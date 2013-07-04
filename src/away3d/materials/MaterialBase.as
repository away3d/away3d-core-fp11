package away3d.materials
{
	import away3d.animators.IAnimationSet;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.traverse.EntityCollector;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.passes.DepthMapPass;
	import away3d.materials.passes.DistanceMapPass;
	import away3d.materials.passes.MaterialPassBase;
	
	import flash.display.BlendMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	
	use namespace arcane;
	
	/**
	 * MaterialBase forms an abstract base class for any material.
	 * A material consists of several passes, each of which constitutes at least one render call. Several passes could
	 * be used for special effects (render lighting for many lights in several passes, render an outline in a separate
	 * pass) or to provide additional render-to-texture passes (rendering diffuse light to texture for texture-space
	 * subsurface scattering, or rendering a depth map for specialized self-shadowing).
	 *
	 * Away3D provides default materials trough SinglePassMaterialBase and MultiPassMaterialBase, which use modular
	 * methods to build the shader code. MaterialBase can be extended to build specific and high-performant custom
	 * shaders, or entire new material frameworks.
	 */
	public class MaterialBase extends NamedAssetBase implements IAsset
	{
		/**
		 * A counter used to assign unique ids per material, which is used to sort per material while rendering.
		 * This reduces state changes.
		 */
		private static var MATERIAL_ID_COUNT:uint = 0;

		/**
		 * An object to contain any extra data.
		 */
		public var extra:Object;

		/**
		 * A value that can be used by materials that only work with a given type of renderer. The renderer can test the
		 * classification to choose which render path to use. For example, a deferred material could set this value so
		 * that the deferred renderer knows not to take the forward rendering path.
		 *
		 * @private
		 */
		arcane var _classification:String;

		/**
		 * An id for this material used to sort the renderables by material, which reduces render state changes across
		 * materials using the same Program3D.
		 *
		 * @private
		 */
		arcane var _uniqueId:uint;

		/**
		 * An id for this material used to sort the renderables by shader program, which reduces Program3D state changes.
		 *
		 * @private
		 */
		arcane var _renderOrderId:int;

		/**
		 * The same as _renderOrderId, but applied to the depth shader passes.
		 *
		 * @private
		 */
		arcane var _depthPassId:int;

		private var _bothSides:Boolean;
		private var _animationSet:IAnimationSet;

		/**
		 * A list of material owners, renderables or custom Entities.
		 */
		private var _owners:Vector.<IMaterialOwner>;
		
		private var _alphaPremultiplied:Boolean;
		
		private var _blendMode:String = BlendMode.NORMAL;
		
		protected var _numPasses:uint;
		protected var _passes:Vector.<MaterialPassBase>;
		
		protected var _mipmap:Boolean = true;
		protected var _smooth:Boolean = true;
		protected var _repeat:Boolean;
		
		protected var _depthPass:DepthMapPass;
		protected var _distancePass:DistanceMapPass;
		
		protected var _lightPicker:LightPickerBase;
		private var _distanceBasedDepthRender:Boolean;
		private var _depthCompareMode:String = Context3DCompareMode.LESS_EQUAL;
		
		/**
		 * Creates a new MaterialBase object.
		 */
		public function MaterialBase()
		{
			_owners = new Vector.<IMaterialOwner>();
			_passes = new Vector.<MaterialPassBase>();
			_depthPass = new DepthMapPass();
			_distancePass = new DistanceMapPass();
			_depthPass.addEventListener(Event.CHANGE, onDepthPassChange);
			_distancePass.addEventListener(Event.CHANGE, onDistancePassChange);
			
			// Default to considering pre-multiplied textures while blending
			alphaPremultiplied = true;
			
			_uniqueId = MATERIAL_ID_COUNT++;
		}

		/**
		 * @inheritDoc
		 */
		public function get assetType():String
		{
			return AssetType.MATERIAL;
		}

		/**
		 * The light picker used by the material to provide lights to the material if it supports lighting.
		 *
		 * @see away3d.materials.lightpickers.LightPickerBase
		 * @see away3d.materials.lightpickers.StaticLightPicker
		 */
		public function get lightPicker():LightPickerBase
		{
			return _lightPicker;
		}
		
		public function set lightPicker(value:LightPickerBase):void
		{
			if (value != _lightPicker) {
				_lightPicker = value;
				var len:uint = _passes.length;
				for (var i:uint = 0; i < len; ++i)
					_passes[i].lightPicker = _lightPicker;
			}
		}
		
		/**
		 * Indicates whether or not any used textures should use mipmapping. Defaults to true.
		 */
		public function get mipmap():Boolean
		{
			return _mipmap;
		}
		
		public function set mipmap(value:Boolean):void
		{
			_mipmap = value;
			for (var i:int = 0; i < _numPasses; ++i)
				_passes[i].mipmap = value;
		}
		
		/**
		 * Indicates whether or not any used textures should use smoothing.
		 */
		public function get smooth():Boolean
		{
			return _smooth;
		}
		
		public function set smooth(value:Boolean):void
		{
			_smooth = value;
			for (var i:int = 0; i < _numPasses; ++i)
				_passes[i].smooth = value;
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
			_depthCompareMode = value;
		}
		
		/**
		 * Indicates whether or not any used textures should be tiled. If set to false, texture samples are clamped to
		 * the texture's borders when the uv coordinates are outside the [0, 1] interval.
		 */
		public function get repeat():Boolean
		{
			return _repeat;
		}
		
		public function set repeat(value:Boolean):void
		{
			_repeat = value;
			for (var i:int = 0; i < _numPasses; ++i)
				_passes[i].repeat = value;
		}
		
		/**
		 * Cleans up resources owned by the material, including passes. Textures are not owned by the material since they
		 * could be used by other materials and will not be disposed.
		 */
		public function dispose():void
		{
			var i:uint;
			
			for (i = 0; i < _numPasses; ++i)
				_passes[i].dispose();
			
			_depthPass.dispose();
			_distancePass.dispose();
			_depthPass.removeEventListener(Event.CHANGE, onDepthPassChange);
			_distancePass.removeEventListener(Event.CHANGE, onDistancePassChange);
		}
		
		/**
		 * Defines whether or not the material should cull triangles facing away from the camera.
		 */
		public function get bothSides():Boolean
		{
			return _bothSides;
		}
		
		public function set bothSides(value:Boolean):void
		{
			_bothSides = value;
			
			for (var i:int = 0; i < _numPasses; ++i)
				_passes[i].bothSides = value;
			
			_depthPass.bothSides = value;
			_distancePass.bothSides = value;
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
		public function get blendMode():String
		{
			return _blendMode;
		}
		
		public function set blendMode(value:String):void
		{
			_blendMode = value;
		}
		
		/**
		 * Indicates whether visible textures (or other pixels) used by this material have
		 * already been premultiplied. Toggle this if you are seeing black halos around your
		 * blended alpha edges.
		 */
		public function get alphaPremultiplied():Boolean
		{
			return _alphaPremultiplied;
		}
		
		public function set alphaPremultiplied(value:Boolean):void
		{
			_alphaPremultiplied = value;
			
			for (var i:int = 0; i < _numPasses; ++i)
				_passes[i].alphaPremultiplied = value;
		}
		
		/**
		 * Indicates whether or not the material requires alpha blending during rendering.
		 */
		public function get requiresBlending():Boolean
		{
			return _blendMode != BlendMode.NORMAL;
		}

		/**
		 * An id for this material used to sort the renderables by material, which reduces render state changes across
		 * materials using the same Program3D.
		 */
		public function get uniqueId():uint
		{
			return _uniqueId;
		}
		
		/**
		 * The amount of passes used by the material.
		 *
		 * @private
		 */
		arcane function get numPasses():uint
		{
			return _numPasses;
		}

		/**
		 * Indicates that the depth pass uses transparency testing to discard pixels.
		 *
		 * @private
		 */
		arcane function hasDepthAlphaThreshold():Boolean
		{
			return _depthPass.alphaThreshold > 0;
		}

		/**
		 * Sets the render state for the depth pass that is independent of the rendered object. Used when rendering
		 * depth or distances (fe: shadow maps, depth pre-pass).
		 *
		 * @param stage3DProxy The Stage3DProxy used for rendering.
		 * @param camera The camera from which the scene is viewed.
		 * @param distanceBased Whether or not the depth pass or distance pass should be activated. The distance pass
		 * is required for shadow cube maps.
		 *
		 * @private
		 */
		arcane function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Boolean = false):void
		{
			_distanceBasedDepthRender = distanceBased;

			if (distanceBased)
				_distancePass.activate(stage3DProxy, camera);
			else
				_depthPass.activate(stage3DProxy, camera);
		}

		/**
		 * Clears the render state for the depth pass.
		 *
		 * @param stage3DProxy The Stage3DProxy used for rendering.
		 *
		 * @private
		 */
		arcane function deactivateForDepth(stage3DProxy:Stage3DProxy):void
		{
			if (_distanceBasedDepthRender)
				_distancePass.deactivate(stage3DProxy);
			else
				_depthPass.deactivate(stage3DProxy);
		}

		/**
		 * Renders a renderable using the depth pass.
		 *
		 * @param renderable The IRenderable instance that needs to be rendered.
		 * @param stage3DProxy The Stage3DProxy used for rendering.
		 * @param camera The camera from which the scene is viewed.
		 * @param viewProjection The view-projection matrix used to project to the screen. This is not the same as
		 * camera.viewProjection as it includes the scaling factors when rendering to textures.
		 *
		 * @private
		 */
		arcane function renderDepth(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			if (_distanceBasedDepthRender) {
				if (renderable.animator)
					_distancePass.updateAnimationState(renderable, stage3DProxy, camera);
				_distancePass.render(renderable, stage3DProxy, camera, viewProjection);
			} else {
				if (renderable.animator)
					_depthPass.updateAnimationState(renderable, stage3DProxy, camera);
				_depthPass.render(renderable, stage3DProxy, camera, viewProjection);
			}
		}

		/**
		 * Indicates whether or not the pass with the given index renders to texture or not.
		 * @param index The index of the pass.
		 * @return True if the pass renders to texture, false otherwise.
		 *
		 * @private
		 */
		arcane function passRendersToTexture(index:uint):Boolean
		{
			return _passes[index].renderToTexture;
		}
		
		/**
		 * Sets the render state for a pass that is independent of the rendered object. This needs to be called before
		 * calling renderPass. Before activating a pass, the previously used pass needs to be deactivated.
		 * @param index The index of the pass to activate.
		 * @param stage3DProxy The Stage3DProxy object which is currently used for rendering.
		 * @param camera The camera from which the scene is viewed.
		 * @private
		 */
		arcane function activatePass(index:uint, stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			_passes[index].activate(stage3DProxy, camera);
		}


		/**
		 * Clears the render state for a pass. This needs to be called before activating another pass.
		 * @param index The index of the pass to deactivate.
		 * @param stage3DProxy The Stage3DProxy used for rendering
		 *
		 * @private
		 */
		arcane function deactivatePass(index:uint, stage3DProxy:Stage3DProxy):void
		{
			_passes[index].deactivate(stage3DProxy);
		}

		/**
		 * Renders the current pass. Before calling renderPass, activatePass needs to be called with the same index.
		 * @param index The index of the pass used to render the renderable.
		 * @param renderable The IRenderable object to draw.
		 * @param stage3DProxy The Stage3DProxy object used for rendering.
		 * @param entityCollector The EntityCollector object that contains the visible scene data.
		 * @param viewProjection The view-projection matrix used to project to the screen. This is not the same as
		 * camera.viewProjection as it includes the scaling factors when rendering to textures.
		 */
		arcane function renderPass(index:uint, renderable:IRenderable, stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, viewProjection:Matrix3D):void
		{
			if (_lightPicker)
				_lightPicker.collectLights(renderable, entityCollector);
			
			var pass:MaterialPassBase = _passes[index];
			
			if (renderable.animator)
				pass.updateAnimationState(renderable, stage3DProxy, entityCollector.camera);
			
			pass.render(renderable, stage3DProxy, entityCollector.camera, viewProjection);
		}
		
		//
		// MATERIAL MANAGEMENT
		//
		/**
		 * Mark an IMaterialOwner as owner of this material.
		 * Assures we're not using the same material across renderables with different animations, since the
		 * Program3Ds depend on animation. This method needs to be called when a material is assigned.
		 *
		 * @param owner The IMaterialOwner that had this material assigned
		 *
		 * @private
		 */
		arcane function addOwner(owner:IMaterialOwner):void
		{
			_owners.push(owner);
			
			if (owner.animator) {
				if (_animationSet && owner.animator.animationSet != _animationSet)
					throw new Error("A Material instance cannot be shared across renderables with different animator libraries");
				else {
					if (_animationSet != owner.animator.animationSet) {
						_animationSet = owner.animator.animationSet;
						for (var i:int = 0; i < _numPasses; ++i)
							_passes[i].animationSet = _animationSet;
						_depthPass.animationSet = _animationSet;
						_distancePass.animationSet = _animationSet;
						invalidatePasses(null);
					}
				}
			}
		}
		
		/**
		 * Removes an IMaterialOwner as owner.
		 * @param owner
		 * @private
		 */
		arcane function removeOwner(owner:IMaterialOwner):void
		{
			_owners.splice(_owners.indexOf(owner), 1);
			if (_owners.length == 0) {
				_animationSet = null;
				for (var i:int = 0; i < _numPasses; ++i)
					_passes[i].animationSet = _animationSet;
				_depthPass.animationSet = _animationSet;
				_distancePass.animationSet = _animationSet;
				invalidatePasses(null);
			}
		}
		
		/**
		 * A list of the IMaterialOwners that use this material
		 *
		 * @private
		 */
		arcane function get owners():Vector.<IMaterialOwner>
		{
			return _owners;
		}
		
		/**
		 * Performs any processing that needs to occur before any of its passes are used.
		 *
		 * @private
		 */
		arcane function updateMaterial(context:Context3D):void
		{
		
		}
		
		/**
		 * Deactivates the last pass of the material.
		 *
		 * @private
		 */
		arcane function deactivate(stage3DProxy:Stage3DProxy):void
		{
			_passes[_numPasses - 1].deactivate(stage3DProxy);
		}
		
		/**
		 * Marks the shader programs for all passes as invalid, so they will be recompiled before the next use.
		 * @param triggerPass The pass triggering the invalidation, if any. This is passed to prevent invalidating the
		 * triggering pass, which would result in an infinite loop.
		 *
		 * @private
		 */
		arcane function invalidatePasses(triggerPass:MaterialPassBase):void
		{
			var owner:IMaterialOwner;
			
			_depthPass.invalidateShaderProgram();
			_distancePass.invalidateShaderProgram();

			// test if the depth and distance passes support animating the animation set in the vertex shader
			// if any object using this material fails to support accelerated animations for any of the passes,
			// we should do everything on cpu (otherwise we have the cost of both gpu + cpu animations)
			if (_animationSet) {
				_animationSet.resetGPUCompatibility();
				for each (owner in _owners) {
					if (owner.animator) {
						owner.animator.testGPUCompatibility(_depthPass);
						owner.animator.testGPUCompatibility(_distancePass);
					}
				}
			}
			
			for (var i:int = 0; i < _numPasses; ++i) {
				// only invalidate the pass if it wasn't the triggering pass
				if (_passes[i] != triggerPass)
					_passes[i].invalidateShaderProgram(false);

				// test if animation will be able to run on gpu BEFORE compiling materials
				// test if the pass supports animating the animation set in the vertex shader
				// if any object using this material fails to support accelerated animations for any of the passes,
				// we should do everything on cpu (otherwise we have the cost of both gpu + cpu animations)
				if (_animationSet) {
					for each (owner in _owners) {
						if (owner.animator)
							owner.animator.testGPUCompatibility(_passes[i]);
					}
				}
			}
		}

		/**
		 * Removes a pass from the material.
		 * @param pass The pass to be removed.
		 */
		protected function removePass(pass:MaterialPassBase):void
		{
			_passes.splice(_passes.indexOf(pass), 1);
			--_numPasses;
		}
		
		/**
		 * Removes all passes from the material
		 */
		protected function clearPasses():void
		{
			for (var i:int = 0; i < _numPasses; ++i)
				_passes[i].removeEventListener(Event.CHANGE, onPassChange);
			
			_passes.length = 0;
			_numPasses = 0;
		}
		
		/**
		 * Adds a pass to the material
		 * @param pass
		 */
		protected function addPass(pass:MaterialPassBase):void
		{
			_passes[_numPasses++] = pass;
			pass.animationSet = _animationSet;
			pass.alphaPremultiplied = _alphaPremultiplied;
			pass.mipmap = _mipmap;
			pass.smooth = _smooth;
			pass.repeat = _repeat;
			pass.lightPicker = _lightPicker;
			pass.bothSides = _bothSides;
			pass.addEventListener(Event.CHANGE, onPassChange);
			invalidatePasses(null);
		}

		/**
		 * Listener for when a pass's shader code changes. It recalculates the render order id.
		 */
		private function onPassChange(event:Event):void
		{
			var mult:Number = 1;
			var ids:Vector.<int>;
			var len:int;
			
			_renderOrderId = 0;
			
			for (var i:int = 0; i < _numPasses; ++i) {
				ids = _passes[i]._program3Dids;
				len = ids.length;
				for (var j:int = 0; j < len; ++j) {
					if (ids[j] != -1) {
						_renderOrderId += mult*ids[j];
						j = len;
					}
				}
				mult *= 1000;
			}
		}

		/**
		 * Listener for when the distance pass's shader code changes. It recalculates the depth pass id.
		 */
		private function onDistancePassChange(event:Event):void
		{
			var ids:Vector.<int> = _distancePass._program3Dids;
			var len:uint = ids.length;
			
			_depthPassId = 0;
			
			for (var j:int = 0; j < len; ++j) {
				if (ids[j] != -1) {
					_depthPassId += ids[j];
					j = len;
				}
			}
		}

		/**
		 * Listener for when the depth pass's shader code changes. It recalculates the depth pass id.
		 */
		private function onDepthPassChange(event:Event):void
		{
			var ids:Vector.<int> = _depthPass._program3Dids;
			var len:uint = ids.length;
			
			_depthPassId = 0;
			
			for (var j:int = 0; j < len; ++j) {
				if (ids[j] != -1) {
					_depthPassId += ids[j];
					j = len;
				}
			}
		}
	}
}
