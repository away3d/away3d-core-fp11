package away3d.prefabs {

	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.bounds.NullBounds;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.IRenderable;
	import away3d.core.base.Object3D;
	import away3d.core.math.UVTransform;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.SkyBoxNode;
	import away3d.core.render.IRenderer;
	import away3d.entities.IEntity;
	import away3d.library.assets.AssetType;
	import away3d.materials.IMaterial;

	use namespace arcane;

	/**
	 * A SkyBox class is used to render a sky in the scene. It's always considered static and 'at infinity', and as
	 * such it's always centered at the camera's position and sized to exactly fit within the camera's frustum, ensuring
	 * the sky box is always as large as possible without being clipped.
	 */
	public class SkyBox extends Object3D implements IEntity, IMaterialOwner
	{
		private var _uvTransform:UVTransform = new UVTransform();
		private var _material:IMaterial;
		private var _animator:IAnimator;

		public function get animator():IAnimator
		{
			return _animator;
		}

		/**
		 * Create a new Skybox object.
		 *
		 * @param material    The material with which to render the Skybox.
		 */
		public function SkyBox(material:IMaterial)
		{
			_isEntity = true;
			this.material = material;
		}

		/**
		 * The material with which to render the Skybox.
		 */
		public function get material():IMaterial
		{
			return this._material;
		}

		public function set material(value:IMaterial):void
		{
			if (value == _material)
				return;

			if (_material) {
				_material.removeOwner(this);
			}

			_material = value;

			if (_material)
				_material.addOwner(this);
		}

		public function get uvTransform():UVTransform
		{
			return _uvTransform;
		}

		public function set uvTransform(value:UVTransform):void
		{
			_uvTransform = value;
		}


		override public function get assetType():String
		{
			return AssetType.SKYBOX;
		}

		/**
		 * @protected
		 */
		override protected function invalidateBounds():void
		{
			// dead end
		}

		/**
		 * @protected
		 */
		override protected function createEntityPartitionNode():EntityNode
		{
			return new SkyBoxNode(this);
		}
		/**
		 * @protected
		 */
		override protected function updateBounds():void
		{
			_boundsInvalid = false;
		}

		override public function get castsShadows():Boolean
		{
			return false; //TODO
		}


		public function collectRenderables(renderer:IRenderer):void {
			// Since this getter is invoked every iteration of the render loop, and
			// the prefab construct could affect the sub-meshes, the prefab is
			// validated here to give it a chance to rebuild.
			if (sourcePrefab)
				sourcePrefab.validate();

			collectRenderable(renderer);
		}

		public function addRenderable(renderable:IRenderable):IRenderable {
			return null;
		}

		public function removeRenderable(renderable:IRenderable):IRenderable {
			return null;
		}

		public function collectRenderable(renderable:IRenderer):void {
		}
	}
}
