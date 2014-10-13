package away3d.materials.methods {
    import away3d.arcane;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.Texture2DBase;
    import away3d.textures.TextureProxyBase;

    import flash.display3D.Context3D;

    use namespace arcane;

    /**
     * TerrainDiffuseMethod provides a diffuse method that uses different tiled textures with alpha masks to create a
     * large surface with high detail and less apparent tiling.
     */
    public class TerrainDiffuseMethod extends DiffuseBasicMethod {
        private var _blendingTexture:Texture2DBase;
        private var _splats:Vector.<Texture2DBase>;
        private var _numSplattingLayers:uint;
        private var _tileData:Array;

        /**
         * Creates a new TerrainDiffuseMethod.
         * @param splatTextures An array of Texture2DProxyBase containing the detailed textures to be tiled.
         * @param blendingTexture The texture containing the blending data. The red, green, and blue channels contain the blending values for each of the textures in splatTextures, respectively.
         * @param tileData The amount of times each splat texture needs to be tiled. The first entry in the array applies to the base texture, the others to the splats. If omitted, the default value of 50 is assumed for each.
         */
        public function TerrainDiffuseMethod(splatTextures:Array, blendingTexture:Texture2DBase, tileData:Array)
        {
            super();
            _splats = Vector.<Texture2DBase>(splatTextures);
            _tileData = tileData;
            _blendingTexture = blendingTexture;
            _numSplattingLayers = _splats.length;
            if (_numSplattingLayers > 4)
                throw new Error("More than 4 splatting layers is not supported!");
        }

        /**
         * @inheritDoc
         */
        override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            var data:Vector.<Number> = shaderObject.fragmentConstantData;
            var index:int = methodVO.fragmentConstantsIndex;
            data[index] = _tileData ? _tileData[0] : 1;
            for (var i:int = 0; i < _numSplattingLayers; ++i) {
                if (i < 3)
                    data[uint(index + i + 1)] = _tileData ? _tileData[i + 1] : 50;
                else
                    data[uint(index + i - 4)] = _tileData ? _tileData[i + 1] : 50;
            }
        }

        /**
         * @inheritDoc
         */
        arcane override function getFragmentPostLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";
            var albedo:ShaderRegisterElement;
            var scaleRegister:ShaderRegisterElement;
            var scaleRegister2:ShaderRegisterElement;

            // incorporate input from ambient
            if (shaderObject.numLights > 0) {
                if (shaderObject.usesShadows)
                    code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + sharedRegisters.shadowTarget + ".w\n";
                code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz, " + targetReg + ".xyz\n" +
                        "sat " + targetReg + ".xyz, " + targetReg + ".xyz\n";
                registerCache.removeFragmentTempUsage(_totalLightColorReg);

                albedo = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(albedo, 1);
            } else
                albedo = targetReg;

            if (!_useTexture)
                throw new Error("TerrainDiffuseMethod requires a diffuse texture!");
            _diffuseInputRegister = registerCache.getFreeTextureReg();
            methodVO.texturesIndex = _diffuseInputRegister.index;
            var blendTexReg:ShaderRegisterElement = registerCache.getFreeTextureReg();

            scaleRegister = registerCache.getFreeFragmentConstant();
            if (_numSplattingLayers == 4)
                scaleRegister2 = registerCache.getFreeFragmentConstant();

            var uv:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(uv, 1);

            var uvReg:ShaderRegisterElement = sharedRegisters.uvVarying;

            code += "mul " + uv + ", " + uvReg + ", " + scaleRegister + ".x\n" +
                    getSplatSampleCode(shaderObject, albedo, sharedRegisters, _diffuseInputRegister, texture, uv);

            var blendValues:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(blendValues, 1);
            code += ShaderCompilerHelper.getTex2DSampleCode(blendValues, sharedRegisters, blendTexReg, _blendingTexture, shaderObject.useSmoothTextures, false, shaderObject.useMipmapping, uvReg);
            var splatTexReg:ShaderRegisterElement;

            methodVO.fragmentConstantsIndex = scaleRegister.index * 4;
            var comps:Vector.<String> = Vector.<String>([ ".x", ".y", ".z", ".w" ]);

            for (var i:int = 0; i < _numSplattingLayers; ++i) {
                var scaleRegName:String = i < 3 ? scaleRegister + comps[i + 1] : scaleRegister2 + comps[i - 3];
                splatTexReg = registerCache.getFreeTextureReg();
                code += "mul " + uv + ", " + uvReg + ", " + scaleRegName + "\n" +
                        getSplatSampleCode(shaderObject, uv, sharedRegisters, splatTexReg, _splats[i], uv);

                code += "sub " + uv + ", " + uv + ", " + albedo + "\n" +
                        "mul " + uv + ", " + uv + ", " + blendValues + comps[i] + "\n" +
                        "add " + albedo + ", " + albedo + ", " + uv + "\n";
            }
            registerCache.removeFragmentTempUsage(uv);
            registerCache.removeFragmentTempUsage(blendValues);

            if (shaderObject.numLights > 0) {
                code += "mul " + targetReg + ".xyz, " + albedo + ".xyz, " + targetReg + ".xyz\n" +
                        "mov " + targetReg + ".w, " + albedo + ".w\n";

                registerCache.removeFragmentTempUsage(albedo);
            }

            return code;
        }

        /**
         * @inheritDoc
         */
        arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
        {
            var context:Context3D = stage.context3D;
            var i:int;
            var texIndex:int = methodVO.texturesIndex;
            super.activate(shaderObject, methodVO, stage);
            stage.activateTexture(texIndex + 1, _blendingTexture);

            texIndex += 2;
            for (i = 0; i < _numSplattingLayers; ++i)
                stage.activateTexture(i + texIndex, _splats[i]);
        }

        /**
         * Gets the sample code for a single splat.
         */
        protected function getSplatSampleCode(shaderObject:ShaderObjectBase, targetReg:ShaderRegisterElement, sharedReg:ShaderRegisterData, inputReg:ShaderRegisterElement, texture:TextureProxyBase, uvReg:ShaderRegisterElement = null):String
        {
            uvReg ||= sharedReg.uvVarying;
            return ShaderCompilerHelper.getTex2DSampleCode(targetReg, sharedReg, inputReg, texture, shaderObject.useSmoothTextures, true, shaderObject.useMipmapping, uvReg)
        }
    }
}
