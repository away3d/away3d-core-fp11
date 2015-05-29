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

    import flash.display3D.Context3DMipFilter;
    import flash.display3D.Context3DTextureFilter;
    import flash.display3D.Context3DWrapMode;

    use namespace arcane;

    /**
     * BasicSpecularMethod provides the default shading method for Blinn-Phong specular highlights (an optimized but approximated
     * version of Phong specularity).
     */
    public class SpecularBasicMethod extends LightingMethodBase {
        protected var _useTexture:Boolean;
        protected var _totalLightColorReg:ShaderRegisterElement;
        protected var _specularTextureRegister:ShaderRegisterElement;
        protected var _specularTexData:ShaderRegisterElement;
        protected var _specularDataRegister:ShaderRegisterElement;

        private var _texture:Texture2DBase;

        private var _gloss:int = 50;
        private var _specular:Number = 1;
        private var _specularColor:uint = 0xffffff;
        arcane var _specularR:Number = 1, _specularG:Number = 1, _specularB:Number = 1;
        protected var _isFirstLight:Boolean;

        /**
         * Creates a new BasicSpecularMethod object.
         */
        public function SpecularBasicMethod()
        {
            super();
        }

        override arcane function isUsed(shaderObject:ShaderObjectBase):Boolean
        {
            var shaderLightingObject:ShaderLightingObject = shaderObject as ShaderLightingObject;
            return !(shaderLightingObject && !shaderLightingObject.numLights);
        }


        /**
         * @inheritDoc
         */
        override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            var shaderLightingObject:ShaderLightingObject = shaderObject as ShaderLightingObject;

            methodVO.needsUV = _useTexture;
            methodVO.needsNormals = shaderLightingObject && shaderLightingObject.numLights > 0;
            methodVO.needsView = shaderLightingObject && shaderLightingObject.numLights > 0;
        }

        /**
         * The sharpness of the specular highlight.
         */
        public function get gloss():Number
        {
            return _gloss;
        }

        public function set gloss(value:Number):void
        {
            _gloss = value;
        }

        /**
         * The overall strength of the specular highlights.
         */
        public function get specular():Number
        {
            return _specular;
        }

        public function set specular(value:Number):void
        {
            if (value == _specular)
                return;

            _specular = value;
            updateSpecular();
        }

        /**
         * The colour of the specular reflection of the surface.
         */
        public function get specularColor():uint
        {
            return _specularColor;
        }

        public function set specularColor(value:uint):void
        {
            if (_specularColor == value)
                return;

            // specular is now either enabled or disabled
            if (_specularColor == 0 || value == 0)
                invalidateShaderProgram();
            _specularColor = value;
            updateSpecular();
        }

        /**
         * The bitmapData that encodes the specular highlight strength per texel in the red channel, and the sharpness
         * in the green channel. You can use SpecularBitmapTexture if you want to easily set specular and gloss maps
         * from grayscale images, but prepared images are preferred.
         */
        public function get texture():Texture2DBase
        {
            return _texture;
        }

        public function set texture(value:Texture2DBase):void
        {
            if (Boolean(value) != _useTexture ||
                    (value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
                invalidateShaderProgram();
            }
            _useTexture = Boolean(value);
            _texture = value;
        }

        /**
         * @inheritDoc
         */
        override public function copyFrom(method:ShadingMethodBase):void
        {
            var spec:SpecularBasicMethod = SpecularBasicMethod(method);
            texture = spec.texture;
            specular = spec.specular;
            specularColor = spec.specularColor;
            gloss = spec.gloss;
        }

        /**
         * @inheritDoc
         */
        arcane override function cleanCompilationData():void
        {
            super.cleanCompilationData();
            _totalLightColorReg = null;
            _specularTextureRegister = null;
            _specularTexData = null;
            _specularDataRegister = null;
        }

        /**
         * @inheritDoc
         */
        override arcane function getFragmentPreLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            _isFirstLight = true;

            _specularDataRegister = registerCache.getFreeFragmentConstant();
            methodVO.fragmentConstantsIndex = _specularDataRegister.index * 4;

            if (_useTexture) {
                _specularTexData = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(_specularTexData, 1);
                _specularTextureRegister = registerCache.getFreeTextureReg();
                methodVO.texturesIndex = _specularTextureRegister.index;
                code = ShaderCompilerHelper.getTex2DSampleCode(_specularTexData, sharedRegisters, _specularTextureRegister, _texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping);
            } else
                _specularTextureRegister = null;

            _totalLightColorReg = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(_totalLightColorReg, 1);

            return code;
        }

        /**
         * @inheritDoc
         */
        override arcane function getFragmentCodePerLight(shaderObject:ShaderLightingObject, methodVO:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";
            var t:ShaderRegisterElement;

            if (_isFirstLight)
                t = _totalLightColorReg;
            else {
                t = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(t, 1);
            }

            var viewDirReg:ShaderRegisterElement = sharedRegisters.viewDirFragment;
            var normalReg:ShaderRegisterElement = sharedRegisters.normalFragment;

            // blinn-phong half vector model
            code += "add " + t + ", " + lightDirReg + ", " + viewDirReg + "\n" +
                    "nrm " + t + ".xyz, " + t + "\n" +
                    "dp3 " + t + ".w, " + normalReg + ", " + t + "\n" +
                    "sat " + t + ".w, " + t + ".w\n";

            if (_useTexture) {
                // apply gloss modulation from texture
                code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
                        "pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
            } else
                code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";

            // attenuate
            if (shaderObject.usesLightFallOff)
                code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

            if (_modulateMethod != null)
                code += _modulateMethod(shaderObject, methodVO, t, registerCache, sharedRegisters);

            code += "mul " + t + ".xyz, " + lightColReg + ", " + t + ".w\n";

            if (!_isFirstLight) {
                code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
                registerCache.removeFragmentTempUsage(t);
            }

            _isFirstLight = false;

            return code;
        }

        /**
         * @inheritDoc
         */
        arcane override function getFragmentCodePerProbe(shaderObject:ShaderLightingObject, methodVO:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";
            var t:ShaderRegisterElement;

            // write in temporary if not first light, so we can add to total diffuse colour
            if (_isFirstLight)
                t = _totalLightColorReg;
            else {
                t = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(t, 1);
            }

            var normalReg:ShaderRegisterElement = sharedRegisters.normalFragment;
            var viewDirReg:ShaderRegisterElement = sharedRegisters.viewDirFragment;
            code += "dp3 " + t + ".w, " + normalReg + ", " + viewDirReg + "\n" +
                    "add " + t + ".w, " + t + ".w, " + t + ".w\n" +
                    "mul " + t + ", " + t + ".w, " + normalReg + "\n" +
                    "sub " + t + ", " + t + ", " + viewDirReg + "\n" +
                    "tex " + t + ", " + t + ", " + cubeMapReg + " <cube," + (shaderObject.useSmoothTextures ? "linear" : "nearest") + ",miplinear>\n" +
                    "mul " + t + ".xyz, " + t + ", " + weightRegister + "\n";

            if (_modulateMethod != null)
                code += _modulateMethod(shaderObject, methodVO, t, registerCache, sharedRegisters);

            if (!_isFirstLight) {
                code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
                registerCache.removeFragmentTempUsage(t);
            }

            _isFirstLight = false;

            return code;
        }

        /**
         * @inheritDoc
         */
        override arcane function getFragmentPostLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            if (sharedRegisters.shadowTarget)
                code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + sharedRegisters.shadowTarget + ".w\n";

            if (_useTexture) {
                // apply strength modulation from texture
                code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularTexData + ".x\n";
                registerCache.removeFragmentTempUsage(_specularTexData);
            }

            // apply material's specular reflection
            code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularDataRegister + "\n" +
                    "add " + targetReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n";
            registerCache.removeFragmentTempUsage(_totalLightColorReg);

            return code;
        }

        /**
         * @inheritDoc
         */
        arcane override function activate(shaderObject:ShaderObjectBase, vo:MethodVO, stage3DProxy:Stage3DProxy):void
        {
            //var context : Context3D = stage3DProxy._context3D;

            if (_useTexture) {
                stage3DProxy.context3D.setSamplerStateAt(vo.texturesIndex, shaderObject.repeatTextures ? Context3DWrapMode.REPEAT : Context3DWrapMode.CLAMP, shaderObject.useSmoothTextures ? Context3DTextureFilter.LINEAR : Context3DTextureFilter.NEAREST, shaderObject.useMipmapping ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
                stage3DProxy.activateTexture(vo.texturesIndex, this._texture);
            }
            var index:int = vo.fragmentConstantsIndex;
            var data:Vector.<Number> = shaderObject.fragmentConstantData;
            data[index] = _specularR;
            data[index + 1] = _specularG;
            data[index + 2] = _specularB;
            data[index + 3] = _gloss;
        }

        /**
         * Updates the specular color data used by the render state.
         */
        private function updateSpecular():void
        {
            _specularR = ((_specularColor >> 16) & 0xff) / 0xff * _specular;
            _specularG = ((_specularColor >> 8) & 0xff) / 0xff * _specular;
            _specularB = (_specularColor & 0xff) / 0xff * _specular;
        }
    }
}
