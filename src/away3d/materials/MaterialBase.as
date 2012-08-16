package away3d.materials
{
	import away3d.animators.IAnimationSet;
	import away3d.animators.IAnimator;
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
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.events.Event;

	use namespace arcane;

	/**
	 * MaterialBase forms an abstract base class for any material.
	 *
	 * Vertex stream index 0 is reserved for vertex positions.
	 * Vertex shader constants index 0-3 are reserved for projections, constant 4 for viewport positioning
	 */
	public class MaterialBase extends NamedAssetBase implements IAsset
	{
		private static var MATERIAL_ID_COUNT : uint = 0;
		/**
		 * An object to contain any extra data
		 */
		public var extra : Object;

		// can be used by other renderers to determine how to render this particular material
		// in practice, this can be checked by a custom EntityCollector
		arcane var _classification : String;

		// this value is usually derived from other settings
		arcane var _uniqueId : uint;

		arcane var _renderOrderId : int;
		arcane var _name : String = "material";

		private var _bothSides : Boolean;
		private var _animationSet : IAnimationSet;

		private var _owners : Vector.<IMaterialOwner>;

		private var _alphaPremultiplied : Boolean;
		private var _requiresBlending : Boolean;

		private var _blendMode : String = BlendMode.NORMAL;
		private var _srcBlend : String = Context3DBlendFactor.SOURCE_ALPHA;
		private var _destBlend : String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;

		protected var _numPasses : uint;
		protected var _passes : Vector.<MaterialPassBase>;

		protected var _mipmap : Boolean = true;
		protected var _smooth : Boolean = true;
		protected var _repeat : Boolean;
		protected var _depthCompareMode:String = Context3DCompareMode.LESS;

		protected var _depthPass : DepthMapPass;
		protected var _distancePass : DistanceMapPass;

		private var _lightPicker : LightPickerBase;
		private var _distanceBasedDepthRender : Boolean;

		/**
		 * Creates a new MaterialBase object.
		 */
		public function MaterialBase()
		{
			_owners = new Vector.<IMaterialOwner>();
			_passes = new Vector.<MaterialPassBase>();
			_depthPass = new DepthMapPass();
			_distancePass = new DistanceMapPass();
			
			// Default to considering pre-multiplied textures while blending
			alphaPremultiplied = true;

			_uniqueId = MATERIAL_ID_COUNT++;
		}

		public function get assetType() : String
		{
			return AssetType.MATERIAL;
		}

		public function get lightPicker() : LightPickerBase
		{
			return _lightPicker;
		}

		public function set lightPicker(value : LightPickerBase) : void
		{
			if (value != _lightPicker) {
				if (_lightPicker)
					_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
				
				_lightPicker = value;
	
				if (_lightPicker)
					_lightPicker.addEventListener(Event.CHANGE, onLightsChange);
				
				invalidatePasses(null);
			}
		}

		private function onLightsChange(event : Event) : void
		{
			var pass : MaterialPassBase;
			for (var i : uint = 0; i < _numPasses; ++i) {
				pass = _passes[i];
				pass.numPointLights = _lightPicker.numPointLights;
				pass.numDirectionalLights = _lightPicker.numDirectionalLights;
				pass.numLightProbes = _lightPicker.numLightProbes;
			}
		}

		/**
		 * Indicates whether or not any used textures should use mipmapping.
		 */
		public function get mipmap() : Boolean
		{
			return _mipmap;
		}

		public function set mipmap(value : Boolean) : void
		{
			_mipmap = value;
			for (var i : int = 0; i < _numPasses; ++i) _passes[i].mipmap = value;
		}

		/**
		 * Indicates whether or not any used textures should use smoothing.
		 */
		public function get smooth() : Boolean
		{
			return _smooth;
		}

		public function set smooth(value : Boolean) : void
		{
			_smooth = value;
			for (var i : int = 0; i < _numPasses; ++i) _passes[i].smooth = value;
		}
		
		public function get depthCompareMode() : String
		{
			return _passes[_numPasses-1].depthCompareMode;
		}
		
		public function set depthCompareMode(value : String) : void
		{
			_passes[_numPasses-1].depthCompareMode = value;
		}

		/**
		 * Indicates whether or not any used textures should be tiled.
		 */
		public function get repeat() : Boolean
		{
			return _repeat;
		}

		public function set repeat(value : Boolean) : void
		{
			_repeat = value;
			for (var i : int = 0; i < _numPasses; ++i) _passes[i].repeat = value;
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose() : void
		{
			var i : uint;

			for (i = 0; i < _numPasses; ++i) _passes[i].dispose();

			_depthPass.dispose();
			_distancePass.dispose();

			if (_lightPicker)
				_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
		}

		/**
		 * Defines whether or not the material should perform backface culling.
		 */
		public function get bothSides() : Boolean
		{
			return _bothSides;
		}

		public function set bothSides(value : Boolean) : void
		{
			_bothSides = value;

			for (var i : int = 0; i < _numPasses; ++i)
				_passes[i].bothSides = value;

			_depthPass.bothSides = value;
			_distancePass.bothSides = value;
		}

		/**
		 * The blend mode to use when drawing this renderable. The following blend modes are supported:
		 * <ul>
		 * <li>BlendMode.NORMAL</li>
		 * <li>BlendMode.MULTIPLY</li>
		 * <li>BlendMode.ADD</li>
		 * <li>BlendMode.ALPHA</li>
		 * </ul>
		 */
		public function get blendMode() : String
		{
			return _blendMode;
		}

		public function set blendMode(value : String) : void
		{
			_blendMode = value;

			updateBlendFactors();
		}
		
		
		/**
		 * Indicates whether visible textures (or other pixels) used by this material have
		 * already been premultiplied. Toggle this if you are seeing black halos around your
		 * blended alpha edges.
		*/
		public function get alphaPremultiplied() : Boolean
		{
			return _alphaPremultiplied;
		}
		public function set alphaPremultiplied(value : Boolean) : void
		{
			_alphaPremultiplied = value;

			for (var i : int = 0; i < _numPasses; ++i)
				_passes[i].alphaPremultiplied = value;
		}
		

		/**
		 * Indicates whether or not the material requires alpha blending during rendering.
		 */
		public function get requiresBlending() : Boolean
		{
			return _requiresBlending;
		}

		/**
		 * The unique id assigned to the material by the MaterialLibrary.
		 */
		public function get uniqueId() : uint
		{
			return _uniqueId;
		}

		public override function get name() : String
		{
			return _name;
		}

		public override function set name(value : String) : void
		{
			_name = value;
		}


		/**
		 * The amount of passes used by the material.
		 *
		 * @private
		 */
		arcane function get numPasses() : uint
		{
			return _numPasses;
		}

		arcane function activateForDepth(stage3DProxy : Stage3DProxy, camera : Camera3D, distanceBased : Boolean = false, textureRatioX : Number = 1, textureRatioY : Number = 1) : void
		{
			_distanceBasedDepthRender = distanceBased;

			if (distanceBased)
				_distancePass.activate(stage3DProxy, camera, textureRatioX, textureRatioY);
			else
				_depthPass.activate(stage3DProxy, camera, textureRatioX, textureRatioY);
		}

		arcane function deactivateForDepth(stage3DProxy : Stage3DProxy) : void
		{
			if (_distanceBasedDepthRender)
				_distancePass.deactivate(stage3DProxy);
			else
				_depthPass.deactivate(stage3DProxy);
		}

		arcane function renderDepth(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			if (_distanceBasedDepthRender) {
				if (renderable.animator)
					_distancePass.updateAnimationState(renderable, stage3DProxy);
				_distancePass.render(renderable, stage3DProxy, camera, _lightPicker);
			}
			else {
				if (renderable.animator)
					_depthPass.updateAnimationState(renderable, stage3DProxy);
				_depthPass.render(renderable, stage3DProxy, camera, _lightPicker);
			}
		}

		arcane function passRendersToTexture(index : uint) : Boolean
		{
			return _passes[index].renderToTexture;
		}

		/**
		 * Sets the render state for a pass that is independent of the rendered object.
		 * @param index The index of the pass to activate.
		 * @param context The Context3D object which is currently rendering.
		 * @param camera The camera from which the scene is viewed.
		 * @private
		 */
		arcane function activatePass(index : uint, stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			var pass : MaterialPassBase = _passes[index];
			var enableDepthWrite : Boolean = true;
			var context : Context3D = stage3DProxy._context3D;

			if (index == _numPasses-1) {
				if (requiresBlending) {
					enableDepthWrite = false;
					context.setBlendFactors(_srcBlend, _destBlend);
				}
			}

			context.setDepthTest(enableDepthWrite, pass.depthCompareMode);
			pass.activate(stage3DProxy, camera, textureRatioX, textureRatioY);
		}

		/**
		 * Clears the render state for a pass.
		 * @param index The index of the pass to deactivate.
		 * @param context The Context3D object that is currently rendering.
		 * @private
		 */
		arcane function deactivatePass(index : uint, stage3DProxy : Stage3DProxy) : void
		{
			_passes[index].deactivate(stage3DProxy);
		}

		/**
		 * Renders a renderable with a pass.
		 * @param index The pass to render with.
		 * @private
		 */
		arcane function renderPass(index : uint, renderable : IRenderable, stage3DProxy : Stage3DProxy, entityCollector : EntityCollector) : void
		{
			if (_lightPicker)
				_lightPicker.collectLights(renderable, entityCollector);

			var pass : MaterialPassBase = _passes[index];

			if (renderable.animator)
				pass.updateAnimationState(renderable, stage3DProxy);

			pass.render(renderable, stage3DProxy, entityCollector.camera, _lightPicker);
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
		arcane function addOwner(owner : IMaterialOwner) : void
		{
			_owners.push(owner);
			
			if (owner.animator) {
				if (_animationSet && owner.animator.animationSet != _animationSet) {
					throw new Error("A Material instance cannot be shared across renderables with different animator libraries");
				}
				else {
					_animationSet = owner.animator.animationSet;
					for (var i : int = 0; i < _numPasses; ++i)
						_passes[i].animationSet = _animationSet;
					_depthPass.animationSet = _animationSet;
					_distancePass.animationSet = _animationSet;
					invalidatePasses(null);
				}
			}
		}

		/**
		 * Removes an IMaterialOwner as owner.
		 * @param owner
		 * @private
		 */
		arcane function removeOwner(owner : IMaterialOwner) : void
		{
			_owners.splice(_owners.indexOf(owner), 1);
			if (_owners.length == 0) {
				_animationSet = null;
				for (var i : int = 0; i < _numPasses; ++i)
					_passes[i].animationSet = _animationSet;
				_depthPass.animationSet = _animationSet;
				_distancePass.animationSet = _animationSet;
				invalidatePasses(null);
			}
		}

		/**
		 * A list of the IMaterialOwners that use this material
		 * @private
		 */
		arcane function get owners() : Vector.<IMaterialOwner>
		{
			return _owners;
		}

		/**
		 * Updates the material
		 *
		 * @private
		 */
		arcane function updateMaterial(context : Context3D) : void
		{

		}

		/**
		 * Deactivates the material (in effect, its last pass)
		 * @private
		 */
		arcane function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			_passes[_numPasses-1].deactivate(stage3DProxy);
		}

		/**
		 * Marks the depth shader program as invalid, so it will be recompiled before the next render.
		 * @param triggerPass The pass triggering the invalidation, if any, so no infinite loop will occur.
		 */
		arcane function invalidatePasses(triggerPass : MaterialPassBase) : void
		{
			var owner : IMaterialOwner;
			
			_depthPass.invalidateShaderProgram();
			_distancePass.invalidateShaderProgram();
			
			if (_animationSet) {
				_animationSet.resetGPUCompatibility();
				for each (owner in _owners) {
					if (owner.animator) {
						owner.animator.testGPUCompatibility(_depthPass);
						owner.animator.testGPUCompatibility(_distancePass);
					}
				}
			}

			for (var i : int = 0; i < _numPasses; ++i) {
				if (_passes[i] != triggerPass) _passes[i].invalidateShaderProgram(false);
				// test if animation will be able to run on gpu BEFORE compiling materials
				if (_animationSet)
					for each (owner in _owners)
						if (owner.animator)
							owner.animator.testGPUCompatibility(_passes[i]);
			}
		}

		/**
		 * Clears all passes in the material.
		 */
		protected function clearPasses() : void
		{
			for (var i : int = 0; i < _numPasses; ++i) {
				_passes[i].removeEventListener(Event.CHANGE, onPassChange);
			}
			_passes.length = 0;
			_numPasses = 0;

		}

		/**
		 * Adds a pass to the material
		 * @param pass
		 */
		protected function addPass(pass : MaterialPassBase) : void
		{
			_passes[_numPasses++] = pass;
			pass.animationSet = _animationSet;
			pass.alphaPremultiplied = _alphaPremultiplied;
			pass.mipmap = _mipmap;
			pass.smooth = _smooth;
			pass.repeat = _repeat;
			pass.numPointLights = _lightPicker? _lightPicker.numPointLights : 0;
			pass.numDirectionalLights = _lightPicker? _lightPicker.numDirectionalLights : 0;
			pass.numLightProbes = _lightPicker? _lightPicker.numLightProbes : 0;
			pass.addEventListener(Event.CHANGE, onPassChange);
			calculateRenderId();
			invalidatePasses(null);
		}
		
		private function updateBlendFactors() : void
		{
			switch (_blendMode) {
				case BlendMode.NORMAL:
				case BlendMode.LAYER:
					_srcBlend = Context3DBlendFactor.SOURCE_ALPHA;
					_destBlend = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
					_requiresBlending = false; // only requires blending if a subtype needs it
					break;
				case BlendMode.MULTIPLY:
					_srcBlend = Context3DBlendFactor.ZERO;
					_destBlend = Context3DBlendFactor.SOURCE_COLOR;
					_requiresBlending = true;
					break;
				case BlendMode.ADD:
					_srcBlend = Context3DBlendFactor.SOURCE_ALPHA;
					_destBlend = Context3DBlendFactor.ONE;
					_requiresBlending = true;
					break;
				case BlendMode.ALPHA:
					_srcBlend = Context3DBlendFactor.ZERO;
					_destBlend = Context3DBlendFactor.SOURCE_ALPHA;
					_requiresBlending = true;
					break;
				default:
					throw new ArgumentError("Unsupported blend mode!");
			}
		}
		
		private function calculateRenderId() : void
		{
		}

		private function onPassChange(event : Event) : void
		{
			var mult : Number = 1;
			var ids : Vector.<int>;
			var len : int;

			_renderOrderId = 0;

			for (var i : int = 0; i < _numPasses; ++i) {
				ids = _passes[i]._program3Dids;
				len = ids.length;
				for (var j : int = 0; j < len; ++j) {
					if (ids[j] != -1) {
						_renderOrderId += mult*ids[j];
						j = len;
					}
				}
				mult *= 1000;
			}
		}
	}
}