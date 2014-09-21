package away3d.materials.compilation {
    import away3d.materials.LightSources;
    import away3d.materials.MaterialBase;
    import away3d.materials.passes.ILightingPass;

    import flash.display3D.Context3DProfile;

    /**
     * LightingShaderCompiler is a ShaderCompiler that generates code for passes performing shading only (no effect passes)
     */
    public class ShaderLightingCompiler extends ShaderCompilerBase {
        private var _materialLightingPass:ILightingPass;
        private var _shaderLightingObject:ShaderLightingObject;
        public var _pointLightFragmentConstants:Vector.<ShaderRegisterElement>;
        public var _pointLightVertexConstants:Vector.<ShaderRegisterElement>;
        public var _dirLightFragmentConstants:Vector.<ShaderRegisterElement>;
        public var _dirLightVertexConstants:Vector.<ShaderRegisterElement>;

        protected var _numProbeRegisters:Number;

        /**
         * Creates a new ShaderCompilerBase object.
         * @param profile The compatibility profile of the renderer.
         */
        public function ShaderLightingCompiler(material:MaterialBase, materialPass:ILightingPass, shaderObject:ShaderLightingObject)
        {
            super(material, materialPass, shaderObject);

            _materialLightingPass = materialPass;
            _shaderLightingObject = shaderObject;
        }

        /**
         * Compile the code for the methods.
         */
        override protected function compileDependencies():void
        {
            super.compileDependencies();

            //compile the lighting code
            if (_shaderLightingObject.usesShadows)
                compileShadowCode();

            if (_shaderLightingObject.usesLights) {
                initLightRegisters();
                compileLightCode();
            }

            if (_shaderLightingObject.usesProbes)
                compileLightProbeCode();

            _vertexCode += _materialLightingPass.getPostLightingVertexCode(_shaderLightingObject, _registerCache, _sharedRegisters);
            _fragmentCode += _materialLightingPass.getPostLightingFragmentCode(_shaderLightingObject, _registerCache, _sharedRegisters);
        }

        /**
         * Provides the code to provide shadow mapping.
         */
        public function compileShadowCode():void
        {
            if (_shaderLightingObject.normalDependencies > 0) {
                _sharedRegisters.shadowTarget = _sharedRegisters.normalFragment;
            } else {
                _sharedRegisters.shadowTarget = _registerCache.getFreeFragmentVectorTemp();
                _registerCache.addFragmentTempUsages(_sharedRegisters.shadowTarget, 1);
            }
        }

        /**
         * Initializes constant registers to contain light data.
         */
        private function initLightRegisters():void
        {
            // init these first so we're sure they're in sequence
            var i:Number, len:Number;

            if (_dirLightVertexConstants) {
                len = _dirLightVertexConstants.length;
                for (i = 0; i < len; ++i) {
                    _dirLightVertexConstants[i] = _registerCache.getFreeVertexConstant();

                    if (_shaderLightingObject.lightVertexConstantIndex == -1)
                        _shaderLightingObject.lightVertexConstantIndex = _dirLightVertexConstants[i].index * 4;
                }
            }

            if (_pointLightVertexConstants) {
                len = _pointLightVertexConstants.length;
                for (i = 0; i < len; ++i) {
                    _pointLightVertexConstants[i] = _registerCache.getFreeVertexConstant();

                    if (_shaderLightingObject.lightVertexConstantIndex == -1)
                        _shaderLightingObject.lightVertexConstantIndex = _pointLightVertexConstants[i].index * 4;
                }
            }

            len = _dirLightFragmentConstants.length;
            for (i = 0; i < len; ++i) {
                _dirLightFragmentConstants[i] = _registerCache.getFreeFragmentConstant();

                if (_shaderLightingObject.lightFragmentConstantIndex == -1)
                    _shaderLightingObject.lightFragmentConstantIndex = _dirLightFragmentConstants[i].index * 4;
            }

            len = _pointLightFragmentConstants.length;
            for (i = 0; i < len; ++i) {
                _pointLightFragmentConstants[i] = _registerCache.getFreeFragmentConstant();

                if (_shaderLightingObject.lightFragmentConstantIndex == -1)
                    _shaderLightingObject.lightFragmentConstantIndex = _pointLightFragmentConstants[i].index * 4;
            }
        }

        /**
         * Compiles the shading code for directional and point lights.
         */
        private function compileLightCode():void
        {
            var diffuseColorReg:ShaderRegisterElement;
            var specularColorReg:ShaderRegisterElement;
            var lightPosReg:ShaderRegisterElement;
            var lightDirReg:ShaderRegisterElement;
            var vertexRegIndex:Number = 0;
            var fragmentRegIndex:Number = 0;
            var addSpec:Boolean = _shaderLightingObject.usesLightsForSpecular;
            var addDiff:Boolean = _shaderLightingObject.usesLightsForDiffuse;
            var lightVarying:ShaderRegisterElement;

            //compile the shading code for directional lights.
            for (var i:Number = 0; i < _materialLightingPass.numDirectionalLights; ++i) {
                if (_shaderLightingObject.usesTangentSpace) {
                    lightDirReg = _dirLightVertexConstants[vertexRegIndex++];
                    lightVarying = _registerCache.getFreeVarying();

                    _vertexCode += "m33 " + lightVarying + ".xyz, " + lightDirReg + ", " + _sharedRegisters.animatedTangent + "\n" +
                            "mov " + lightVarying + ".w, " + lightDirReg + ".w\n";

                    lightDirReg = _registerCache.getFreeFragmentVectorTemp();
                    _registerCache.addVertexTempUsages(lightDirReg, 1);

                    _fragmentCode += "nrm " + lightDirReg + ".xyz, " + lightVarying + "\n" +
                            "mov " + lightDirReg + ".w, " + lightVarying + ".w\n";

                } else {
                    lightDirReg = _dirLightFragmentConstants[fragmentRegIndex++];
                }

                diffuseColorReg = _dirLightFragmentConstants[fragmentRegIndex++];
                specularColorReg = _dirLightFragmentConstants[fragmentRegIndex++];

                if (addDiff)
                    _fragmentCode += _materialLightingPass.getPerLightDiffuseFragmentCode(_shaderLightingObject, lightDirReg, diffuseColorReg, _registerCache, _sharedRegisters);

                if (addSpec)
                    _fragmentCode += _materialLightingPass.getPerLightSpecularFragmentCode(_shaderLightingObject, lightDirReg, specularColorReg, _registerCache, _sharedRegisters);

                if (_shaderLightingObject.usesTangentSpace)
                    _registerCache.removeVertexTempUsage(lightDirReg);
            }

            vertexRegIndex = 0;
            fragmentRegIndex = 0;

            //compile the shading code for point lights
            for (i = 0; i < _materialLightingPass.numPointLights; ++i) {

                if (_shaderLightingObject.usesTangentSpace || !_shaderLightingObject.usesGlobalPosFragment)
                    lightPosReg = _pointLightVertexConstants[vertexRegIndex++];
                else
                    lightPosReg = _pointLightFragmentConstants[fragmentRegIndex++];

                diffuseColorReg = _pointLightFragmentConstants[fragmentRegIndex++];
                specularColorReg = _pointLightFragmentConstants[fragmentRegIndex++];

                lightDirReg = _registerCache.getFreeFragmentVectorTemp();
                _registerCache.addFragmentTempUsages(lightDirReg, 1);



                if (_shaderLightingObject.usesTangentSpace) {
                    lightVarying = _registerCache.getFreeVarying();
                    var temp:ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
                    _vertexCode += "sub " + temp + ", " + lightPosReg + ", " + _sharedRegisters.localPosition + "\n" +
                            "m33 " + lightVarying + ".xyz, " + temp + ", " + _sharedRegisters.animatedTangent + "\n" +
                            "mov " + lightVarying + ".w, " + _sharedRegisters.localPosition + ".w\n";
                } else if (!_shaderLightingObject.usesGlobalPosFragment) {
                    lightVarying = _registerCache.getFreeVarying();
                    _vertexCode += "sub " + lightVarying + ", " + lightPosReg + ", " + _sharedRegisters.globalPositionVertex + "\n";
                } else {
                    lightVarying = lightDirReg;
                    _fragmentCode += "sub " + lightDirReg + ", " + lightPosReg + ", " + _sharedRegisters.globalPositionVarying + "\n";
                }

                if (_shaderLightingObject.usesLightFallOff) {
                    // calculate attenuation
                    _fragmentCode += // attenuate
                            "dp3 " + lightDirReg + ".w, " + lightVarying + ", " + lightVarying + "\n" + // w = d - radius
                            "sub " + lightDirReg + ".w, " + lightDirReg + ".w, " + diffuseColorReg + ".w\n" + // w = (d - radius)/(max-min)
                            "mul " + lightDirReg + ".w, " + lightDirReg + ".w, " + specularColorReg + ".w\n" + // w = clamp(w, 0, 1)
                            "sat " + lightDirReg + ".w, " + lightDirReg + ".w\n" + // w = 1-w
                            "sub " + lightDirReg + ".w, " + _sharedRegisters.commons + ".w, " + lightDirReg + ".w\n" + // normalize
                            "nrm " + lightDirReg + ".xyz, " + lightVarying + "\n";
                } else {
                    _fragmentCode += "nrm " + lightDirReg + ".xyz, " + lightVarying + "\n" +
                            "mov " + lightDirReg + ".w, " + lightVarying + ".w\n";
                }

                if (_shaderLightingObject.lightFragmentConstantIndex == -1)
                    _shaderLightingObject.lightFragmentConstantIndex = lightPosReg.index * 4;

                if (addDiff)
                    _fragmentCode += _materialLightingPass.getPerLightDiffuseFragmentCode(_shaderLightingObject, lightDirReg, diffuseColorReg, _registerCache, _sharedRegisters);

                if (addSpec)
                    _fragmentCode += _materialLightingPass.getPerLightSpecularFragmentCode(_shaderLightingObject, lightDirReg, specularColorReg, _registerCache, _sharedRegisters);

                _registerCache.removeFragmentTempUsage(lightDirReg);
            }
        }

        /**
         * Compiles shading code for light probes.
         */
        private function compileLightProbeCode():void
        {
            var weightReg:String;
            var weightComponents:Array = [ ".x", ".y", ".z", ".w" ];
            var weightRegisters:Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>();
            var i:Number;
            var texReg:ShaderRegisterElement;
            var addSpec:Boolean = _shaderLightingObject.usesProbesForSpecular;
            var addDiff:Boolean = _shaderLightingObject.usesProbesForDiffuse;

            if (addDiff)
                _shaderLightingObject.lightProbeDiffuseIndices = new Vector.<int>();

            if (addSpec)
                _shaderLightingObject.lightProbeSpecularIndices = new Vector.<int>();

            for (i = 0; i < _numProbeRegisters; ++i) {
                weightRegisters[i] = _registerCache.getFreeFragmentConstant();

                if (i == 0)
                    _shaderLightingObject.probeWeightsIndex = weightRegisters[i].index * 4;
            }

            for (i = 0; i < _materialLightingPass.numLightProbes; ++i) {
                weightReg = weightRegisters[Math.floor(i / 4)].toString() + weightComponents[i % 4];

                if (addDiff) {
                    texReg = _registerCache.getFreeTextureReg();
                    _shaderLightingObject.lightProbeDiffuseIndices[i] = texReg.index;
                    _fragmentCode += _materialLightingPass.getPerProbeDiffuseFragmentCode(_shaderLightingObject, texReg, weightReg, _registerCache, _sharedRegisters);
                }

                if (addSpec) {
                    texReg = _registerCache.getFreeTextureReg();
                    _shaderLightingObject.lightProbeSpecularIndices[i] = texReg.index;
                    _fragmentCode += _materialLightingPass.getPerProbeSpecularFragmentCode(_shaderLightingObject, texReg, weightReg, _registerCache, _sharedRegisters);
                }
            }
        }

        /**
         * Reset all the indices to "unused".
         */
        override protected function initRegisterIndices():void
        {
            super.initRegisterIndices();

            _shaderLightingObject.lightVertexConstantIndex = -1;
            _shaderLightingObject.lightFragmentConstantIndex = -1;
            _shaderLightingObject.probeWeightsIndex = -1;

            _numProbeRegisters = Math.ceil(_materialLightingPass.numLightProbes / 4);

            //init light data
            if (_shaderLightingObject.usesTangentSpace || !_shaderLightingObject.usesGlobalPosFragment) {
                _pointLightVertexConstants = new Vector.<ShaderRegisterElement>(_materialLightingPass.numPointLights);
                _pointLightFragmentConstants = new Vector.<ShaderRegisterElement>(_materialLightingPass.numPointLights * 2);
            } else {
                _pointLightFragmentConstants = new Vector.<ShaderRegisterElement>(_materialLightingPass.numPointLights * 3);
            }

            if (_shaderLightingObject.usesTangentSpace) {
                _dirLightVertexConstants = new Vector.<ShaderRegisterElement>(_materialLightingPass.numDirectionalLights);
                _dirLightFragmentConstants = new Vector.<ShaderRegisterElement>(_materialLightingPass.numDirectionalLights * 2);
            } else {
                _dirLightFragmentConstants = new Vector.<ShaderRegisterElement>(_materialLightingPass.numDirectionalLights * 3);
            }
        }


        /**
         * Figure out which named registers are required, and how often.
         */
        override protected function calculateDependencies():void
        {
            var numAllLights:Number = _materialLightingPass.numPointLights + _materialLightingPass.numDirectionalLights;
            var numLightProbes:Number = _materialLightingPass.numLightProbes;
            var diffuseLightSources:Number = _material.diffuseLightSources;
            var specularLightSources:Number = _materialLightingPass.usesSpecular() ? _material.specularLightSources : 0x00;
            var combinedLightSources:Number = diffuseLightSources | specularLightSources;

            _shaderLightingObject.usesLightFallOff = _material.enableLightFallOff && _shaderLightingObject.profile != Context3DProfile.BASELINE_CONSTRAINED;
            _shaderLightingObject.numLights = numAllLights + numLightProbes;
            _shaderLightingObject.numPointLights = _materialLightingPass.numPointLights;
            _shaderLightingObject.numDirectionalLights = _materialLightingPass.numDirectionalLights;
            _shaderLightingObject.numLightProbes = numLightProbes;
            _shaderLightingObject.pointLightsOffset = _materialLightingPass.pointLightsOffset;
            _shaderLightingObject.directionalLightsOffset = _materialLightingPass.directionalLightsOffset;
            _shaderLightingObject.lightProbesOffset = _materialLightingPass.lightProbesOffset;
            _shaderLightingObject.lightPicker = _materialLightingPass.lightPicker;
            _shaderLightingObject.usesLights = numAllLights > 0 && (combinedLightSources & LightSources.LIGHTS) != 0;
            _shaderLightingObject.usesProbes = numLightProbes > 0 && (combinedLightSources & LightSources.PROBES) != 0;
            _shaderLightingObject.usesLightsForSpecular = numAllLights > 0 && (specularLightSources & LightSources.LIGHTS) != 0;
            _shaderLightingObject.usesProbesForSpecular = numLightProbes > 0 && (specularLightSources & LightSources.PROBES) != 0;
            _shaderLightingObject.usesLightsForDiffuse = numAllLights > 0 && (diffuseLightSources & LightSources.LIGHTS) != 0;
            _shaderLightingObject.usesProbesForDiffuse = numLightProbes > 0 && (diffuseLightSources & LightSources.PROBES) != 0;
            _shaderLightingObject.usesShadows = _materialLightingPass.usesShadows();

            super.calculateDependencies();
        }
    }
}
