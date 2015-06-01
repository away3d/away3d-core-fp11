package away3d.materials {
    import away3d.arcane;
    import away3d.materials.lightpickers.StaticLightPicker;
    import away3d.materials.methods.AmbientBasicMethod;
    import away3d.materials.methods.DiffuseBasicMethod;
    import away3d.materials.methods.EffectMethodBase;
    import away3d.materials.methods.NormalBasicMethod;
    import away3d.materials.methods.ShadowMapMethodBase;
    import away3d.materials.methods.SpecularBasicMethod;
    import away3d.materials.passes.MaterialPassMode;
    import away3d.materials.passes.TriangleMethodPass;
    import away3d.textures.Texture2DBase;

    import flash.display.BlendMode;
    import flash.display3D.Context3DCompareMode;
    import flash.geom.ColorTransform;

    use namespace arcane;

    public class TriangleMethodMaterial extends TriangleMaterialBase {
        private var _alphaBlending:Boolean = false;
        private var _alpha:Number = 1;
        private var _colorTransform:ColorTransform;
        private var _materialMode:String;
        private var _casterLightPass:TriangleMethodPass;
        private var _nonCasterLightPasses:Vector.<TriangleMethodPass>;
        private var _screenPass:TriangleMethodPass;

        private var _ambientMethod:AmbientBasicMethod = new AmbientBasicMethod();
        private var _shadowMethod:ShadowMapMethodBase;
        private var _diffuseMethod:DiffuseBasicMethod = new DiffuseBasicMethod();
        private var _normalMethod:NormalBasicMethod = new NormalBasicMethod();
        private var _specularMethod:SpecularBasicMethod = new SpecularBasicMethod();


        private var _depthCompareMode:String = Context3DCompareMode.LESS_EQUAL;

        /**
         * Creates a new TriangleMethodMaterial object.
         *
         * @param texture The texture used for the material's albedo color.
         * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
         * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to false.
         * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to false.
         */
        public function TriangleMethodMaterial(texture:Texture2DBase = null, smooth:Boolean = true, repeat:Boolean = false, mipmap:Boolean = true)
        {
            super();

            materialMode = TriangleMaterialMode.SINGLE_PASS;

            this.texture = texture;

            this.smooth = smooth;
            this.repeat = repeat;
            this.mipmap = mipmap;
        }


        public function get materialMode():String
        {
            return _materialMode;
        }

        public function set materialMode(value:String):void
        {
            if (_materialMode == value)
                return;

            _materialMode = value;

            invalidateScreenPasses();
        }

        /**
         * The depth compare mode used to render the renderables using this material.
         *
         * @see flash.display3D.Context3DCompareMode
         */

        public function get depthCompareMode():String
        {
            return _depthCompareMode;
        }

        public function set depthCompareMode(value:String):void
        {
            if (_depthCompareMode == value)
                return;

            _depthCompareMode = value;

            invalidateScreenPasses();
        }

        /**
         * The alpha of the surface.
         */
        public function get alpha():Number
        {
            return _alpha;
        }

        public function set alpha(value:Number):void
        {
            if (value > 1)
                value = 1;
            else if (value < 0)
                value = 0;

            if (_alpha == value)
                return;

            _alpha = value;

            if (_colorTransform == null)
                _colorTransform = new ColorTransform();

            _colorTransform.alphaMultiplier = value;

            invalidatePasses();
        }

        /**
         * The ColorTransform object to transform the colour of the material with. Defaults to null.
         */
        public function get colorTransform():ColorTransform
        {
            return _screenPass.colorTransform;
        }

        public function set colorTransform(value:ColorTransform):void
        {
            _screenPass.colorTransform = value;
        }

        /**
         * The texture object to use for the ambient colour.
         */
        public function get diffuseTexture():Texture2DBase
        {
            return _diffuseMethod.texture;
        }

        public function set diffuseTexture(value:Texture2DBase):void
        {
            _diffuseMethod.texture = value;
        }

        /**
         * The method that provides the ambient lighting contribution. Defaults to AmbientBasicMethod.
         */
        public function get ambientMethod():AmbientBasicMethod
        {
            return _ambientMethod;
        }

        public function set ambientMethod(value:AmbientBasicMethod):void
        {
            if (_ambientMethod == value)
                return;

            if (value && _ambientMethod)
                value.copyFrom(_ambientMethod);

            _ambientMethod = value;

            invalidateScreenPasses();
        }

        /**
         * The method used to render shadows cast on this surface, or null if no shadows are to be rendered. Defaults to null.
         */
        public function get shadowMethod():ShadowMapMethodBase
        {
            return _shadowMethod;
        }

        public function set shadowMethod(value:ShadowMapMethodBase):void
        {
            if (_shadowMethod == value)
                return;

            if (value && _shadowMethod)
                value.copyFrom(_shadowMethod);

            _shadowMethod = value;

            invalidateScreenPasses();
        }

        /**
         * The method that provides the diffuse lighting contribution. Defaults to DiffuseBasicMethod.
         */
        public function get diffuseMethod():DiffuseBasicMethod
        {
            return _diffuseMethod;
        }

        public function set diffuseMethod(value:DiffuseBasicMethod):void
        {
            if (_diffuseMethod == value)
                return;

            if (value && _diffuseMethod)
                value.copyFrom(_diffuseMethod);

            _diffuseMethod = value;

            invalidateScreenPasses();
        }

        /**
         * The method that provides the specular lighting contribution. Defaults to SpecularBasicMethod.
         */
        public function get specularMethod():SpecularBasicMethod
        {
            return _specularMethod;
        }

        public function set specularMethod(value:SpecularBasicMethod):void
        {
            if (_specularMethod == value)
                return;

            if (value && _specularMethod)
                value.copyFrom(_specularMethod);

            _specularMethod = value;

            invalidateScreenPasses();
        }

        /**
         * The method used to generate the per-pixel normals. Defaults to NormalBasicMethod.
         */
        public function get normalMethod():NormalBasicMethod
        {
            return _normalMethod;
        }

        public function set normalMethod(value:NormalBasicMethod):void
        {
            if (_normalMethod == value)
                return;

            if (value && _normalMethod)
                value.copyFrom(_normalMethod);

            _normalMethod = value;

            invalidateScreenPasses();
        }

        /**
         * Appends an "effect" shading method to the shader. Effect methods are those that do not influence the lighting
         * but modulate the shaded colour, used for fog, outlines, etc. The method will be applied to the result of the
         * methods added prior.
         */
        public function addEffectMethod(method:EffectMethodBase):void
        {
            if (_screenPass == null)
                _screenPass = new TriangleMethodPass();

            _screenPass.addEffectMethod(method);

            invalidateScreenPasses();
        }

        /**
         * The Number of "effect" methods added to the material.
         */
        public function get numEffectMethods():Number
        {
            return _screenPass ? _screenPass.numEffectMethods : 0;
        }

        /**
         * Queries whether a given effect method was added to the material.
         *
         * @param method The method to be queried.
         * @return true if the method was added to the material, false otherwise.
         */
        public function hasEffectMethod(method:EffectMethodBase):Boolean
        {
            return _screenPass ? _screenPass.hasEffectMethod(method) : false;
        }

        /**
         * Returns the method added at the given index.
         * @param index The index of the method to retrieve.
         * @return The method at the given index.
         */
        public function getEffectMethodAt(index:Number):EffectMethodBase
        {
            if (_screenPass == null)
                return null;

            return _screenPass.getEffectMethodAt(index);
        }

        /**
         * Adds an effect method at the specified index amongst the methods already added to the material. Effect
         * methods are those that do not influence the lighting but modulate the shaded colour, used for fog, outlines,
         * etc. The method will be applied to the result of the methods with a lower index.
         */
        public function addEffectMethodAt(method:EffectMethodBase, index:Number):void
        {
            if (_screenPass == null)
                _screenPass = new TriangleMethodPass();

            _screenPass.addEffectMethodAt(method, index);

            invalidatePasses();
        }

        /**
         * Removes an effect method from the material.
         * @param method The method to be removed.
         */
        public function removeEffectMethod(method:EffectMethodBase):void
        {
            if (_screenPass == null)
                return;

            _screenPass.removeEffectMethod(method);

            // reconsider
            if (_screenPass.numEffectMethods == 0)
                invalidatePasses();
        }

        /**
         * The normal map to modulate the direction of the surface for each texel. The default normal method expects
         * tangent-space normal maps, but others could expect object-space maps.
         */
        public function get normalMap():Texture2DBase
        {
            return _normalMethod.normalMap;
        }

        public function set normalMap(value:Texture2DBase):void
        {
            _normalMethod.normalMap = value;
        }

        /**
         * A specular map that defines the strength of specular reflections for each texel in the red channel,
         * and the gloss factor in the green channel. You can use SpecularBitmapTexture if you want to easily set
         * specular and gloss maps from grayscale images, but correctly authored images are preferred.
         */
        public function get specularMap():Texture2DBase
        {
            return _specularMethod.texture;
        }

        public function set specularMap(value:Texture2DBase):void
        {
            _specularMethod.texture = value;
        }

        /**
         * The glossiness of the material (sharpness of the specular highlight).
         */
        public function get gloss():Number
        {
            return _specularMethod.gloss;
        }

        public function set gloss(value:Number):void
        {
            _specularMethod.gloss = value;
        }

        /**
         * The strength of the ambient reflection.
         */
        public function get ambient():Number
        {
            return _ambientMethod.ambient;
        }

        public function set ambient(value:Number):void
        {
            _ambientMethod.ambient = value;
        }

        /**
         * The overall strength of the specular reflection.
         */
        public function get specular():Number
        {
            return _specularMethod.specular;
        }

        public function set specular(value:Number):void
        {
            _specularMethod.specular = value;
        }

        /**
         * The colour of the ambient reflection.
         */
        public function get ambientColor():Number
        {
            return _diffuseMethod.ambientColor;
        }

        public function set ambientColor(value:Number):void
        {
            _diffuseMethod.ambientColor = value;
        }

        /**
         * The colour of the diffuse reflection.
         */
        public function get diffuseColor():Number
        {
            return _diffuseMethod.diffuseColor;
        }

        public function set diffuseColor(value:Number):void
        {
            _diffuseMethod.diffuseColor = value;
        }

        /**
         * The colour of the specular reflection.
         */
        public function get specularColor():Number
        {
            return _specularMethod.specularColor;
        }

        public function set specularColor(value:Number):void
        {
            _specularMethod.specularColor = value;
        }

        /**
         * Indicates whether or not the material has transparency. If binary transparency is sufficient, for
         * example when using textures of foliage, consider using alphaThreshold instead.
         */

        public function get alphaBlending():Boolean
        {
            return _alphaBlending;
        }

        public function set alphaBlending(value:Boolean):void
        {
            if (_alphaBlending == value)
                return;

            _alphaBlending = value;

            invalidatePasses();
        }

        /**
         * @inheritDoc
         */
        override arcane function updateMaterial():void
        {
            if (_screenPassesInvalid) {
                //Updates screen passes when they were found to be invalid.
                _screenPassesInvalid = false;

                initPasses();

                setBlendAndCompareModes();

                clearScreenPasses();

                if (_materialMode == TriangleMaterialMode.MULTI_PASS) {
                    if (_casterLightPass)
                        addScreenPass(_casterLightPass);

                    if (_nonCasterLightPasses)
                        for (var i:Number = 0; i < _nonCasterLightPasses.length; ++i)
                            addScreenPass(_nonCasterLightPasses[i]);
                }

                if (_screenPass)
                    addScreenPass(_screenPass);
            }
        }

        /**
         * Initializes all the passes and their dependent passes.
         */
        private function initPasses():void
        {
            // let the effects pass handle everything if there are no lights, when there are effect methods applied
            // after shading, or when the material mode is single pass.
            if (numLights == 0 || numEffectMethods > 0 || _materialMode == TriangleMaterialMode.SINGLE_PASS)
                initEffectPass();
            else if (_screenPass)
                removeEffectPass();

            // only use a caster light pass if shadows need to be rendered
            if (_shadowMethod && _materialMode == TriangleMaterialMode.MULTI_PASS)
                initCasterLightPass();
            else if (_casterLightPass)
                removeCasterLightPass();

            // only use non caster light passes if there are lights that don't cast
            if (numNonCasters > 0 && _materialMode == TriangleMaterialMode.MULTI_PASS)
                initNonCasterLightPasses();
            else if (_nonCasterLightPasses)
                removeNonCasterLightPasses();
        }

        /**
         * Sets up the various blending modes for all screen passes, based on whether or not there are previous passes.
         */
        private function setBlendAndCompareModes():void
        {
            var forceSeparateMVP:Boolean = Boolean(_casterLightPass || _screenPass);

            // caster light pass is always first if it exists, hence it uses normal blending
            if (_casterLightPass) {
                _casterLightPass.forceSeparateMVP = forceSeparateMVP;
                _casterLightPass.setBlendMode(BlendMode.NORMAL);
                _casterLightPass.depthCompareMode = _depthCompareMode;
            }

            if (_nonCasterLightPasses) {
                var firstAdditiveIndex:Number = 0;

                // if there's no caster light pass, the first non caster light pass will be the first
                // and should use normal blending
                if (!_casterLightPass) {
                    _nonCasterLightPasses[0].forceSeparateMVP = forceSeparateMVP;
                    _nonCasterLightPasses[0].setBlendMode(BlendMode.NORMAL);
                    _nonCasterLightPasses[0].depthCompareMode = _depthCompareMode;
                    firstAdditiveIndex = 1;
                }

                // all lighting passes following the first light pass should use additive blending
                for (var i:Number = firstAdditiveIndex; i < _nonCasterLightPasses.length; ++i) {
                    _nonCasterLightPasses[i].forceSeparateMVP = forceSeparateMVP;
                    _nonCasterLightPasses[i].setBlendMode(BlendMode.ADD);
                    _nonCasterLightPasses[i].depthCompareMode = Context3DCompareMode.LESS_EQUAL;
                }
            }

            if (_casterLightPass || _nonCasterLightPasses) {
                //cannot be blended by blendmode property if multipass enabled
                _requiresBlending = false;

                // there are light passes, so this should be blended in
                if (_screenPass) {
                    _screenPass.passMode = MaterialPassMode.EFFECTS;
                    _screenPass.depthCompareMode = Context3DCompareMode.LESS_EQUAL;
                    _screenPass.setBlendMode(BlendMode.LAYER);
                    _screenPass.forceSeparateMVP = forceSeparateMVP;
                }

            } else if (_screenPass) {
                _requiresBlending = (_blendMode != BlendMode.NORMAL || _alphaBlending || (_colorTransform && _colorTransform.alphaMultiplier < 1));
                // effects pass is the only pass, so it should just blend normally
                _screenPass.passMode = MaterialPassMode.SUPER_SHADER;
                _screenPass.depthCompareMode = _depthCompareMode;
                _screenPass.preserveAlpha = _requiresBlending;
                _screenPass.colorTransform = _colorTransform;
                _screenPass.setBlendMode((_blendMode == BlendMode.NORMAL && _requiresBlending) ? BlendMode.LAYER : _blendMode);
                _screenPass.forceSeparateMVP = false;
            }
        }

        private function initCasterLightPass():void
        {

            if (_casterLightPass == null)
                _casterLightPass = new TriangleMethodPass(MaterialPassMode.LIGHTING);

            _casterLightPass.lightPicker = new StaticLightPicker([_shadowMethod.castingLight]);
            _casterLightPass.shadowMethod = _shadowMethod;
            _casterLightPass.diffuseMethod = _diffuseMethod;
            _casterLightPass.ambientMethod = _ambientMethod;
            _casterLightPass.normalMethod = _normalMethod;
            _casterLightPass.specularMethod = _specularMethod;
        }

        private function removeCasterLightPass():void
        {
            _casterLightPass.dispose();
            removeScreenPass(_casterLightPass);
            _casterLightPass = null;
        }

        private function initNonCasterLightPasses():void
        {
            removeNonCasterLightPasses();
            var pass:TriangleMethodPass;
            var numDirLights:Number = _lightPicker.numDirectionalLights;
            var numPointLights:Number = _lightPicker.numPointLights;
            var numLightProbes:Number = _lightPicker.numLightProbes;
            var dirLightOffset:Number = 0;
            var pointLightOffset:Number = 0;
            var probeOffset:Number = 0;

            if (!_casterLightPass) {
                numDirLights += _lightPicker.numCastingDirectionalLights;
                numPointLights += _lightPicker.numCastingPointLights;
            }

            _nonCasterLightPasses = new Vector.<TriangleMethodPass>();

            while (dirLightOffset < numDirLights || pointLightOffset < numPointLights || probeOffset < numLightProbes) {
                pass = new TriangleMethodPass(MaterialPassMode.LIGHTING);
                pass.includeCasters = _shadowMethod == null;
                pass.directionalLightsOffset = dirLightOffset;
                pass.pointLightsOffset = pointLightOffset;
                pass.lightProbesOffset = probeOffset;
                pass.lightPicker = _lightPicker;
                pass.diffuseMethod = _diffuseMethod;
                pass.ambientMethod = _ambientMethod;
                pass.normalMethod = _normalMethod;
                pass.specularMethod = _specularMethod;
                _nonCasterLightPasses.push(pass);

                dirLightOffset += pass.numDirectionalLights;
                pointLightOffset += pass.numPointLights;
                probeOffset += pass.numLightProbes;
            }
        }

        private function removeNonCasterLightPasses():void
        {
            if (!_nonCasterLightPasses)
                return;

            for (var i:Number = 0; i < _nonCasterLightPasses.length; ++i)
                removeScreenPass(_nonCasterLightPasses[i]);

            _nonCasterLightPasses = null;
        }

        private function removeEffectPass():void
        {
            if (_screenPass.ambientMethod != _ambientMethod)
                _screenPass.ambientMethod.dispose();

            if (_screenPass.diffuseMethod != _diffuseMethod)
                _screenPass.diffuseMethod.dispose();

            if (_screenPass.specularMethod != _specularMethod)
                _screenPass.specularMethod.dispose();

            if (_screenPass.normalMethod != _normalMethod)
                _screenPass.normalMethod.dispose();

            removeScreenPass(_screenPass);
            _screenPass = null;
        }

        private function initEffectPass():void
        {
            if (_screenPass == null)
                _screenPass = new TriangleMethodPass();

            if (_materialMode == TriangleMaterialMode.SINGLE_PASS) {
                _screenPass.ambientMethod = _ambientMethod;
                _screenPass.diffuseMethod = _diffuseMethod;
                _screenPass.specularMethod = _specularMethod;
                _screenPass.normalMethod = _normalMethod;
                _screenPass.shadowMethod = _shadowMethod;
            } else if (_materialMode == TriangleMaterialMode.MULTI_PASS) {
                if (numLights == 0) {
                    _screenPass.ambientMethod = _ambientMethod;
                } else {
                    _screenPass.ambientMethod = null;
                }

                _screenPass.preserveAlpha = false;
                _screenPass.normalMethod = _normalMethod;
            }
        }

        /**
         * The maximum total Number of lights provided by the light picker.
         */
        private function get numLights():Number
        {
            return _lightPicker ? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights + _lightPicker.numCastingDirectionalLights + _lightPicker.numCastingPointLights : 0;
        }

        /**
         * The amount of lights that don't cast shadows.
         */
        private function get numNonCasters():Number
        {
            return _lightPicker ? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights : 0;
        }
    }
}
