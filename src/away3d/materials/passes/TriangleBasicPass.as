package away3d.materials.passes {
    import away3d.arcane;
    import away3d.core.pool.MaterialPassData;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;

    import flash.display3D.Context3DMipFilter;
    import flash.display3D.Context3DTextureFilter;
    import flash.display3D.Context3DWrapMode;

    use namespace arcane;

    /**
     * CompiledPass forms an abstract base class for the default compiled pass materials provided by Away3D,
     * using material methods to define their appearance.
     */
    public class TriangleBasicPass extends MaterialPassBase {
        private var _diffuseColor:int = 0xffffff;
        private var _diffuseR:int = 1;
        private var _diffuseG:int = 1;
        private var _diffuseB:int = 1;
        private var _diffuseA:int = 1;

        private var _fragmentConstantsIndex:int;
        private var _texturesIndex:int;

        /**
         * The alpha component of the diffuse reflection.
         */
        public function get diffuseAlpha():int
        {
            return _diffuseA;
        }

        public function set diffuseAlpha(value:int):void
        {
            _diffuseA = value;
        }

        /**
         * The color of the diffuse reflection when not using a texture.
         */
        public function get diffuseColor():int
        {
            return _diffuseColor;
        }

        public function set diffuseColor(diffuseColor:int):void
        {
            _diffuseColor = diffuseColor;

            _diffuseR = ((_diffuseColor >> 16) & 0xff) / 0xff;
            _diffuseG = ((_diffuseColor >> 8) & 0xff) / 0xff;
            _diffuseB = (_diffuseColor & 0xff) / 0xff;
        }

        /**
         * Creates a new CompiledPass object.
         *
         * @param material The material to which this pass belongs.
         */
        public function TriangleBasicPass()
        {
        }

        /**
         * @inheritDoc
         */
        arcane function getFragmentCode(shaderObject:ShaderObjectBase, regCache:ShaderRegisterCache, sharedReg:ShaderRegisterData):String
        {
            var code:String = "";
            var targetReg:ShaderRegisterElement = sharedReg.shadedTarget;
            var diffuseInputReg:ShaderRegisterElement;

            if (shaderObject.texture != null) {
                diffuseInputReg = regCache.getFreeTextureReg();

                _texturesIndex = diffuseInputReg.index;

                code += ShaderCompilerHelper.getTex2DSampleCode(targetReg, sharedReg, diffuseInputReg, shaderObject.texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping);

                if (shaderObject.alphaThreshold > 0) {
                    var cutOffReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
                    _fragmentConstantsIndex = cutOffReg.index * 4;

                    code += "sub " + targetReg + ".w, " + targetReg + ".w, " + cutOffReg + ".x\n" +
                            "kil " + targetReg + ".w\n" +
                            "add " + targetReg + ".w, " + targetReg + ".w, " + cutOffReg + ".x\n";
                }

            } else {
                diffuseInputReg = regCache.getFreeFragmentConstant();

                _fragmentConstantsIndex = diffuseInputReg.index * 4;

                code += "mov " + targetReg + ", " + diffuseInputReg + "\n";
            }

            return code;
        }

        override public function includeDependencies(dependencyCounter:ShaderObjectBase):void
        {
            if (dependencyCounter.texture != null)
                dependencyCounter.uvDependencies++;
        }

        /**
         * @inheritDoc
         */
        override public function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
        {
            super.activate(pass, stage, camera);

            var shaderObject:ShaderObjectBase = pass.shaderObject;

            if (shaderObject.texture != null) {
                stage.context3D.setSamplerStateAt(_texturesIndex, shaderObject.repeatTextures ? Context3DWrapMode.REPEAT : Context3DWrapMode.CLAMP, shaderObject.useSmoothTextures ? Context3DTextureFilter.LINEAR : Context3DTextureFilter.NEAREST, shaderObject.useMipmapping ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
                stage.activateTexture(_texturesIndex, shaderObject.texture);

                if (shaderObject.alphaThreshold > 0)
                    shaderObject.fragmentConstantData[_fragmentConstantsIndex] = shaderObject.alphaThreshold;
            } else {
                var index:int = _fragmentConstantsIndex;
                var data:Vector.<Number> = shaderObject.fragmentConstantData;
                data[index] = _diffuseR;
                data[index + 1] = _diffuseG;
                data[index + 2] = _diffuseB;
                data[index + 3] = _diffuseA;
            }
        }
    }
}
