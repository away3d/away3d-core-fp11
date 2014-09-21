package away3d.entities
{
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.Object3D;
	import away3d.core.geom.UVTransform;
	import away3d.core.library.AssetType;
	import away3d.core.partition.EntityNode;
	import away3d.core.render.IRenderer;
	import away3d.events.MaterialEvent;
	import away3d.materials.MaterialBase;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class LineSegment extends Object3D implements IEntity, IMaterialOwner
	{
		private var _animator:IAnimator;
		private var _material:MaterialBase;
		private var _uvTransform:UVTransform;
		public var _startPosition:Vector3D;
		public var _endPosition:Vector3D;
		public var _halfThickness:Number;

		/**
		 * Defines the animator of the line segment. Act on the line segment's geometry. Defaults to null
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
			return AssetType.LINE_SEGMENT;
		}

		/**
		 *
		 */
		public function get startPostion():Vector3D
		{
			return _startPosition;
		}

		public function set startPosition(value:Vector3D):void
		{
			if (_startPosition == value)
				return;

			_startPosition = value;

			notifyRenderableUpdate();
		}

		/**
		 *
		 */
		public function get endPosition():Vector3D
		{
			return _endPosition;
		}

		public function set endPosition(value:Vector3D):void
		{
			if (_endPosition == value)
				return;

			_endPosition = value;

			notifyRenderableUpdate();
		}

		/**
		 *
		 */
		public function get material():MaterialBase
		{
			return _material;
		}

		public function set material(value:MaterialBase):void
		{
			if (value == _material)
				return;

			if (_material) {
				_material.removeOwner(this);
				_material.removeEventListener(MaterialEvent.SIZE_CHANGED, onSizeChangedDelegate);
			}


			_material = value;

			if (_material) {
				_material.addOwner(this);
				_material.addEventListener(MaterialEvent.SIZE_CHANGED, onSizeChangedDelegate);
			}
		}

		private function onSizeChangedDelegate(event:MaterialEvent):void
		{
			notifyRenderableUpdate();
		}

		/**
		 *
		 */
		public function get thickness():Number
		{
			return _halfThickness * 2;
		}

		public function set thickness(value:Number):void
		{
			if (_halfThickness == value)
				return;

			_halfThickness = value * 0.5;

			notifyRenderableUpdate();
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

		/**
		 * Create a line segment
		 *
		 * @param startPosition Start position of the line segment
		 * @param endPosition Ending position of the line segment
		 * @param thickness Thickness of the line
		 */
		public function LineSegment(material:MaterialBase, startPosition:Vector3D, endPosition:Vector3D, thickness:Number = 1)
		{
			super();

			_isEntity = true;

			this.material = material;

			_startPosition = startPosition;
			_endPosition = endPosition;
			_halfThickness = thickness * 0.5;
		}

		override public function dispose():void
		{
			_startPosition = null;
			_endPosition = null;
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
			_bounds.fromExtremes(_startPosition.x, _startPosition.y, _startPosition.z, _endPosition.x, _endPosition.y, _endPosition.z);
			super.updateBounds();
		}

		/**
		 * @private
		 */
		private function onSizeChanged(event:MaterialEvent):void
		{
			notifyRenderableUpdate();
		}

		/**
		 * @private
		 */
		private function notifyRenderableUpdate():void
		{
			var len:uint = _renderables.length;
			for (var i:uint = 0; i < len; i++)
				_renderables[i].invalidateVertexData("vertices"); //TODO
		}

		public function collectRenderables(renderer:IRenderer):void
		{
			// Since getter is invoked every iteration of the render loop, and
			// the prefab construct could affect the sub-meshes, the prefab is
			// validated here to give it a chance to rebuild.
			if (sourcePrefab)
				sourcePrefab.validate();

			collectRenderable(renderer);
		}

		public function collectRenderable(renderer:IRenderer):void
		{
			//TODO
			//			renderer.applyLineSubMesh()
		}
	}
}
