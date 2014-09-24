package away3d.materials.compilation {
    import away3d.arcane;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.entities.DirectionalLight;
    import away3d.entities.LightProbe;
    import away3d.entities.PointLight;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.MaterialBase;
    import away3d.materials.lightpickers.LightPickerBase;
    import away3d.materials.passes.ILightingPass;
    import away3d.materials.passes.IMaterialPass;
    import away3d.materials.passes.MaterialPassBase;

    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    use namespace arcane;

    public class ShaderLightingObject extends ShaderObjectBase {
        /**
         * The first index for the fragment constants containing the light data.
         */
        public var lightFragmentConstantIndex:int;

        /**
         * The starting index if the vertex constant to which light data needs to be uploaded.
         */
        public var lightVertexConstantIndex:int;

        /**
         * Indices for the light probe diffuse textures.
         */
        public var lightProbeDiffuseIndices:Vector.<int> /*uint*/;

        /**
         * Indices for the light probe specular textures.
         */
        public var lightProbeSpecularIndices:Vector.<int> /*uint*/;

        /**
         * The index of the fragment constant containing the weights for the light probes.
         */
        public var probeWeightsIndex:Number;

        public var numLights:Number;
        public var usesLightFallOff:Boolean;

        public var usesShadows:Boolean;

        public var numPointLights:int;
        public var numDirectionalLights:int;
        public var numLightProbes:int;
        public var pointLightsOffset:int;
        public var directionalLightsOffset:int;
        public var lightProbesOffset:Number;
        public var lightPicker:LightPickerBase;

        /**
         * Indicates whether the shader uses any lights.
         */
        public var usesLights:Boolean;

        /**
         * Indicates whether the shader uses any light probes.
         */
        public var usesProbes:Boolean;

        /**
         * Indicates whether the lights uses any specular components.
         */
        public var usesLightsForSpecular:Boolean;

        /**
         * Indicates whether the probes uses any specular components.
         */
        public var usesProbesForSpecular:Boolean;

        /**
         * Indicates whether the lights uses any diffuse components.
         */
        public var usesLightsForDiffuse:Boolean;

        /**
         * Indicates whether the probes uses any diffuse components.
         */
        public var usesProbesForDiffuse:Boolean;

        /**
         * Creates a new MethodCompilerVO object.
         */
        public function ShaderLightingObject(profile:String):void
        {
            super(profile);
        }

        /**
         * Factory method to create a concrete compiler object for this object
         */
        override public function createCompiler(material:MaterialBase, materialPass:IMaterialPass):ShaderCompilerBase
        {
            return new ShaderLightingCompiler(material, materialPass as ILightingPass, this);
        }

        /**
         * Clears dependency counts for all registers. Called when recompiling a pass.
         */
        override public function reset():void
        {
            super.reset();

            numLights = 0;
            usesLightFallOff = true;
        }

        /**
         * Adds any external world space dependencies, used to force world space calculations.
         */
        override public function addWorldSpaceDependencies(fragmentLights:Boolean):void
        {
            super.addWorldSpaceDependencies(fragmentLights);

            if (numPointLights > 0 && usesLights) {
                ++globalPosDependencies;

                if (fragmentLights)
                    usesGlobalPosFragment = true;
            }
        }

        /**
         *
         *
         * @param renderable
         * @param stage
         * @param camera
         */
        override public function setRenderState(renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
        {
            super.setRenderState(renderable, stage, camera, viewProjection);

            if (usesLights)
                updateLights();

            if (usesProbes)
                updateProbes(stage);
        }

        /**
         * Updates constant data render state used by the lights. This method is optional for subclasses to implement.
         */
        private function updateLights():void
        {
            var dirLight:DirectionalLight;
            var pointLight:PointLight;
            var i:int = 0;
            var k:int = 0;
            var len:int;
            var dirPos:Vector3D;
            var total:int = 0;
            var numLightTypes:int = usesShadows ? 2 : 1;
            var l:int;
            var offset:int;

            ambientR = ambientG = ambientB = 0;

            l = lightVertexConstantIndex;
            k = lightFragmentConstantIndex;

            var cast:Number = 0;
            var dirLights:Vector.<DirectionalLight> = lightPicker.directionalLights;
            offset = directionalLightsOffset;
            len = lightPicker.directionalLights.length;

            if (offset > len) {
                cast = 1;
                offset -= len;
            }

            for (; cast < numLightTypes; ++cast) {
                if (cast)
                    dirLights = lightPicker.castingDirectionalLights;

                len = dirLights.length;

                if (len > numDirectionalLights)
                    len = numDirectionalLights;

                for (i = 0; i < len; ++i) {
                    dirLight = dirLights[offset + i];
                    dirPos = dirLight.sceneDirection;

                    ambientR += dirLight._ambientR;
                    ambientG += dirLight._ambientG;
                    ambientB += dirLight._ambientB;

                    if (usesTangentSpace) {
                        var x:Number = -dirPos.x;
                        var y:Number = -dirPos.y;
                        var z:Number = -dirPos.z;

                        vertexConstantData[l++] = _inverseSceneMatrix[0] * x + _inverseSceneMatrix[4] * y + _inverseSceneMatrix[8] * z;
                        vertexConstantData[l++] = _inverseSceneMatrix[1] * x + _inverseSceneMatrix[5] * y + _inverseSceneMatrix[9] * z;
                        vertexConstantData[l++] = _inverseSceneMatrix[2] * x + _inverseSceneMatrix[6] * y + _inverseSceneMatrix[10] * z;
                        vertexConstantData[l++] = 1;
                    } else {
                        fragmentConstantData[k++] = -dirPos.x;
                        fragmentConstantData[k++] = -dirPos.y;
                        fragmentConstantData[k++] = -dirPos.z;
                        fragmentConstantData[k++] = 1;
                    }

                    fragmentConstantData[k++] = dirLight._diffuseR;
                    fragmentConstantData[k++] = dirLight._diffuseG;
                    fragmentConstantData[k++] = dirLight._diffuseB;
                    fragmentConstantData[k++] = 1;

                    fragmentConstantData[k++] = dirLight._specularR;
                    fragmentConstantData[k++] = dirLight._specularG;
                    fragmentConstantData[k++] = dirLight._specularB;
                    fragmentConstantData[k++] = 1;

                    if (++total == numDirectionalLights) {
                        // break loop
                        i = len;
                        cast = numLightTypes;
                    }
                }
            }

            // more directional supported than currently picked, need to clamp all to 0
            if (numDirectionalLights > total) {
                i = k + (numDirectionalLights - total) * 12;

                while (k < i)
                    fragmentConstantData[k++] = 0;
            }

            total = 0;

            var pointLights:Vector.<PointLight> = lightPicker.pointLights;
            offset = pointLightsOffset;
            len = lightPicker.pointLights.length;

            if (offset > len) {
                cast = 1;
                offset -= len;
            } else {
                cast = 0;
            }

            for (; cast < numLightTypes; ++cast) {
                if (cast)
                    pointLights = lightPicker.castingPointLights;

                len = pointLights.length;

                for (i = 0; i < len; ++i) {
                    pointLight = pointLights[offset + i];
                    dirPos = pointLight.scenePosition;

                    ambientR += pointLight._ambientR;
                    ambientG += pointLight._ambientG;
                    ambientB += pointLight._ambientB;

                    if (usesTangentSpace) {
                        x = dirPos.x;
                        y = dirPos.y;
                        z = dirPos.z;

                        vertexConstantData[l++] = _inverseSceneMatrix[0] * x + _inverseSceneMatrix[4] * y + _inverseSceneMatrix[8] * z + _inverseSceneMatrix[12];
                        vertexConstantData[l++] = _inverseSceneMatrix[1] * x + _inverseSceneMatrix[5] * y + _inverseSceneMatrix[9] * z + _inverseSceneMatrix[13];
                        vertexConstantData[l++] = _inverseSceneMatrix[2] * x + _inverseSceneMatrix[6] * y + _inverseSceneMatrix[10] * z + _inverseSceneMatrix[14];
                        vertexConstantData[l++] = 1;
                    } else if (!usesGlobalPosFragment) {
                        vertexConstantData[l++] = dirPos.x;
                        vertexConstantData[l++] = dirPos.y;
                        vertexConstantData[l++] = dirPos.z;
                        vertexConstantData[l++] = 1;
                    } else {
                        fragmentConstantData[k++] = dirPos.x;
                        fragmentConstantData[k++] = dirPos.y;
                        fragmentConstantData[k++] = dirPos.z;
                        fragmentConstantData[k++] = 1;
                    }

                    fragmentConstantData[k++] = pointLight._diffuseR;
                    fragmentConstantData[k++] = pointLight._diffuseG;
                    fragmentConstantData[k++] = pointLight._diffuseB;

                    var radius:Number = pointLight.radius;
                    fragmentConstantData[k++] = radius * radius;

                    fragmentConstantData[k++] = pointLight._specularR;
                    fragmentConstantData[k++] = pointLight._specularG;
                    fragmentConstantData[k++] = pointLight._specularB;
                    fragmentConstantData[k++] = pointLight._fallOffFactor;

                    if (++total == numPointLights) {
                        // break loop
                        i = len;
                        cast = numLightTypes;
                    }
                }
            }

            // more directional supported than currently picked, need to clamp all to 0
            if (numPointLights > total) {
                i = k + (total - numPointLights) * 12;

                for (; k < i; ++k)
                    fragmentConstantData[k] = 0;
            }
        }

        /**
         * Updates constant data render state used by the light probes. This method is optional for subclasses to implement.
         */
        private function updateProbes(stage:Stage3DProxy):void
        {
            var probe:LightProbe;
            var lightProbes:Vector.<LightProbe> = lightPicker.lightProbes;
            var weights:Vector.<Number> = lightPicker.lightProbeWeights;
            var len:Number = lightProbes.length - lightProbesOffset;
            var addDiff:Boolean = usesProbesForDiffuse;
            var addSpec:Boolean = usesProbesForSpecular;

            if (!(addDiff || addSpec))
                return;

            if (len > numLightProbes)
                len = numLightProbes;

            for (var i:Number = 0; i < len; ++i) {
                probe = lightProbes[ lightProbesOffset + i];

                if (addDiff)
                    stage.activateCubeTexture(lightProbeDiffuseIndices[i], probe.diffuseMap);

                if (addSpec)
                    stage.activateCubeTexture(lightProbeSpecularIndices[i], probe.specularMap);
            }

            for (i = 0; i < len; ++i)
                fragmentConstantData[probeWeightsIndex + i] = weights[lightProbesOffset + i];
        }
    }
}
