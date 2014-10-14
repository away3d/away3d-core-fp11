package away3d.materials.methods {
    import away3d.arcane;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
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
     * AmbientBasicMethod provides the default shading method for uniform ambient lighting.
     */
    public class AmbientBasicMethod extends ShadingMethodBase {
        private var _color:uint = 0xffffff;
        private var _colorR:Number = 0;
        private var _colorG:Number = 0;
        private var _colorB:Number = 0;
        private var _alpha:Number = 1;

        private var _ambient:Number = 1;

        /**
         * Creates a new AmbientBasicMethod object.
         */
        public function AmbientBasicMethod()
        {
        }


        override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            methodVO.needsUV = shaderObject.texture != null;
        }


        override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            if (!methodVO.needsUV) {
                _color = shaderObject.color;
                updateColor();
            }
        }

        /**
         * The strength of the ambient reflection of the surface.
         */
        public function get ambient():Number
        {
            return _ambient;
        }

        public function set ambient(value:Number):void
        {
            if(_ambient == value) return;
            _ambient = value;
            updateColor();
        }

        /**
         * The colour of the ambient reflection of the surface.
         */
        public function get color():uint
        {
            return _color;
        }

        public function set color(value:uint):void
        {
            if(_color == value) return;
            _color = value;
            updateColor();
        }

        /**
         * @inheritDoc
         */
        override public function copyFrom(method:ShadingMethodBase):void
        {
            var diff:AmbientBasicMethod = AmbientBasicMethod(method);
            ambient = diff.ambient;
            color = diff.color;
        }


        /**
         * @inheritDoc
         */
        override arcane function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";
            var ambientInputRegister:ShaderRegisterElement;

            if (methodVO.needsUV) {
                ambientInputRegister = registerCache.getFreeTextureReg();

                methodVO.texturesIndex = ambientInputRegister.index;

                code += ShaderCompilerHelper.getTex2DSampleCode(targetReg, sharedRegisters, ambientInputRegister, shaderObject.texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping);

                if (shaderObject.alphaThreshold > 0) {
                    var cutOffReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
                    methodVO.fragmentConstantsIndex = cutOffReg.index * 4;

                    code += "sub " + targetReg + ".w, " + targetReg + ".w, " + cutOffReg + ".x\n" +
                            "kil " + targetReg + ".w\n" +
                            "add " + targetReg + ".w, " + targetReg + ".w, " + cutOffReg + ".x\n";
                }

            } else {
                ambientInputRegister = registerCache.getFreeFragmentConstant();
                methodVO.fragmentConstantsIndex = ambientInputRegister.index * 4;

                code += "mov " + targetReg + ", " + ambientInputRegister + "\n";
            }

            return code;
        }

        /**
         * @inheritDoc
         */
        override arcane function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
        {
            if (methodVO.needsUV) {
                stage.context3D.setSamplerStateAt(methodVO.texturesIndex, shaderObject.repeatTextures ? Context3DWrapMode.REPEAT : Context3DWrapMode.CLAMP, shaderObject.useSmoothTextures ? Context3DTextureFilter.LINEAR : Context3DTextureFilter.NEAREST, shaderObject.useMipmapping ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
                stage.activateTexture(methodVO.texturesIndex, shaderObject.texture);

                if (shaderObject.alphaThreshold > 0)
                    shaderObject.fragmentConstantData[methodVO.fragmentConstantsIndex] = shaderObject.alphaThreshold;
            } else {
                var index:int = methodVO.fragmentConstantsIndex;
                var data:Vector.<Number> = shaderObject.fragmentConstantData;
                data[index] = _colorR;
                data[index + 1] = _colorG;
                data[index + 2] = _colorB;
                data[index + 3] = _alpha;
            }
        }

        /**
         * Updates the ambient color data used by the render state.
         */
        private function updateColor():void
        {
            _colorR = ((_color >> 16) & 0xff) / 0xff * _ambient;
            _colorG = ((_color >> 8) & 0xff) / 0xff * _ambient;
            _colorB = (_color & 0xff) / 0xff * _ambient;
        }

        public function get alpha():Number
        {
            return _alpha;
        }

        public function set alpha(value:Number):void
        {
            _alpha = value;
        }
    }
}
