package away3d.materials.passes {
    import away3d.arcane;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.events.ShadingMethodEvent;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.methods.AmbientBasicMethod;
    import away3d.materials.methods.DiffuseBasicMethod;
    import away3d.materials.methods.EffectColorTransformMethod;
    import away3d.materials.methods.EffectMethodBase;
    import away3d.materials.methods.LightingMethodBase;
    import away3d.materials.methods.NormalBasicMethod;
    import away3d.materials.methods.ShadowMapMethodBase;
    import away3d.materials.methods.SpecularBasicMethod;

    import flash.geom.ColorTransform;
    import flash.geom.Matrix3D;

    use namespace arcane;

    public class TriangleMethodPass extends MaterialPassBase implements ILightingPass {
        arcane var colorTransformMethodVO:MethodVO;
        arcane var normalMethodVO:MethodVO;
        arcane var ambientMethodVO:MethodVO;
        arcane var shadowMethodVO:MethodVO;
        arcane var diffuseMethodVO:MethodVO;
        arcane var specularMethodVO:MethodVO;
        arcane var methodVOs:Vector.<MethodVO> = new Vector.<MethodVO>();

        public var _numEffectDependencies:int = 0;

        /**
         * Creates a new CompiledPass object.
         *
         * @param material The material to which this pass belongs.
         */
        public function TriangleMethodPass(passMode:int = 0x03)
        {
            super(passMode);
        }

        /**
         * Factory method to create a concrete shader object for this pass.
         *
         * @param profile The compatibility profile used by the renderer.
         */
        override public function createShaderObject(profile:String):ShaderObjectBase
        {
            if (_lightPicker && Boolean(passMode & MaterialPassMode.LIGHTING))
                return new ShaderLightingObject(profile);

            return new ShaderObjectBase(profile);
        }

        /**
         * Initializes the unchanging constant data for this material.
         */
        override public function initConstantData(shaderObject:ShaderObjectBase):void
        {
            super.initConstantData(shaderObject);

            //Updates method constants if they have changed.
            var len:int = methodVOs.length;
            for (var i:int = 0; i < len; ++i)
                methodVOs[i].method.initConstants(shaderObject, methodVOs[i]);
        }

        /**
         * The ColorTransform object to transform the colour of the material with. Defaults to null.
         */
        public function get colorTransform():ColorTransform
        {
            return colorTransformMethod ? colorTransformMethod.colorTransform : null;
        }

        public function set colorTransform(value:ColorTransform):void
        {
            if (value) {
                if (colorTransformMethod == null)
                    colorTransformMethod = new EffectColorTransformMethod();

                colorTransformMethod.colorTransform = value;

            } else if (!value) {
                if (colorTransformMethod)
                    colorTransformMethod = null;
            }
        }

        /**
         * The EffectColorTransformMethod object to transform the colour of the material with. Defaults to null.
         */
        public function get colorTransformMethod():EffectColorTransformMethod
        {
            return colorTransformMethodVO ? colorTransformMethodVO.method as EffectColorTransformMethod : null;
        }

        public function set colorTransformMethod(value:EffectColorTransformMethod)
        {
            if (colorTransformMethodVO && colorTransformMethodVO.method == value)
                return;

            if (colorTransformMethodVO) {
                removeDependency(colorTransformMethodVO);
                colorTransformMethodVO = null;
            }

            if (value) {
                colorTransformMethodVO = new MethodVO(value);
                addDependency(colorTransformMethodVO);
            }
        }

        private function removeDependency(methodVO:MethodVO, effectsDependency:Boolean = false):void
        {
            var index:int = methodVOs.indexOf(methodVO);

            if (!effectsDependency)
                _numEffectDependencies--;

            methodVO.method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
            methodVOs.splice(index, 1);

            invalidatePass();
        }

        private function addDependency(methodVO:MethodVO, effectsDependency:Boolean = false, index:int = -1):void
        {
            methodVO.method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);

            if (effectsDependency) {
                if (index != -1)
                    methodVOs.splice(index + methodVOs.length - _numEffectDependencies, 0, methodVO);
                else
                    methodVOs.push(methodVO);
                _numEffectDependencies++;
            } else {
                methodVOs.splice(methodVOs.length - _numEffectDependencies, 0, methodVO);
            }

            invalidatePass();
        }

        /**
         * Appends an "effect" shading method to the shader. Effect methods are those that do not influence the lighting
         * but modulate the shaded colour, used for fog, outlines, etc. The method will be applied to the result of the
         * methods added prior.
         */
        public function addEffectMethod(method:EffectMethodBase):void
        {
            addDependency(new MethodVO(method), true);
        }

        /**
         * The number of "effect" methods added to the material.
         */
        public function get numEffectMethods():int
        {
            return _numEffectDependencies;
        }

        /**
         * Queries whether a given effects method was added to the material.
         *
         * @param method The method to be queried.
         * @return true if the method was added to the material, false otherwise.
         */
        public function hasEffectMethod(method:EffectMethodBase):Boolean
        {
            return getDependencyForMethod(method) != null;
        }

        /**
         * Returns the method added at the given index.
         * @param index The index of the method to retrieve.
         * @return The method at the given index.
         */
        public function getEffectMethodAt(index:int):EffectMethodBase
        {
            if (index < 0 || index > _numEffectDependencies - 1)
                return null;

            return methodVOs[index + methodVOs.length - _numEffectDependencies].method as EffectMethodBase
        }

        /**
         * Adds an effect method at the specified index amongst the methods already added to the material. Effect
         * methods are those that do not influence the lighting but modulate the shaded colour, used for fog, outlines,
         * etc. The method will be applied to the result of the methods with a lower index.
         */
        public function addEffectMethodAt(method:EffectMethodBase, index:int):void
        {
            this.addDependency(new MethodVO(method), true, index);
        }

        /**
         * Removes an effect method from the material.
         * @param method The method to be removed.
         */
        public function removeEffectMethod(method:EffectMethodBase):void
        {
            var methodVO:MethodVO = getDependencyForMethod(method);

            if (methodVO != null)
                removeDependency(methodVO, true);
        }


        private function getDependencyForMethod(method:EffectMethodBase):MethodVO
        {
            var len:int = methodVOs.length;
            for (var i:int = 0; i < len; ++i)
                if (methodVOs[i].method == method)
                    return methodVOs[i];

            return null;
        }

        /**
         * The method used to generate the per-pixel normals. Defaults to NormalBasicMethod.
         */
        public function get normalMethod():NormalBasicMethod
        {
            return normalMethodVO ? normalMethodVO.method as NormalBasicMethod : null;
        }

        public function set normalMethod(value:NormalBasicMethod)
        {
            if (normalMethodVO && normalMethodVO.method == value)
                return;

            if (normalMethodVO) {
                removeDependency(normalMethodVO);
                normalMethodVO = null;
            }

            if (value) {
                normalMethodVO = new MethodVO(value);
                addDependency(normalMethodVO);
            }
        }

        /**
         * The method that provides the ambient lighting contribution. Defaults to AmbientBasicMethod.
         */
        public function get ambientMethod():AmbientBasicMethod
        {
            return this.ambientMethodVO ? ambientMethodVO.method as AmbientBasicMethod : null;
        }

        public function set ambientMethod(value:AmbientBasicMethod)
        {
            if (ambientMethodVO && ambientMethodVO.method == value)
                return;

            if (ambientMethodVO) {
                removeDependency(ambientMethodVO);
                ambientMethodVO = null;
            }

            if (value) {
                ambientMethodVO = new MethodVO(value);
                addDependency(ambientMethodVO);
            }
        }

        /**
         * The method used to render shadows cast on this surface, or null if no shadows are to be rendered. Defaults to null.
         */
        public function get shadowMethod():ShadowMapMethodBase
        {
            return shadowMethodVO ? shadowMethodVO.method as ShadowMapMethodBase : null;
        }

        public function set shadowMethod(value:ShadowMapMethodBase)
        {
            if (shadowMethodVO && shadowMethodVO.method == value)
                return;

            if (shadowMethodVO) {
                removeDependency(shadowMethodVO);
                shadowMethodVO = null;
            }

            if (value) {
                shadowMethodVO = new MethodVO(value);
                addDependency(shadowMethodVO);
            }
        }

        /**
         * The method that provides the diffuse lighting contribution. Defaults to DiffuseBasicMethod.
         */
        public function get diffuseMethod():DiffuseBasicMethod
        {
            return diffuseMethodVO ? diffuseMethodVO.method as DiffuseBasicMethod : null;
        }

        public function set diffuseMethod(value:DiffuseBasicMethod)
        {
            if (diffuseMethodVO && diffuseMethodVO.method == value)
                return;

            if (diffuseMethodVO) {
                removeDependency(diffuseMethodVO);
                diffuseMethodVO = null;
            }

            if (value) {
                diffuseMethodVO = new MethodVO(value);
                addDependency(diffuseMethodVO);
            }
        }

        /**
         * The method that provides the specular lighting contribution. Defaults to SpecularBasicMethod.
         */
        public function get specularMethod():SpecularBasicMethod
        {
            return specularMethodVO ? specularMethodVO.method as SpecularBasicMethod : null;
        }

        public function set specularMethod(value:SpecularBasicMethod)
        {
            if (specularMethodVO && specularMethodVO.method == value)
                return;

            if (specularMethodVO) {
                removeDependency(specularMethodVO);
                specularMethodVO = null;
            }

            if (value) {
                specularMethodVO = new MethodVO(value);
                addDependency(specularMethodVO);
            }
        }

        /**
         * @inheritDoc
         */
        override public function dispose():void
        {
            super.dispose();

            while (methodVOs.length)
                removeDependency(methodVOs[0]);

            methodVOs = null;
        }

        /**
         * Called when any method's shader code is invalidated.
         */
        private function onShaderInvalidated(event:ShadingMethodEvent):void
        {
            invalidatePass();
        }

        // RENDER LOOP

        /**
         * @inheritDoc
         */
        override public function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
        {
            super.activate(pass, stage, camera);

            var methodVO:MethodVO;
            var len:int = methodVOs.length;
            for (var i:int = 0; i < len; ++i) {
                methodVO = this.methodVOs[i];
                if (methodVO.useMethod)
                    methodVO.method.activate(pass.shaderObject, methodVO, stage);
            }
        }

        /**
         *
         *
         * @param renderable
         * @param stage
         * @param camera
         */
        override public function setRenderState(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
        {
            super.setRenderState(pass, renderable, stage, camera, viewProjection);

            var methodVO:MethodVO;
            var len:int = methodVOs.length;
            for (var i:int = 0; i < len; ++i) {
                methodVO = methodVOs[i];
                if (methodVO.useMethod)
                    methodVO.method.setRenderState(pass.shaderObject, methodVO, renderable, stage, camera);
            }
        }

        /**
         * @inheritDoc
         */
        override public function deactivate(pass:MaterialPassData, stage:Stage3DProxy):void
        {
            super.deactivate(pass, stage);

            var methodVO:MethodVO;
            var len:int = methodVOs.length;
            for (var i:int = 0; i < len; ++i) {
                methodVO = methodVOs[i];
                if (methodVO.useMethod)
                    methodVO.method.deactivate(pass.shaderObject, methodVO, stage);
            }
        }

        override public function includeDependencies(shaderObject:ShaderObjectBase):void
        {
            var i:int;
            var len:int = methodVOs.length;
            for (i = 0; i < len; ++i)
                setupAndCountDependencies(shaderObject, methodVOs[i]);

            for (i = 0; i < len; ++i)
                methodVOs[i].useMethod = methodVOs[i].method.isUsed(shaderObject);

            super.includeDependencies(shaderObject);
        }


        /**
         * Counts the dependencies for a given method.
         * @param shaderObject The method to count the dependencies for.
         * @param methodVO The method's data for this material.
         */
        private function setupAndCountDependencies(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            methodVO.reset();

            methodVO.method.initVO(shaderObject, methodVO);

            if (methodVO.needsProjection)
                shaderObject.projectionDependencies++;

            if (methodVO.needsGlobalVertexPos) {

                shaderObject.globalPosDependencies++;

                if (methodVO.needsGlobalFragmentPos)
                    shaderObject.usesGlobalPosFragment = true;

            } else if (methodVO.needsGlobalFragmentPos) {
                shaderObject.globalPosDependencies++;
                shaderObject.usesGlobalPosFragment = true;
            }

            if (methodVO.needsNormals)
                shaderObject.normalDependencies++;

            if (methodVO.needsTangents)
                shaderObject.tangentDependencies++;

            if (methodVO.needsView)
                shaderObject.viewDirDependencies++;

            if (methodVO.needsUV)
                shaderObject.uvDependencies++;

            if (methodVO.needsSecondaryUV)
                shaderObject.secondaryUVDependencies++;
        }

        override public function getPreLightingVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            if (this.ambientMethodVO && this.ambientMethodVO.useMethod)
                code += this.ambientMethodVO.method.getVertexCode(shaderObject, this.ambientMethodVO, registerCache, sharedRegisters);

            if (this.diffuseMethodVO && this.diffuseMethodVO.useMethod)
                code += this.diffuseMethodVO.method.getVertexCode(shaderObject, this.diffuseMethodVO, registerCache, sharedRegisters);

            if (this.specularMethodVO && this.specularMethodVO.useMethod)
                code += this.specularMethodVO.method.getVertexCode(shaderObject, this.specularMethodVO, registerCache, sharedRegisters);

            return code;
        }

        override public function getPreLightingFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            if (this.ambientMethodVO && this.ambientMethodVO.useMethod) {
                code += this.ambientMethodVO.method.getFragmentCode(shaderObject, this.ambientMethodVO, sharedRegisters.shadedTarget, registerCache, sharedRegisters);

                if (this.ambientMethodVO.needsNormals)
                    registerCache.removeFragmentTempUsage(sharedRegisters.normalFragment);

                if (this.ambientMethodVO.needsView)
                    registerCache.removeFragmentTempUsage(sharedRegisters.viewDirFragment);
            }

            if (this.diffuseMethodVO && this.diffuseMethodVO.useMethod)
                code += (diffuseMethodVO.method as LightingMethodBase).getFragmentPreLightingCode(shaderObject as ShaderLightingObject, this.diffuseMethodVO, registerCache, sharedRegisters);

            if (this.specularMethodVO && this.specularMethodVO.useMethod)
                code += (this.specularMethodVO.method as LightingMethodBase).getFragmentPreLightingCode(shaderObject as ShaderLightingObject, this.specularMethodVO, registerCache, sharedRegisters);

            return code;
        }

        public function getPerLightDiffuseFragmentCode(shaderObject:ShaderLightingObject, lightDirReg:ShaderRegisterElement, diffuseColorReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return ( this.diffuseMethodVO.method as LightingMethodBase).getFragmentCodePerLight(shaderObject, this.diffuseMethodVO, lightDirReg, diffuseColorReg, registerCache, sharedRegisters);
        }

        public function getPerLightSpecularFragmentCode(shaderObject:ShaderLightingObject, lightDirReg:ShaderRegisterElement, specularColorReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return (this.specularMethodVO.method as LightingMethodBase).getFragmentCodePerLight(shaderObject, this.specularMethodVO, lightDirReg, specularColorReg, registerCache, sharedRegisters);
        }

        public function getPerProbeDiffuseFragmentCode(shaderObject:ShaderLightingObject, texReg:ShaderRegisterElement, weightReg:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return (this.diffuseMethodVO.method as LightingMethodBase).getFragmentCodePerProbe(shaderObject, this.diffuseMethodVO, texReg, weightReg, registerCache, sharedRegisters);
        }

        public function getPerProbeSpecularFragmentCode(shaderObject:ShaderLightingObject, texReg:ShaderRegisterElement, weightReg:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return (this.specularMethodVO.method as LightingMethodBase).getFragmentCodePerProbe(shaderObject, this.specularMethodVO, texReg, weightReg, registerCache, sharedRegisters);
        }

        public function getPostLightingVertexCode(shaderObject:ShaderLightingObject, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            if (this.shadowMethodVO)
                code += this.shadowMethodVO.method.getVertexCode(shaderObject, this.shadowMethodVO, registerCache, sharedRegisters);

            return code;
        }

        public function getPostLightingFragmentCode(shaderObject:ShaderLightingObject, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            if (shaderObject.useAlphaPremultiplied && _enableBlending) {

                code += "add " + sharedRegisters.shadedTarget + ".w, " + sharedRegisters.shadedTarget + ".w, " + sharedRegisters.commons + ".z\n" +
                        "div " + sharedRegisters.shadedTarget + ".xyz, " + sharedRegisters.shadedTarget + ", " + sharedRegisters.shadedTarget + ".w\n" +
                        "sub " + sharedRegisters.shadedTarget + ".w, " + sharedRegisters.shadedTarget + ".w, " + sharedRegisters.commons + ".z\n" +
                        "sat " + sharedRegisters.shadedTarget + ".xyz, " + sharedRegisters.shadedTarget + "\n";
            }

            if (shadowMethodVO)
                code += shadowMethodVO.method.getFragmentCode(shaderObject, shadowMethodVO, sharedRegisters.shadowTarget, registerCache, sharedRegisters);

            if (diffuseMethodVO && diffuseMethodVO.useMethod) {
                code += (diffuseMethodVO.method as LightingMethodBase).getFragmentPostLightingCode(shaderObject, diffuseMethodVO, sharedRegisters.shadedTarget, registerCache, sharedRegisters);

                // resolve other dependencies as well?
                if (diffuseMethodVO.needsNormals)
                    registerCache.removeFragmentTempUsage(sharedRegisters.normalFragment);

                if (diffuseMethodVO.needsView)
                    registerCache.removeFragmentTempUsage(sharedRegisters.viewDirFragment);
            }

            if (specularMethodVO && specularMethodVO.useMethod) {
                code += (specularMethodVO.method as LightingMethodBase).getFragmentPostLightingCode(shaderObject, specularMethodVO, sharedRegisters.shadedTarget, registerCache, sharedRegisters);
                if (specularMethodVO.needsNormals)
                    registerCache.removeFragmentTempUsage(sharedRegisters.normalFragment);
                if (specularMethodVO.needsView)
                    registerCache.removeFragmentTempUsage(sharedRegisters.viewDirFragment);
            }

            if (shadowMethodVO)
                registerCache.removeFragmentTempUsage(sharedRegisters.shadowTarget);

            return code;
        }

        /**
         * Indicates whether or not normals are allowed in tangent space. This is only the case if no object-space
         * dependencies exist.
         */
        override public function usesTangentSpace(shaderObject:ShaderObjectBase):Boolean
        {
            var shaderLightingObject:ShaderLightingObject = shaderObject as ShaderLightingObject;
            if (shaderLightingObject.usesProbes)
                return false;

            var methodVO:MethodVO;
            var len:int = methodVOs.length;
            for (var i:int = 0; i < len; ++i) {
                methodVO = methodVOs[i];
                if (methodVO.useMethod && !methodVO.method.usesTangentSpace())
                    return false;
            }

            return true;
        }

        /**
         * Indicates whether or not normals are output in tangent space.
         */

        override public function outputsTangentNormals(shaderObject:ShaderObjectBase):Boolean
        {
            return (normalMethodVO.method as NormalBasicMethod).outputsTangentNormals();
        }


        /**
         * Indicates whether or not normals are output by the pass.
         */

        override protected function outputsNormals(shaderObject:ShaderObjectBase):Boolean
        {
            return normalMethodVO && normalMethodVO.useMethod;
        }


        override public function getNormalVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return normalMethodVO.method.getVertexCode(shaderObject, normalMethodVO, registerCache, sharedRegisters);
        }

        override public function getNormalFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = normalMethodVO.method.getFragmentCode(shaderObject, normalMethodVO, sharedRegisters.normalFragment, registerCache, sharedRegisters);

            if (normalMethodVO.needsView)
                registerCache.removeFragmentTempUsage(sharedRegisters.viewDirFragment);

            if (normalMethodVO.needsGlobalFragmentPos || normalMethodVO.needsGlobalVertexPos)
                registerCache.removeVertexTempUsage(sharedRegisters.globalPositionVertex);

            return code;
        }

        /**
         * @inheritDoc
         */
        override public function getVertexCode(shaderObject:ShaderObjectBase, regCache:ShaderRegisterCache, sharedReg:ShaderRegisterData):String
        {
            var code:String = "";
            var methodVO:MethodVO;
            var len:int = methodVOs.length;
            for (var i:int = len - _numEffectDependencies; i < len; i++) {
                methodVO = methodVOs[i];
                if (methodVO.useMethod) {
                    code += methodVO.method.getVertexCode(shaderObject, methodVO, regCache, sharedReg);

                    if (methodVO.needsGlobalVertexPos || methodVO.needsGlobalFragmentPos)
                        regCache.removeVertexTempUsage(sharedReg.globalPositionVertex);
                }
            }

            if (colorTransformMethodVO && colorTransformMethodVO.useMethod)
                code += colorTransformMethodVO.method.getVertexCode(shaderObject, colorTransformMethodVO, regCache, sharedReg);

            return code;
        }

        /**
         * @inheritDoc
         */
        override public function getFragmentCode(shaderObject:ShaderObjectBase, regCache:ShaderRegisterCache, sharedReg:ShaderRegisterData):String
        {
            var code:String = "";
            var alphaReg:ShaderRegisterElement;

            if (preserveAlpha && _numEffectDependencies > 0) {
                alphaReg = regCache.getFreeFragmentSingleTemp();
                regCache.addFragmentTempUsages(alphaReg, 1);
                code += "mov " + alphaReg + ", " + sharedReg.shadedTarget + ".w\n";
            }

            var methodVO:MethodVO;
            var len:int = methodVOs.length;
            for (var i:int = len - _numEffectDependencies; i < len; i++) {
                methodVO = methodVOs[i];
                if (methodVO.useMethod) {
                    code += methodVO.method.getFragmentCode(shaderObject, methodVO, sharedReg.shadedTarget, regCache, sharedReg);

                    if (methodVO.needsNormals)
                        regCache.removeFragmentTempUsage(sharedReg.normalFragment);

                    if (methodVO.needsView)
                        regCache.removeFragmentTempUsage(sharedReg.viewDirFragment);

                }
            }

            if (preserveAlpha && _numEffectDependencies > 0) {
                code += "mov " + sharedReg.shadedTarget + ".w, " + alphaReg + "\n";
                regCache.removeFragmentTempUsage(alphaReg);
            }

            if (colorTransformMethodVO && colorTransformMethodVO.useMethod)
                code += colorTransformMethodVO.method.getFragmentCode(shaderObject, colorTransformMethodVO, sharedReg.shadedTarget, regCache, sharedReg);

            return code;
        }

        /**
         * Indicates whether the shader uses any shadows.
         */
        public function usesShadows():Boolean
        {
            return Boolean(shadowMethodVO || lightPicker.castingDirectionalLights.length > 0 || lightPicker.castingPointLights.length > 0);
        }

        /**
         * Indicates whether the shader uses any specular component.
         */
        public function usesSpecular():Boolean
        {
            return Boolean(specularMethodVO);
        }
    }
}
