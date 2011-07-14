package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.BitmapDataTextureCache;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.managers.Texture3DProxy;
	import away3d.core.managers.Texture3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.Shader;
	import flash.display.ShaderJob;
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

		[Embed(source="../../pbks/NormalizeSplats.pbj", mimeType="application/octet-stream")]
		private var NormalizeKernel : Class;

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

			if (_splats[index])
				BitmapDataTextureCache.getInstance().freeTexture(_splats[index]);

            _splats[index] = BitmapDataTextureCache.getInstance().getTexture(texture);
            _tileData[index] = tile;
        }

		public function normalizeSplats() : void
		{
			if (_numSplattingLayers <= 1) return;
			var shader : Shader = new Shader(new NormalizeKernel());
			shader.data.numLayers = _numSplattingLayers;
			shader.data.src.input = _blendData;
			new ShaderJob(shader, _blendData).start(true);
			_blendingTexture.invalidateContent();
		}


        arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
        {
            var code : String = "";
		    var albedo : ShaderRegisterElement;
		    var scaleRegister : ShaderRegisterElement;

			// incorporate input from ambient
	        if (_numLights > 0) {
				code += "add " + targetReg+".xyz, " + _totalLightColorReg+".xyz, " + targetReg+".xyz\n" +
						"sat " + targetReg+".xyz, " + targetReg+".xyz\n";
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
                code += "mul " + uv + ", " + _uvFragmentReg + ", " + scaleRegister + comps[i] + "\n" +
						getSplatSampleCode(uv, splatTexReg, uv) +
                		"sub " + uv + ", " + uv + ", " + albedo + "\n" +
						"mul " + uv + ", " + uv + ", " + temp + comps[i] + "\n" +
						"add " + albedo + ", " + albedo + ", " + uv + "\n";
            }
            regCache.removeFragmentTempUsage(uv);

            _diffuseInputIndex = _diffuseInputRegister.index;

			if (_numLights == 0)
				return code;

			code += "mul " + targetReg+".xyz, " + albedo+".xyz, " + targetReg+".xyz\n" +
					"mov " + targetReg+".w, " + albedo+".w\n";

            regCache.removeFragmentTempUsage(albedo);

			return code;
        }

        arcane override function activate(stage3DProxy : Stage3DProxy) : void
        {
            super.activate(stage3DProxy);
            stage3DProxy.setTextureAt(_blendingTextureIndex, _blendingTexture.getTextureForStage3D(stage3DProxy));

            for (var i : int = 0; i < _numSplattingLayers; ++i)
                stage3DProxy.setTextureAt(i+_splatTextureIndex, _splats[i].getTextureForStage3D(stage3DProxy));

            stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _tileRegisterIndex, _tileData, 1);
        }


//        arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
//        {
//            super.deactivate(stage3DProxy);
//
//            stage3DProxy.setTextureAt(_blendingTextureIndex, null);
//            for (var i : int = 0; i < _numSplattingLayers; ++i)
//                stage3DProxy.setTextureAt(i+_splatTextureIndex, null);
//
//        }

        override public function dispose(deep : Boolean) : void
        {
			super.dispose(deep);
			_blendingTexture.dispose(true);

			var len : int = _splats.length;

			for (var i : int = 0; i < len; ++i) {
				if (_splats[i])
					BitmapDataTextureCache.getInstance().freeTexture(_splats[i]);
			}
        }

        override public function set alphaThreshold(value : Number) : void
        {
            throw new Error("Alpha threshold not supported for TerrainDiffuseMethod");
        }

        protected function getSplatSampleCode(targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, uvReg : ShaderRegisterElement = null) : String
		{
			var wrap : String = "wrap";
			var filter : String;

			if (_smooth) filter = _mipmap ? "linear,miplinear" : "linear";
			else filter = _mipmap ? "nearest,mipnearest" : "nearest";

            uvReg ||= _uvFragmentReg;
			return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <2d," + filter + ",wrap>\n";
		}
    }
}
