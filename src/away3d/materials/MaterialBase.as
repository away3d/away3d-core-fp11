package away3d.materials
{
	import away3d.animators.data.AnimationBase;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.IRenderable;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	import away3d.lights.LightBase;
	import away3d.materials.passes.DepthMapPass;
	import away3d.materials.passes.MaterialPassBase;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;

	use namespace arcane;

	/**
	 * MaterialBase forms an abstract base class for any material.
	 *
	 * Vertex stream index 0 is reserved for vertex positions.
	 * Vertex shader constants index 0-3 are reserved for projections
	 */
	public class MaterialBase extends NamedAssetBase implements IAsset
	{
		/**
		 * An object to contain any extra data
		 */
		public var extra : Object;

		private var _materialLibrary : MaterialLibrary;

		// this value is usually derived from other settings
		arcane var _uniqueId : int;
		arcane var _name : String = "material";
		private var _namespace : String = "";

		private var _bothSides : Boolean;
		private var _animation : AnimationBase;

		private var _owners : Vector.<IMaterialOwner>;

		private var _requiresBlending : Boolean;

		private var _blendMode : String = BlendMode.NORMAL;
		private var _srcBlend : String = Context3DBlendFactor.SOURCE_ALPHA;
		private var _destBlend : String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;

		protected var _numPasses : uint;
		private var _passes : Vector.<MaterialPassBase>;

		protected var _mipmap : Boolean;
		private var _smooth : Boolean;
		private var _repeat : Boolean;

		private var _lights : Array;

		private var _mipmapBitmap : BitmapData;
		private var _depthPass : DepthMapPass;

		/**
		 * Creates a new MaterialBase object.
		 */
		public function MaterialBase()
		{
			_materialLibrary = MaterialLibrary.getInstance();
			_materialLibrary.registerMaterial(this);
			_owners = new Vector.<IMaterialOwner>();
			_passes = new Vector.<MaterialPassBase>();
			_depthPass = new DepthMapPass();

			invalidateDepthShaderProgram();
		}
		
		
		public function get assetType() : String
		{
			return AssetType.MATERIAL;
		}

		public function get lights() : Array
		{
			return _lights;
		}

		public function set lights(value : Array) : void
		{
			_lights = value;
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
		 * Sets the materials name and namespace.
		 * @param name The name of the material.
		 * @param materialNameSpace The name space of the material.
		 */
		public function setNameAndSpace(name : String, materialNameSpace : String) : void
		{
			materialNameSpace ||= "";
			_materialLibrary.unsetName(this);
			_namespace = materialNameSpace;
			_name = name;
			_materialLibrary.setName(this);
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose(deep : Boolean) : void
		{
			var i : uint;

			_materialLibrary.unregisterMaterial(this);

			for (i = 0; i < _numPasses; ++i) _passes[i].dispose(deep);

			if (_mipmapBitmap) _mipmapBitmap.dispose();

			_depthPass.dispose(deep);
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
		}

		/**
		 * The blend mode to use when drawing this renderable. The following blend modes are supported:
		 * <ul>
		 * <li>BlendMode.NORMAL<li>
		 * <li>BlendMode.MULTIPLY<li>
		 * <li>BlendMode.ADD<li>
		 * <li>BlendMode.ALPHA<li>
		 * </ul>
		 */
		public function get blendMode() : String
		{
			return _blendMode;
		}

		public function set blendMode(value : String) : void
		{
			_blendMode = value;

			_requiresBlending = true;
			switch (value) {
				case BlendMode.NORMAL:
				case BlendMode.LAYER:
					_srcBlend = Context3DBlendFactor.SOURCE_ALPHA;
					_destBlend = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
					_requiresBlending = false; // only requires blending if a subtype needs it
					break;
				case BlendMode.MULTIPLY:
					_srcBlend = Context3DBlendFactor.ZERO;
					_destBlend = Context3DBlendFactor.SOURCE_COLOR;
					break;
				case BlendMode.ADD:
					_srcBlend = Context3DBlendFactor.SOURCE_ALPHA;
					_destBlend = Context3DBlendFactor.ONE;
					break;
				case BlendMode.ALPHA:
					_srcBlend = Context3DBlendFactor.ZERO;
					_destBlend = Context3DBlendFactor.SOURCE_ALPHA;
					break;
				default:
					throw new ArgumentError("Unsupported blend mode!");
			}

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

		/**
		 * The namespace of the material, used by the MaterialLibrary.
		 */
		public function get materialNamespace() : String
		{
			return _namespace;
		}

		public function set materialNamespace(value : String) : void
		{
			_materialLibrary.unsetName(this);
			_namespace = value;
			_materialLibrary.setName(this);
		}

		public override function get name() : String
		{
			return _name;
		}

		public override function set name(value : String) : void
		{
			_materialLibrary.unsetName(this);
			_name = value;
			_materialLibrary.setName(this);
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

		arcane function activateForDepth(context : Context3D, contextIndex : uint, camera : Camera3D) : void
		{
			_depthPass.activate(context, contextIndex, camera);
		}

		arcane function deactivateForDepth(context : Context3D) : void
		{
			_depthPass.deactivate(context);
		}

		arcane function renderDepth(renderable : IRenderable, context : Context3D, contextIndex : uint, camera : Camera3D) : void
		{
			if (renderable.animationState)
				renderable.animationState.setRenderState(context, contextIndex, _depthPass, renderable);

			_depthPass.render(renderable, context, contextIndex, camera);
		}

		/**
		 * Sets the render state for a pass that is independent of the rendered object.
		 * @param index The index of the pass to activate.
		 * @param context The Context3D object which is currently rendering.
		 * @param camera The camera from which the scene is viewed.
		 * @private
		 */
		arcane function activatePass(index : uint, context : Context3D, contextIndex : uint, camera : Camera3D) : void
		{
			if (index == _numPasses-1) {
				if (requiresBlending)
					context.setBlendFactors(_srcBlend, _destBlend);
			}

			_passes[index].activate(context, contextIndex, camera);
		}

		/**
		 * Clears the render state for a pass.
		 * @param index The index of the pass to deactivate.
		 * @param context The Context3D object that is currently rendering.
		 * @private
		 */
		arcane function deactivatePass(index : uint, context : Context3D) : void
		{
			_passes[index].deactivate(context);
		}

		/**
		 * Renders a renderable with a pass.
		 * @param index The pass to render with.
		 * @param renderable The renderable to render.
		 * @param context The Context3D object which is currently rendering.
		 * @param camera The camera from which the scene is rendered.
		 * @param lights The lights which are influencing the lighting of the scene.
		 * @private
		 */
		arcane function renderPass(index : uint, renderable : IRenderable, context : Context3D, contextIndex : uint, camera : Camera3D) : void
		{
			if (renderable.animationState)
				renderable.animationState.setRenderState(context, contextIndex, _passes[index], renderable);

			_passes[index].render(renderable, context, contextIndex, camera);
		}


//
// MATERIAL MANAGEMENT
//
		/**
		 * Mark an IMaterialOwner as owner of this material. It's also used by the material library to ensure materials
		 * are correctly replaced.
		 * Assures we're not using the same material across renderables with different animations, since the
		 * Program3Ds depend on animation. This method needs to be called when a material is assigned.
		 *
		 * @param owner The IMaterialOwner that had this material assigned
		 *
		 * @private
		 */
		arcane function addOwner(owner : IMaterialOwner) : void
		{
			if (_animation) {
				if (!owner.animation.equals(_animation))
					throw new Error("A Material instance cannot be shared across renderables with different animation instances");
			}
			else {
				_animation = owner.animation;
				for (var i : int = 0; i < _numPasses; ++i)
					_passes[i].animation = _animation;
				_depthPass.animation = _animation;
			}

			_owners.push(owner);
		}

		/**
		 * Removes an IMaterialOwner as owner.
		 * @param owner
		 * @private
		 */
		arcane function removeOwner(owner : IMaterialOwner) : void
		{
			_owners.splice(_owners.indexOf(owner), 1);
			if (_owners.length == 0) _animation = null;
		}

		/**
		 * Assignes a unique id to the material.
		 * @param id
		 * @private
		 */
		arcane function setUniqueId(id : int) : void
		{
			_uniqueId = id;
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
		arcane function deactivate(context : Context3D) : void
		{
			_passes[_numPasses-1].deactivate(context);
		}

		/**
		 * Marks the depth shader program as invalid, so it will be recompiled before the next render.
		 */
		arcane function invalidateDepthShaderProgram() : void
		{
			_depthPass.invalidateShaderProgram();
		}

		/**
		 * Clears all passes in the material.
		 */
		protected function clearPasses() : void
		{
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
			pass.animation = _animation;
			pass.mipmap = _mipmap;
			pass.smooth = _smooth;
			pass.repeat = _repeat;
			pass.lights = _lights? Vector.<LightBase>(_lights) : null;
		}
	}
}