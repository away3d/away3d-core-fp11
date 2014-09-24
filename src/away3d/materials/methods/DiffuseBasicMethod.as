package away3d.materials.methods {
    import away3d.arcane;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
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
     * BasicDiffuseMethod provides the default shading method for Lambert (dot3) diffuse lighting.
     */
    public class DiffuseBasicMethod extends LightingMethodBase {
        private var _multiply:Boolean = true;

        protected var _useTexture:Boolean;
        protected var _totalLightColorReg:ShaderRegisterElement;
        protected var _diffuseInputRegister:ShaderRegisterElement;

        private var _texture:Texture2DBase;
        private var _diffuseColor:uint = 0xffffff;
        private var _ambientColor:uint = 0xffffff;
        private var _diffuseR:Number = 1;
        private var _diffuseG:Number = 1;
        private var _diffuseB:Number = 1;
        private var _ambientR:Number = 1;
        private var _ambientG:Number = 1;
        private var _ambientB:Number = 1;

        protected var _isFirstLight:Boolean;

        /**
         * Creates a new DiffuseBasicMethod object.
         */
        public function DiffuseBasicMethod()
        {
            super();
        }

        override arcane function isUsed(shaderObject:ShaderObjectBase):Boolean
        {
            return !((shaderObject as ShaderLightingObject) && !(shaderObject as ShaderLightingObject).numLights);
        }

        /**
         * Set internally if diffuse color component multiplies or replaces the ambient color
         */
        public function get multiply():Boolean
        {
            return _multiply;
        }

        public function set multiply(value:Boolean)
        {
            if (_multiply == value)
                return;

            _multiply = value;

            invalidateShaderProgram();
        }

        override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            methodVO.needsUV = _useTexture;
            methodVO.needsNormals = (shaderObject as ShaderLightingObject).numLights > 0;
        }

        /**
         * Forces the creation of the texture.
         * @param stage The Stage used by the renderer
         */
        public function generateMip(stage:Stage3DProxy):void
        {
            if (_useTexture)
                stage.activateTexture(0, this._texture);
        }

        /**
         * The color of the diffuse reflection when not using a texture.
         */
        public function get diffuseColor():uint
        {
            return _diffuseColor;
        }

        public function set diffuseColor(value:uint):void
        {
            if (_diffuseColor == value)
                return;

            _diffuseColor = value;

            updateDiffuse();
        }

        /**
         * The color of the ambient reflection
         */
        public function get ambientColor():uint
        {
            return _ambientColor;
        }

        public function set ambientColor(value:uint):void
        {
            if (_ambientColor == value)
                return;

            _ambientColor = value;

            updateAmbient();
        }


        /**
         * The bitmapData to use to define the diffuse reflection color per texel.
         */
        public function get texture():Texture2DBase
        {
            return this._texture;
        }

        public function set texture(value:Texture2DBase):void
        {
            var b:Boolean = (value != null);

            if (b != _useTexture || (value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)))
                invalidateShaderProgram();

            _useTexture = b;
            _texture = value;
        }

        /**
         * @inheritDoc
         */
        override public function dispose():void
        {
            _texture = null;
        }

        /**
         * @inheritDoc
         */
        override public function copyFrom(method:ShadingMethodBase):void
        {
            var diff:DiffuseBasicMethod = method as DiffuseBasicMethod;

            this.texture = diff.texture;
            this.multiply = diff.multiply;
            this.diffuseColor = diff.diffuseColor;
            this.ambientColor = diff.ambientColor;
        }

        /**
         * @inheritDoc
         */
        override arcane function cleanCompilationData():void
        {
            super.cleanCompilationData();

            _totalLightColorReg = null;
            _diffuseInputRegister = null;
        }

        /**
         * @inheritDoc
         */
        override arcane function getFragmentPreLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            _isFirstLight = true;

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

            // write in temporary if not first light, so we can add to total diffuse colour
            if (_isFirstLight) {
                t = _totalLightColorReg;
            } else {
                t = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(t, 1);
            }

            code += "dp3 " + t + ".x, " + lightDirReg + ", " + sharedRegisters.normalFragment + "\n" +
                    "max " + t + ".w, " + t + ".x, " + sharedRegisters.commons + ".y\n";

            if (shaderObject.usesLightFallOff)
                code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

            if (_modulateMethod != null)
                code += _modulateMethod(shaderObject, methodVO, t, registerCache, sharedRegisters);

            code += "mul " + t + ", " + t + ".w, " + lightColReg + "\n";

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
        override arcane function getFragmentCodePerProbe(shaderObject:ShaderLightingObject, methodVO:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";
            var t:ShaderRegisterElement;

            // write in temporary if not first light, so we can add to total diffuse colour
            if (_isFirstLight) {
                t = _totalLightColorReg;
            } else {
                t = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(t, 1);
            }

            code += "tex " + t + ", " + sharedRegisters.normalFragment + ", " + cubeMapReg + " <cube,linear,miplinear>\n" +
                    "mul " + t + ".xyz, " + t + ".xyz, " + weightRegister + "\n";

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

            var albedo:ShaderRegisterElement;
            var cutOffReg:ShaderRegisterElement;

            // incorporate input from ambient
            if (sharedRegisters.shadowTarget)
                code += applyShadow(shaderObject, methodVO, registerCache, sharedRegisters);

            albedo = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(albedo, 1);

            var ambientColorRegister:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
            methodVO.fragmentConstantsIndex = ambientColorRegister.index * 4;

            if (_useTexture) {
                _diffuseInputRegister = registerCache.getFreeTextureReg();

                methodVO.texturesIndex = _diffuseInputRegister.index;

                code += ShaderCompilerHelper.getTex2DSampleCode(albedo, sharedRegisters, _diffuseInputRegister, _texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping);

            } else {
                _diffuseInputRegister = registerCache.getFreeFragmentConstant();

                code += "mov " + albedo + ", " + _diffuseInputRegister + "\n";
            }

            code += "sat " + _totalLightColorReg + ", " + _totalLightColorReg + "\n" +
                    "mul " + albedo + ".xyz, " + albedo + ", " + _totalLightColorReg + "\n";

            if (_multiply) {
                code += "add " + albedo + ".xyz, " + albedo + ", " + ambientColorRegister + "\n" +
                        "mul " + targetReg + ".xyz, " + targetReg + ", " + albedo + "\n";
            } else {
                code += "mul " + targetReg + ".xyz, " + targetReg + ", " + ambientColorRegister + "\n" +
                        "mul " + _totalLightColorReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n" +
                        "sub " + targetReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n" +
                        "add " + targetReg + ".xyz, " + targetReg + ", " + albedo + "\n";
            }

            registerCache.removeFragmentTempUsage(_totalLightColorReg);
            registerCache.removeFragmentTempUsage(albedo);

            return code;
        }

        /**
         * Generate the code that applies the calculated shadow to the diffuse light
         * @param methodVO The MethodVO object for which the compilation is currently happening.
         * @param regCache The register cache the compiler is currently using for the register management.
         */
        public function applyShadow(shaderObject:ShaderLightingObject, methodVO:MethodVO, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "mul " + this._totalLightColorReg + ".xyz, " + this._totalLightColorReg + ", " + sharedRegisters.shadowTarget + ".w\n";
        }

        /**
         * @inheritDoc
         */
        override arcane function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
        {
            if (this._useTexture) {
                stage.context3D.setSamplerStateAt(methodVO.texturesIndex, shaderObject.repeatTextures ? Context3DWrapMode.REPEAT : Context3DWrapMode.CLAMP, shaderObject.useSmoothTextures ? Context3DTextureFilter.LINEAR : Context3DTextureFilter.NEAREST, shaderObject.useMipmapping ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
                stage.activateTexture(methodVO.texturesIndex, this._texture);
            } else {
                var index:Number = methodVO.fragmentConstantsIndex;
                var data:Vector.<Number> = shaderObject.fragmentConstantData;
                data[index + 4] = this._diffuseR;
                data[index + 5] = this._diffuseG;
                data[index + 6] = this._diffuseB;
                data[index + 7] = 1;
            }
        }

        /**
         * Updates the diffuse color data used by the render state.
         */
        private function updateDiffuse():void
        {
            _diffuseR = ((_diffuseColor >> 16) & 0xff) / 0xff;
            _diffuseG = ((_diffuseColor >> 8) & 0xff) / 0xff;
            _diffuseB = (_diffuseColor & 0xff) / 0xff;
        }

        /**
         * Updates the ambient color data used by the render state.
         */
        private function updateAmbient():void
        {
            _ambientR = ((_ambientColor >> 16) & 0xff) / 0xff;
            _ambientG = ((_ambientColor >> 8) & 0xff) / 0xff;
            _ambientB = (_ambientColor & 0xff) / 0xff;
        }

        /**
         * @inheritDoc
         */
        arcane function setRenderState(shaderObject:ShaderLightingObject, methodVO:MethodVO, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D):void
        {
            //TODO move this to Activate (ambientR/G/B currently calc'd in render state)
            if (shaderObject.numLights > 0) {
                var index:Number = methodVO.fragmentConstantsIndex;
                var data:Vector.<Number> = shaderObject.fragmentConstantData;
                data[index] = shaderObject.ambientR * _ambientR;
                data[index + 1] = shaderObject.ambientG * _ambientG;
                data[index + 2] = shaderObject.ambientB * _ambientB;
                data[index + 3] = 1;
            }
        }
    }
}
