package away3d.materials.compilation {
    import away3d.arcane;
    import away3d.materials.MaterialBase;
    import away3d.materials.passes.IMaterialPass;
    import away3d.materials.passes.MaterialPassMode;

    use namespace arcane;

    /**
     * ShaderCompiler is an abstract base class for shader compilers that use modular shader methods to assemble a
     * material. Concrete subclasses are used by the default materials.
     *
     * @see away3d.materials.methods.ShadingMethodBase
     */
    public class ShaderCompilerBase {
        protected var _shaderObject:ShaderObjectBase;
        protected var _sharedRegisters:ShaderRegisterData;
        protected var _registerCache:ShaderRegisterCache;
        protected var _materialPass:IMaterialPass;
        protected var _material:MaterialBase;

        protected var _vertexCode:String;
        protected var _fragmentCode:String;
        protected var _postAnimationFragmentCode:String;

        //The attributes that need to be animated by animators.
        protected var _animatableAttributes:Vector.<String>;

        //The target registers for animated properties, written to by the animators.
        protected var _animationTargetRegisters:Vector.<String>;

        //The target register to place the animated UV coordinate.
        private var _uvTarget:String;

        //The souce register providing the UV coordinate to animate.
        private var _uvSource:String;

        protected var _profile:String;


        /**
         * Creates a new ShaderCompiler object.
         */
        public function ShaderCompilerBase(material:MaterialBase, materialPass:IMaterialPass, shaderObject:ShaderObjectBase)
        {
            _material = material;
            _materialPass = materialPass;

            _shaderObject = shaderObject;
            _profile = shaderObject.profile;

            _sharedRegisters = new ShaderRegisterData();

            _registerCache = new ShaderRegisterCache(_profile);
            _registerCache.vertexAttributesOffset = 1;
            _registerCache.reset();
        }

        /**
         * Compiles the code after all setup on the compiler has finished.
         */
        public function compile():void
        {
            _shaderObject.reset();

            calculateDependencies();

            initRegisterIndices();

            compileDependencies();

            //compile custom vertex & fragment codes
            _vertexCode += _materialPass.getVertexCode(_shaderObject, _registerCache, _sharedRegisters);
            _postAnimationFragmentCode += _materialPass.getFragmentCode(_shaderObject, _registerCache, _sharedRegisters);

            //assign the final output color to the output register
            _postAnimationFragmentCode += "mov " + _registerCache.fragmentOutputRegister + ", " + _sharedRegisters.shadedTarget + "\n";
            _registerCache.removeFragmentTempUsage(_sharedRegisters.shadedTarget);

            //initialise the required shader constants
            _shaderObject.initConstantData(_registerCache, _animatableAttributes, _animationTargetRegisters, _uvSource, _uvTarget);
            _materialPass.initConstantData(_shaderObject);
        }

        /**
         * Compile the code for the methods.
         */
        protected function compileDependencies():void
        {
            _sharedRegisters.shadedTarget = _registerCache.getFreeFragmentVectorTemp();
            _registerCache.addFragmentTempUsages(_sharedRegisters.shadedTarget, 1);

            //compile the world-space position if required
            if (_shaderObject.globalPosDependencies > 0)
                compileGlobalPositionCode();

            //Calculate the (possibly animated) UV coordinates.
            if (_shaderObject.uvDependencies > 0)
                compileUVCode();

            if (_shaderObject.secondaryUVDependencies > 0)
                compileSecondaryUVCode();

            if (_shaderObject.normalDependencies > 0)
                compileNormalCode();

            if (_shaderObject.viewDirDependencies > 0)
                compileViewDirCode();

            //collect code from material
            _vertexCode += _material.getVertexCode(_shaderObject, _registerCache, _sharedRegisters);
            _fragmentCode += _material.getFragmentCode(_shaderObject, _registerCache, _sharedRegisters);

            //collect code from pass
            _vertexCode += _materialPass.getPreLightingVertexCode(_shaderObject, _registerCache, _sharedRegisters);
            _fragmentCode += _materialPass.getPreLightingFragmentCode(_shaderObject, _registerCache, _sharedRegisters);


        }

        private function compileGlobalPositionCode():void
        {
            _registerCache.addVertexTempUsages(_sharedRegisters.globalPositionVertex = _registerCache.getFreeVertexVectorTemp(), _shaderObject.globalPosDependencies);

            var sceneMatrixReg:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
            _registerCache.getFreeVertexConstant();
            _registerCache.getFreeVertexConstant();
            _registerCache.getFreeVertexConstant();

            _shaderObject.sceneMatrixIndex = sceneMatrixReg.index * 4;

            _vertexCode += "m44 " + _sharedRegisters.globalPositionVertex + ", " + _sharedRegisters.localPosition + ", " + sceneMatrixReg + "\n";

            if (_shaderObject.usesGlobalPosFragment) {
                _sharedRegisters.globalPositionVarying = _registerCache.getFreeVarying();
                _vertexCode += "mov " + _sharedRegisters.globalPositionVarying + ", " + _sharedRegisters.globalPositionVertex + "\n";
            }
        }

        /**
         * Calculate the (possibly animated) UV coordinates.
         */
        private function compileUVCode():void
        {
            var uvAttributeReg:ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
            _shaderObject.uvBufferIndex = uvAttributeReg.index;

            var varying:ShaderRegisterElement = _registerCache.getFreeVarying();

            _sharedRegisters.uvVarying = varying;

            if (_shaderObject.usesUVTransform) {
                // a, b, 0, tx
                // c, d, 0, ty
                var uvTransform1:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
                var uvTransform2:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
                _shaderObject.uvTransformIndex = uvTransform1.index * 4;

                _vertexCode += "dp4 " + varying + ".x, " + uvAttributeReg + ", " + uvTransform1 + "\n" +
                        "dp4 " + varying + ".y, " + uvAttributeReg + ", " + uvTransform2 + "\n" +
                        "mov " + varying + ".zw, " + uvAttributeReg + ".zw \n";
            } else {
                _shaderObject.uvTransformIndex = -1;
                _uvTarget = varying.toString();
                _uvSource = uvAttributeReg.toString();
            }
        }

        /**
         * Provide the secondary UV coordinates.
         */
        private function compileSecondaryUVCode():void
        {
            var uvAttributeReg:ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
            _shaderObject.secondaryUVBufferIndex = uvAttributeReg.index;
            _sharedRegisters.secondaryUVVarying = _registerCache.getFreeVarying();
            _vertexCode += "mov " + _sharedRegisters.secondaryUVVarying + ", " + uvAttributeReg + "\n";
        }

        /**
         * Calculate the view direction.
         */
        public function compileViewDirCode():void
        {
            var cameraPositionReg:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
            _sharedRegisters.viewDirVarying = _registerCache.getFreeVarying();
            _sharedRegisters.viewDirFragment = _registerCache.getFreeFragmentVectorTemp();
            _registerCache.addFragmentTempUsages(_sharedRegisters.viewDirFragment, _shaderObject.viewDirDependencies);

            _shaderObject.cameraPositionIndex = cameraPositionReg.index * 4;

            if (_shaderObject.usesTangentSpace) {
                var temp:ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
                _vertexCode += "sub " + temp + ", " + cameraPositionReg + ", " + _sharedRegisters.localPosition + "\n" +
                        "m33 " + _sharedRegisters.viewDirVarying + ".xyz, " + temp + ", " + _sharedRegisters.animatedTangent + "\n" +
                        "mov " + _sharedRegisters.viewDirVarying + ".w, " + _sharedRegisters.localPosition + ".w\n";
            } else {
                _vertexCode += "sub " + _sharedRegisters.viewDirVarying + ", " + cameraPositionReg + ", " + _sharedRegisters.globalPositionVertex + "\n";
                _registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
            }

            //TODO is this required in all cases? (re: distancemappass)
            _fragmentCode += "nrm " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.viewDirVarying + "\n" +
                    "mov " + _sharedRegisters.viewDirFragment + ".w,   " + _sharedRegisters.viewDirVarying + ".w\n";
        }

        /**
         * Calculate the normal.
         */
        public function compileNormalCode():void
        {
            _sharedRegisters.normalFragment = _registerCache.getFreeFragmentVectorTemp();
            _registerCache.addFragmentTempUsages(_sharedRegisters.normalFragment, _shaderObject.normalDependencies);

            //simple normal aquisition if no tangent space is being used
            if (_shaderObject.outputsNormals && !_shaderObject.outputsTangentNormals) {
                _vertexCode += _materialPass.getNormalVertexCode(_shaderObject, _registerCache, _sharedRegisters);
                _fragmentCode += _materialPass.getNormalFragmentCode(_shaderObject, _registerCache, _sharedRegisters);

                return;
            }

            var normalMatrix:Vector.<ShaderRegisterElement>;

            if (!_shaderObject.outputsNormals || !_shaderObject.usesTangentSpace) {
                normalMatrix = new Vector.<ShaderRegisterElement>(3);
                normalMatrix[0] = _registerCache.getFreeVertexConstant();
                normalMatrix[1] = _registerCache.getFreeVertexConstant();
                normalMatrix[2] = _registerCache.getFreeVertexConstant();

                _registerCache.getFreeVertexConstant();

                _shaderObject.sceneNormalMatrixIndex = normalMatrix[0].index * 4;

                _sharedRegisters.normalVarying = _registerCache.getFreeVarying();
            }

            if (_shaderObject.outputsNormals) {
                if (_shaderObject.usesTangentSpace) {
                    // normalize normal + tangent vector and generate (approximated) bitangent used in m33 operation for view
                    _vertexCode += "nrm " + _sharedRegisters.animatedNormal + ".xyz, " + _sharedRegisters.animatedNormal + "\n" +
                            "nrm " + _sharedRegisters.animatedTangent + ".xyz, " + _sharedRegisters.animatedTangent + "\n" +
                            "crs " + _sharedRegisters.bitangent + ".xyz, " + _sharedRegisters.animatedNormal + ", " + _sharedRegisters.animatedTangent + "\n";

                    _fragmentCode += _materialPass.getNormalFragmentCode(_shaderObject, _registerCache, _sharedRegisters);
                } else {
                    //Compiles the vertex shader code for tangent-space normal maps.
                    _sharedRegisters.tangentVarying = _registerCache.getFreeVarying();
                    _sharedRegisters.bitangentVarying = _registerCache.getFreeVarying();
                    var temp:ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();

                    _vertexCode += "m33 " + temp + ".xyz, " + _sharedRegisters.animatedNormal + ", " + normalMatrix[0] + "\n" +
                            "nrm " + _sharedRegisters.animatedNormal + ".xyz, " + temp + "\n" +
                            "m33 " + temp + ".xyz, " + _sharedRegisters.animatedTangent + ", " + normalMatrix[0] + "\n" +
                            "nrm " + _sharedRegisters.animatedTangent + ".xyz, " + temp + "\n" +
                            "mov " + _sharedRegisters.tangentVarying + ".x, " + _sharedRegisters.animatedTangent + ".x  \n" +
                            "mov " + _sharedRegisters.tangentVarying + ".z, " + _sharedRegisters.animatedNormal + ".x  \n" +
                            "mov " + _sharedRegisters.tangentVarying + ".w, " + _sharedRegisters.normalInput + ".w  \n" +
                            "mov " + _sharedRegisters.bitangentVarying + ".x, " + _sharedRegisters.animatedTangent + ".y  \n" +
                            "mov " + _sharedRegisters.bitangentVarying + ".z, " + _sharedRegisters.animatedNormal + ".y  \n" +
                            "mov " + _sharedRegisters.bitangentVarying + ".w, " + _sharedRegisters.normalInput + ".w  \n" +
                            "mov " + _sharedRegisters.normalVarying + ".x, " + _sharedRegisters.animatedTangent + ".z  \n" +
                            "mov " + _sharedRegisters.normalVarying + ".z, " + _sharedRegisters.animatedNormal + ".z  \n" +
                            "mov " + _sharedRegisters.normalVarying + ".w, " + _sharedRegisters.normalInput + ".w  \n" +
                            "crs " + temp + ".xyz, " + _sharedRegisters.animatedNormal + ", " + _sharedRegisters.animatedTangent + "\n" +
                            "mov " + _sharedRegisters.tangentVarying + ".y, " + temp + ".x    \n" +
                            "mov " + _sharedRegisters.bitangentVarying + ".y, " + temp + ".y  \n" +
                            "mov " + _sharedRegisters.normalVarying + ".y, " + temp + ".z    \n";

                    _registerCache.removeVertexTempUsage(_sharedRegisters.animatedTangent);

                    //Compiles the fragment shader code for tangent-space normal maps.
                    var t:ShaderRegisterElement;
                    var b:ShaderRegisterElement;
                    var n:ShaderRegisterElement;

                    t = _registerCache.getFreeFragmentVectorTemp();
                    _registerCache.addFragmentTempUsages(t, 1);
                    b = _registerCache.getFreeFragmentVectorTemp();
                    _registerCache.addFragmentTempUsages(b, 1);
                    n = _registerCache.getFreeFragmentVectorTemp();
                    _registerCache.addFragmentTempUsages(n, 1);

                    _fragmentCode += "nrm " + t + ".xyz, " + _sharedRegisters.tangentVarying + "\n" +
                            "mov " + t + ".w, " + _sharedRegisters.tangentVarying + ".w	\n" +
                            "nrm " + b + ".xyz, " + _sharedRegisters.bitangentVarying + "\n" +
                            "nrm " + n + ".xyz, " + _sharedRegisters.normalVarying + "\n";

                    //compile custom fragment code for normal calcs
                    _fragmentCode += _materialPass.getNormalFragmentCode(_shaderObject, _registerCache, _sharedRegisters) +
                            "m33 " + _sharedRegisters.normalFragment + ".xyz, " + _sharedRegisters.normalFragment + ", " + t + "\n" +
                            "mov " + _sharedRegisters.normalFragment + ".w, " + _sharedRegisters.normalVarying + ".w\n";

                    _registerCache.removeFragmentTempUsage(b);
                    _registerCache.removeFragmentTempUsage(t);
                    _registerCache.removeFragmentTempUsage(n);
                }
            } else {
                // no output, world space is enough
                _vertexCode += "m33 " + _sharedRegisters.normalVarying + ".xyz, " + _sharedRegisters.animatedNormal + ", " + normalMatrix[0] + "\n" +
                        "mov " + _sharedRegisters.normalVarying + ".w, " + _sharedRegisters.animatedNormal + ".w\n";

                _fragmentCode += "nrm " + _sharedRegisters.normalFragment + ".xyz, " + _sharedRegisters.normalVarying + "\n" +
                        "mov " + _sharedRegisters.normalFragment + ".w, " + _sharedRegisters.normalVarying + ".w\n";

                if (_shaderObject.tangentDependencies > 0) {
                    _sharedRegisters.tangentVarying = _registerCache.getFreeVarying();

                    _vertexCode += "m33 " + _sharedRegisters.tangentVarying + ".xyz, " + _sharedRegisters.animatedTangent + ", " + normalMatrix[0] + "\n" +
                            "mov " + _sharedRegisters.tangentVarying + ".w, " + _sharedRegisters.animatedTangent + ".w\n";
                }
            }

            if (!_shaderObject.usesTangentSpace)
                _registerCache.removeVertexTempUsage(_sharedRegisters.animatedNormal);
        }

        /**
         * Reset all the indices to "unused".
         */
        protected function initRegisterIndices():void
        {
            _shaderObject.initRegisterIndices();

            _animatableAttributes = Vector.<String>(["va0"]);
            _animationTargetRegisters = Vector.<String>(["vt0"]);
            _vertexCode = "";
            _fragmentCode = "";
            _postAnimationFragmentCode = "";

            _registerCache.addVertexTempUsages(_sharedRegisters.localPosition = _registerCache.getFreeVertexVectorTemp(), 1);

            //create commonly shared constant registers
            _sharedRegisters.commons = _registerCache.getFreeFragmentConstant();
            _shaderObject.commonsDataIndex = _sharedRegisters.commons.index * 4;

            //Creates the registers to contain the tangent data.
            // need to be created FIRST and in this order (for when using tangent space)
            if (_shaderObject.tangentDependencies > 0 || _shaderObject.outputsNormals) {
                _sharedRegisters.tangentInput = _registerCache.getFreeVertexAttribute();
                _shaderObject.tangentBufferIndex = _sharedRegisters.tangentInput.index;

                _sharedRegisters.animatedTangent = _registerCache.getFreeVertexVectorTemp();
                _registerCache.addVertexTempUsages(_sharedRegisters.animatedTangent, 1);

                if (_shaderObject.usesTangentSpace) {
                    _sharedRegisters.bitangent = _registerCache.getFreeVertexVectorTemp();
                    _registerCache.addVertexTempUsages(_sharedRegisters.bitangent, 1);
                }

                _animatableAttributes.push(_sharedRegisters.tangentInput.toString());
                _animationTargetRegisters.push(_sharedRegisters.animatedTangent.toString());
            }

            if (_shaderObject.normalDependencies > 0) {
                _sharedRegisters.normalInput = _registerCache.getFreeVertexAttribute();
                _shaderObject.normalBufferIndex = _sharedRegisters.normalInput.index;

                _sharedRegisters.animatedNormal = _registerCache.getFreeVertexVectorTemp();
                _registerCache.addVertexTempUsages(_sharedRegisters.animatedNormal, 1);

                _animatableAttributes.push(_sharedRegisters.normalInput.toString());
                _animationTargetRegisters.push(_sharedRegisters.animatedNormal.toString());
            }
        }

        /**
         * Figure out which named registers are required, and how often.
         */
        protected function calculateDependencies():void
        {
            _shaderObject.useAlphaPremultiplied = _material.alphaPremultiplied;
            _shaderObject.useBothSides = _material.bothSides;
            _shaderObject.useMipmapping = _material.mipmap;
            _shaderObject.useSmoothTextures = _material.smooth;
            _shaderObject.repeatTextures = _material.repeat;
            _shaderObject.usesUVTransform = _material.animateUVs;
            _shaderObject.alphaThreshold = _material.alphaThreshold;
            _shaderObject.texture = _material.texture;
            _shaderObject.color = _material.color;
            //TODO: fragment animtion should be compatible with lighting pass
            _shaderObject.usesFragmentAnimation = Boolean(_materialPass.passMode == MaterialPassMode.SUPER_SHADER);

            _materialPass.includeDependencies(_shaderObject);
        }

        /**
         * Disposes all resources used by the compiler.
         */
        public function dispose():void
        {
            _registerCache.dispose();
            _registerCache = null;
            _sharedRegisters = null;
        }

        /**
         * The generated vertex code.
         */
        public function get vertexCode():String
        {
            return _vertexCode;
        }

        /**
         * The generated fragment code.
         */
        public function get fragmentCode():String
        {
            return _fragmentCode;
        }

        /**
         * The generated fragment code.
         */
        public function get postAnimationFragmentCode():String
        {
            return _postAnimationFragmentCode;
        }

        /**
         * The register name containing the final shaded colour.
         */
        public function get shadedTarget():String
        {
            return _sharedRegisters.shadedTarget.toString();
        }
    }
}
