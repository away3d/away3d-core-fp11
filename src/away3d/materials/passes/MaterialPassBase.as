package away3d.materials.passes {
    import away3d.arcane;
    import away3d.core.library.NamedAssetBase;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.lightpickers.LightPickerBase;

    import flash.display.BlendMode;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DCompareMode;
    import flash.events.Event;
    import flash.geom.Matrix3D;

    use namespace arcane;

    /**
     * MaterialPassBase provides an abstract base class for material shader passes. A material pass constitutes at least
     * a render call per required renderable.
     */
    public class MaterialPassBase extends NamedAssetBase implements IMaterialPass {
        private var _materialPassData:Vector.<MaterialPassData> = new Vector.<MaterialPassData>();
        private var _maxLights:Number = 3;
        private var _preserveAlpha:Boolean = true;
        private var _includeCasters:Boolean = true;
        private var _forceSeparateMVP:Boolean = false;

        private var _directionalLightsOffset:Number = 0;
        private var _pointLightsOffset:Number = 0;
        private var _lightProbesOffset:Number = 0;

        protected var _numPointLights:int = 0;
        protected var _numDirectionalLights:int = 0;
        protected var _numLightProbes:int = 0;
        protected var _numLights:int = 0;

		public var useDeferredDiffuseLighting:Boolean;
		public var useDeferredSpecularLighting:Boolean;
		public var useDeferredColoredSpecular:Boolean;

        private var _passMode:Number;

        private var _depthCompareMode:String = Context3DCompareMode.LESS_EQUAL;

        private var _blendFactorSource:String = Context3DBlendFactor.ONE;
        private var _blendFactorDest:String = Context3DBlendFactor.ZERO;

        protected var _enableBlending:Boolean = false;

        protected var _lightPicker:LightPickerBase;

        private var _writeDepth:Boolean = true;


        /**
         * Indicates whether the output alpha value should remain unchanged compared to the material's original alpha.
         */
        public function get preserveAlpha():Boolean
        {
            return _preserveAlpha;
        }

        public function set preserveAlpha(value:Boolean)
        {
            if (_preserveAlpha == value)
                return;

            _preserveAlpha = value;

            invalidatePass();
        }

        /**
         * Indicates whether or not shadow casting lights need to be included.
         */
        public function get includeCasters():Boolean
        {
            return _includeCasters;
        }

        public function set includeCasters(value:Boolean)
        {
            if (_includeCasters == value)
                return;

            _includeCasters = value;

            invalidatePass();
        }

        /**
         * Indicates whether the screen projection should be calculated by forcing a separate scene matrix and
         * view-projection matrix. This is used to prevent rounding errors when using multiple passes with different
         * projection code.
         */
        public function get forceSeparateMVP():Boolean
        {
            return _forceSeparateMVP;
        }

        public function set forceSeparateMVP(value:Boolean)
        {
            if (_forceSeparateMVP == value)
                return;

            _forceSeparateMVP = value;

            invalidatePass();
        }

        /**
         * Indicates the offset in the light picker's directional light vector for which to start including lights.
         * This needs to be set before the light picker is assigned.
         */
        public function get directionalLightsOffset():Number
        {
            return _directionalLightsOffset;
        }

        public function set directionalLightsOffset(value:Number)
        {
            _directionalLightsOffset = value;
        }

        /**
         * Indicates the offset in the light picker's point light vector for which to start including lights.
         * This needs to be set before the light picker is assigned.
         */
        public function get pointLightsOffset():Number
        {
            return _pointLightsOffset;
        }

        public function set pointLightsOffset(value:Number)
        {
            _pointLightsOffset = value;
        }

        /**
         * Indicates the offset in the light picker's light probes vector for which to start including lights.
         * This needs to be set before the light picker is assigned.
         */
        public function get lightProbesOffset():Number
        {
            return _lightProbesOffset;
        }

        public function set lightProbesOffset(value:Number)
        {
            _lightProbesOffset = value;
        }

        /**
         *
         */
        public function get passMode():Number
        {
            return _passMode;
        }

        public function set passMode(value:Number)
        {
            _passMode = value;

            invalidatePass();
        }

        /**
         * Creates a new MaterialPassBase object.
         */
        public function MaterialPassBase(passMode:Number = 0x03)
        {
            super();

            _passMode = passMode;
        }

        /**
         * Factory method to create a concrete shader object for this pass.
         *
         * @param profile The compatibility profile used by the renderer.
         */
        public function createShaderObject(profile:String):ShaderObjectBase
        {
            return new ShaderObjectBase(profile);
        }

        /**
         * Indicate whether this pass should write to the depth buffer or not. Ignored when blending is enabled.
         */
        public function get writeDepth():Boolean
        {
            return _writeDepth;
        }

        public function set writeDepth(value:Boolean)
        {
            _writeDepth = value;
        }

        /**
         * The depth compare mode used to render the renderables using this material.
         */
        public function get depthCompareMode():String
        {
            return _depthCompareMode;
        }

        public function set depthCompareMode(value:String)
        {
            _depthCompareMode = value;
        }

        /**
         * Cleans up any resources used by the current object.
         */
        override public function dispose():void
        {
            if (_lightPicker)
                _lightPicker.removeEventListener(Event.CHANGE, onLightsChange);

            while (_materialPassData.length)
                _materialPassData[0].dispose();

            _materialPassData = null;
        }

        /**
         * Renders an object to the current render target.
         *
         * @private
         */
        public function render(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
        {
            setRenderState(pass, renderable, stage, camera, viewProjection);
        }

        /**
         *
         *
         * @param renderable
         * @param stage
         * @param camera
         */
        public function setRenderState(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
        {
            pass.shaderObject.setRenderState(renderable, stage, camera, viewProjection);
        }

        /**
         * The blend mode to use when drawing this renderable. The following blend modes are supported:
         * <ul>
         * <li>BlendMode.NORMAL: No blending, unless the material inherently needs it</li>
         * <li>BlendMode.LAYER: Force blending. This will draw the object the same as NORMAL, but without writing depth writes.</li>
         * <li>BlendMode.MULTIPLY</li>
         * <li>BlendMode.ADD</li>
         * <li>BlendMode.ALPHA</li>
         * </ul>
         */
        public function setBlendMode(value:String):void
        {
            switch (value) {

                case BlendMode.NORMAL:

                    _blendFactorSource = Context3DBlendFactor.ONE;
                    _blendFactorDest = Context3DBlendFactor.ZERO;
                    _enableBlending = false;

                    break;

                case BlendMode.LAYER:

                    _blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
                    _blendFactorDest = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
                    _enableBlending = true;

                    break;

                case BlendMode.MULTIPLY:

                    _blendFactorSource = Context3DBlendFactor.ZERO;
                    _blendFactorDest = Context3DBlendFactor.SOURCE_COLOR;
                    _enableBlending = true;

                    break;

                case BlendMode.ADD:

                    _blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
                    _blendFactorDest = Context3DBlendFactor.ONE;
                    _enableBlending = true;

                    break;

                case BlendMode.ALPHA:

                    _blendFactorSource = Context3DBlendFactor.ZERO;
                    _blendFactorDest = Context3DBlendFactor.SOURCE_ALPHA;
                    _enableBlending = true;

                    break;

                case BlendMode.SCREEN:
                    _blendFactorSource = Context3DBlendFactor.ONE;
                    _blendFactorDest = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
                    _enableBlending = true;
                    break;

                default:

                    throw new ArgumentError("Unsupported blend mode!");

            }
        }

        /**
         * Sets the render state for the pass that is independent of the rendered object. This needs to be called before
         * calling renderPass. Before activating a pass, the previously used pass needs to be deactivated.
         * @param stage The Stage object which is currently used for rendering.
         * @param camera The camera from which the scene is viewed.
         * @private
         */
        public function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
        {
            var context:Context3D = stage.context3D;
            context.setDepthTest(( _writeDepth && !_enableBlending ), _depthCompareMode);

            if (_enableBlending)
                context.setBlendFactors(_blendFactorSource, _blendFactorDest);

            stage.activateMaterialPass(pass, camera);
        }

        /**
         * Clears the render state for the pass. This needs to be called before activating another pass.
         * @param pass MaterialPassData
         * @param stage The Stage used for rendering
         *
         * @private
         */
        public function deactivate(pass:MaterialPassData, stage:Stage3DProxy):void
        {
            stage.deactivateMaterialPass(pass);
            stage.context3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL); // TODO : imeplement
        }

        /**
         * Marks the shader program as invalid, so it will be recompiled before the next render.
         */
        public function invalidatePass():void
        {
            var len:Number = _materialPassData.length;
            for (var i:Number = 0; i < len; i++)
                _materialPassData[i].invalidate();

            dispatchEvent(new Event(Event.CHANGE));
        }

        /**
         * The light picker used by the material to provide lights to the material if it supports lighting.
         */
        public function get lightPicker():LightPickerBase
        {
            return _lightPicker;
        }

        public function set lightPicker(value:LightPickerBase):void
        {
            if (_lightPicker)
                _lightPicker.removeEventListener(Event.CHANGE, onLightsChange);

            _lightPicker = value;

            if (_lightPicker)
                _lightPicker.addEventListener(Event.CHANGE, onLightsChange);

            updateLights();
        }

        /**
         * Called when the light picker's configuration changes.
         */
        private function onLightsChange(event:Event):void
        {
            updateLights();
        }

        /**
         * Implemented by subclasses if the pass uses lights to update the shader.
         */
        public function updateLights():void
        {
            var numDirectionalLightsOld:Number = _numDirectionalLights;
            var numPointLightsOld:Number = _numPointLights;
            var numLightProbesOld:Number = _numLightProbes;

            if (_lightPicker && Boolean(_passMode & MaterialPassMode.LIGHTING)) {
                _numDirectionalLights = calculateNumDirectionalLights(_lightPicker.numDirectionalLights);
                _numPointLights = calculateNumPointLights(_lightPicker.numPointLights);
                _numLightProbes = calculateNumProbes(_lightPicker.numLightProbes);

                if (_includeCasters) {
                    _numDirectionalLights += _lightPicker.numCastingDirectionalLights;
                    _numPointLights += _lightPicker.numCastingPointLights;
                }

            } else {
                _numDirectionalLights = 0;
                _numPointLights = 0;
                _numLightProbes = 0;
            }

            _numLights = _numDirectionalLights + _numPointLights;

            if (numDirectionalLightsOld != _numDirectionalLights || numPointLightsOld != _numPointLights || numLightProbesOld != _numLightProbes)
                invalidatePass();
        }

        public function includeDependencies(shaderObject:ShaderObjectBase):void
        {
            if (_forceSeparateMVP)
                shaderObject.globalPosDependencies++;

            shaderObject.outputsNormals = outputsNormals(shaderObject);
            shaderObject.outputsTangentNormals = shaderObject.outputsNormals && outputsTangentNormals(shaderObject);
            shaderObject.usesTangentSpace = shaderObject.outputsTangentNormals && usesTangentSpace(shaderObject);

            if (!shaderObject.usesTangentSpace)
                shaderObject.addWorldSpaceDependencies(Boolean(_passMode & MaterialPassMode.EFFECTS));
        }


        public function initConstantData(shaderObject:ShaderObjectBase):void
        {

        }

        public function getPreLightingVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        public function getPreLightingFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        public function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        public function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        public function getNormalVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        public function getNormalFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        /**
         * The amount of point lights that need to be supported.
         */
        public function get numPointLights():int
        {
            return _numPointLights;
        }

        /**
         * The amount of directional lights that need to be supported.
         */
        public function get numDirectionalLights():int
        {
            return _numDirectionalLights;
        }

        /**
         * The amount of light probes that need to be supported.
         */
        public function get numLightProbes():int
        {
            return _numLightProbes;
        }

        /**
         * Indicates whether or not normals are calculated at all.
         */
        protected function outputsNormals(shaderObject:ShaderObjectBase):Boolean
        {
            return false;
        }

        /**
         * Indicates whether or not normals are calculated in tangent space.
         */
        public function outputsTangentNormals(shaderObject:ShaderObjectBase):Boolean
        {
            return false;
        }

        /**
         * Indicates whether or not normals are allowed in tangent space. This is only the case if no object-space
         * dependencies exist.
         */
        public function usesTangentSpace(shaderObject:ShaderObjectBase):Boolean
        {
            return false;
        }

        /**
         * Calculates the amount of directional lights this material will support.
         * @param numDirectionalLights The maximum amount of directional lights to support.
         * @return The amount of directional lights this material will support, bounded by the amount necessary.
         */
        private function calculateNumDirectionalLights(numDirectionalLights:Number):Number
        {
            return Math.min(numDirectionalLights - _directionalLightsOffset, _maxLights);
        }

        /**
         * Calculates the amount of point lights this material will support.
         * @param numPointLights The maximum amount of point lights to support.
         * @return The amount of point lights this material will support, bounded by the amount necessary.
         */
        private function calculateNumPointLights(numPointLights:Number):Number
        {
            var numFree:Number = _maxLights - _numDirectionalLights;
            return Math.min(numPointLights - _pointLightsOffset, numFree);
        }

        /**
         * Calculates the amount of light probes this material will support.
         * @param numLightProbes The maximum amount of light probes to support.
         * @return The amount of light probes this material will support, bounded by the amount necessary.
         */
        private function calculateNumProbes(numLightProbes:Number):Number
        {
            var numChannels:Number = 0;
            // 4 channels available
            return Math.min(numLightProbes - _lightProbesOffset, (4 / numChannels) | 0);
        }

        arcane function addMaterialPassData(materialPassData:MaterialPassData):MaterialPassData
        {
            _materialPassData.push(materialPassData);

            return materialPassData;
        }

        arcane function removeMaterialPassData(materialPassData:MaterialPassData):MaterialPassData
        {
            _materialPassData.splice(_materialPassData.indexOf(materialPassData), 1);

            return materialPassData;
        }
    }
}
