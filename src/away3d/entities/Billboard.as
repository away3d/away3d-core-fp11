package away3d.entities
{
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.Object3D;
	import away3d.core.math.UVTransform;
	import away3d.core.partition.EntityNode;
	import away3d.core.render.IRenderer;
	import away3d.events.MaterialEvent;
	import away3d.library.assets.AssetType;
	import away3d.materials.IMaterial;


	use namespace arcane;

	/**
	 * Billboard is a 3D billboard, a renderable rectangular area that is always aligned with the projection plane.
	 * As a result, no perspective transformation occurs on a Billboard object.
	 *
	 * todo: mvp generation or vertex shader code can be optimized
	 */
	public class Billboard extends Object3D implements IEntity, IMaterialOwner
	{
		private var _animator:IAnimator;
		private var _billboardWidth:Number;
		private var _billboardHeight:Number;
		private var _material:IMaterial;
		private var _uvTransform:UVTransform;


		/**
		 * Defines the animator of the mesh. Act on the mesh's geometry. Defaults to null
		 */
		public function get animator():IAnimator
		{
			return _animator;
		}

		/**
		 *
		 */
		override public function get assetType():String
		{
			return AssetType.BILLBOARD;
		}

		/**
		 *
		 */
		public function get billboardHeight():Number
		{
			return _billboardHeight;
		}

		/**
		 *
		 */
		public function get billboardWidth():Number
		{
			return _billboardWidth;
		}

		/**
		 *
		 */
		public function get material():IMaterial
		{
			return _material;
		}

		public function set material(value:IMaterial):void
		{
			if (value == _material)
				return;

			if (_material) {
				_material.removeOwner(this);
				_material.removeEventListener(MaterialEvent.SIZE_CHANGED, onSizeChanged);
			}

			_material = value;

			if (_material) {
				_material.addOwner(this);
				_material.addEventListener(MaterialEvent.SIZE_CHANGED, onSizeChanged);
			}
		}

		private function onSizeChanged(event:MaterialEvent):void {
			_billboardWidth = _material.width;
			_billboardHeight = _material.height;

			_boundsInvalid = true;

			var len:uint = _renderables.length;
			for (var i:uint = 0; i < len; i++)
				_renderables[i].invalidateVertexData("vertices"); //TODO
		}

		/**
		 *
		 */
		public function get uvTransform():UVTransform
		{
			return _uvTransform;
		}

		public function set uvTransform(value:UVTransform):void
		{
			_uvTransform = value;
		}

		public function Billboard(material:IMaterial, pixelSnapping:String = "auto", smoothing:Boolean = false)
		{
			super();

			_isEntity = true;

			this.material = material;

			_billboardWidth = material.width;
			_billboardHeight = material.height;
		}

		/**
		 * @protected
		 */
		override protected function createEntityPartitionNode():EntityNode
		{
			return new EntityNode(this);
		}

		/**
		 * @protected
		 */
		override protected function updateBounds():void
		{
			_bounds.fromExtremes(0, 0, 0, _billboardWidth, _billboardHeight, 0);

			super.updateBounds();
		}

		/**
		 * //TODO
		 *
		 * @param shortestCollisionDistance
		 * @param findClosest
		 * @returns {Boolean}
		 *
		 * @internal
		 */
		override public function testCollision(shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			return _pickingCollider.testBillboardCollision(this, _pickingCollisionVO, shortestCollisionDistance);
		}

		public function collectRenderables(renderer:IRenderer):void
		{
			// Since this getter is invoked every iteration of the render loop, and
			// the prefab construct could affect the sub-meshes, the prefab is
			// validated here to give it a chance to rebuild.
			if (sourcePrefab)
				sourcePrefab.validate();

			collectRenderable(renderer);
		}

		public function collectRenderable(renderer:IRenderer):void
		{
			renderer.applyBillboard(this);
		}
	}
}
