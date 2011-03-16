package away3d.materials.methods
{
    import away3d.arcane;
    import away3d.core.managers.Texture3DProxy;

    import away3d.materials.utils.AGAL;
    import away3d.materials.utils.ShaderRegisterCache;

    import away3d.materials.utils.ShaderRegisterElement;

    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.geom.Point;

    use namespace arcane;

    public class TerrainDiffuseMethod extends BasicDiffuseMethod
    {
        private var _blendData : BitmapData;
        private var _blendingTexture : Texture3DProxy;
        private var _splats : Vector.<Texture3DProxy>;
        private var _tileData : Vector.<Number>;
        private var _numSplattingLayers : uint;
        private var _tileRegisterIndex : int;
        private var _splatTextureIndex : int;
        private var _blendingTextureIndex : int;

        public function TerrainDiffuseMethod()
        {
            super();
            _tileData = new Vector.<Number>(4, true);
            _splats = new Vector.<Texture3DProxy>(3, true);
        }

        public function setSplattingLayer(index : uint, texture : BitmapData, alpha : BitmapData, tile : Number = 50) : void
        {
			if (index > _numSplattingLayers) throw new Error("The supplied index is out of bounds!");
			if (index >= 3) throw new Error("More than 3 splatting layers is not supported!");

			if (index == _numSplattingLayers)
				_numSplattingLayers = index+1;

            _blendData ||= new BitmapData(alpha.width, alpha.height, false, 0);
            _blendingTexture ||= new Texture3DProxy();
            _blendingTexture.bitmapData = _blendData;

            if (_blendData.width != alpha.width || _blendData.height != alpha.height)
                throw new Error("Alpha maps for each splatting layer need to be of equal size!");

            var targetChannel : int =   index == 0  ?   BitmapDataChannel.RED :
                                        index == 1  ?   BitmapDataChannel.GREEN
                                                    :   BitmapDataChannel.BLUE;

            _blendData.copyChannel(alpha, alpha.rect, new Point(), BitmapDataChannel.RED, targetChannel);
            _blendingTexture.invalidateContent();

            _splats[index] ||= new Texture3DProxy();
            _splats[index].bitmapData = texture;
            _tileData[index] = tile;
        }


        arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
        {
            var code : String = "";
		    var albedo : ShaderRegisterElement;
		    var scaleRegister : ShaderRegisterElement;

			// incorporate input from ambient
	        if (_numLights > 0) {
				code += AGAL.add(targetReg+".xyz", _totalLightColorReg+".xyz", targetReg+".xyz");
				code += AGAL.sat(targetReg+".xyz", targetReg+".xyz");
				regCache.removeFragmentTempUsage(_totalLightColorReg);

                albedo = regCache.getFreeFragmentVectorTemp();
                regCache.addFragmentTempUsages(albedo, 1);
            }
            else
                albedo = targetReg;

            if (!_useTexture) throw new Error("TerrainDiffuseMethod requires a texture (not using BitmapMaterial?)!");
            _diffuseInputRegister = regCache.getFreeTextureReg();
            code += getTexSampleCode(albedo, _diffuseInputRegister);

            var uv : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
            regCache.addFragmentTempUsages(uv, 1);
            var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
            var blendTexReg : ShaderRegisterElement = regCache.getFreeTextureReg();
            _blendingTextureIndex = blendTexReg.index;
            code += getTexSampleCode(temp, blendTexReg);
            var splatTexReg : ShaderRegisterElement;
            scaleRegister = regCache.getFreeFragmentConstant();
            _tileRegisterIndex = scaleRegister.index;
            var comps : Array = [ ".x",".y",".z" ];

            for (var i : int = 0; i < _numSplattingLayers; ++i) {
                splatTexReg = regCache.getFreeTextureReg();
                if (i == 0) _splatTextureIndex = splatTexReg.index;
                code += AGAL.mul(uv.toString(), _uvFragmentReg.toString(), scaleRegister.toString() + comps[i]);
                code += getSplatSampleCode(uv, splatTexReg, uv);
//                code += AGAL.add(albedo.toString(), albedo.toString(), uv.toString());
                code += AGAL.sub(uv.toString(), uv.toString(), albedo.toString());
                code += AGAL.mul(uv.toString(), uv.toString(), temp.toString() + comps[i]);
                code += AGAL.add(albedo.toString(), albedo.toString(), uv.toString());
            }
            regCache.removeFragmentTempUsage(uv);

            _diffuseInputIndex = _diffuseInputRegister.index;

			if (_numLights == 0)
				return code;

			code += AGAL.mul(targetReg+".xyz", albedo+".xyz", targetReg+".xyz");
            code += AGAL.mov(targetReg+".w", albedo+".w");

            regCache.removeFragmentTempUsage(albedo);

			return code;
        }

        arcane override function activate(context : Context3D, contextIndex : uint) : void
        {
            super.activate(context, contextIndex);
            context.setTextureAt(_blendingTextureIndex, _blendingTexture.getTextureForContext(context, contextIndex));

            for (var i : int = 0; i < _numSplattingLayers; ++i)
                context.setTextureAt(i+_splatTextureIndex, _splats[i].getTextureForContext(context, contextIndex));

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _tileRegisterIndex, _tileData, 1);
        }


        arcane override function deactivate(context : Context3D) : void
        {
            super.deactivate(context);
            context.setTextureAt(_blendingTextureIndex, null);
            for (var i : int = 0; i < _numSplattingLayers; ++i)
                context.setTextureAt(i+_splatTextureIndex, null);

        }

        override public function dispose(deep : Boolean) : void
        {
            super.dispose(deep);
            _blendData.dispose();
        }

        override public function set alphaThreshold(value : Number) : void
        {
            throw new Error("Alpha threshold not supported for TerrainDiffuseMethod");
        }

        protected function getSplatSampleCode(targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, uvReg : ShaderRegisterElement = null) : String
		{
			var wrap : String = "wrap";
			var filter : String;

			if (_smooth) filter = _mipmap ? "trilinear" : "bilinear";
			else filter = _mipmap ? "nearestMip" : "nearestNoMip";

            uvReg ||= _uvFragmentReg;
			return AGAL.sample(targetReg.toString(), uvReg.toString(), "2d", inputReg.toString(), filter, wrap);
		}
    }
}
