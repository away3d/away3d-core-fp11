package away3d.bounds
{
	import away3d.core.base.Geometry;
	import away3d.core.geom.Plane3D;
	import away3d.core.geom.PlaneClassification;
	import away3d.entities.IEntity;

	import flash.geom.*;

	/**
	 * NullBounds represents a debug bounding "volume" that is either considered always in, or always out of the frustum.
	 * NullBounds is useful for entities that are always considered in the frustum, such as directional lights or skyboxes.
	 */
	public class NullBounds extends BoundingVolumeBase
	{
		private var _alwaysIn:Boolean;

		public function NullBounds(alwaysIn:Boolean = true)
		{
			super();
			_alwaysIn = alwaysIn;
			_aabb.width = _aabb.height = _aabb.depth = Number.POSITIVE_INFINITY;
			_aabb.x = _aabb.y = _aabb.z = _alwaysIn ? Number.NEGATIVE_INFINITY / 2 : Number.POSITIVE_INFINITY;
		}

		override public function clone():BoundingVolumeBase
		{
			return new NullBounds(_alwaysIn);
		}

		override protected function createBoundingEntity():IEntity
		{
			return null;//_renderable || new WireframeSphere(100, 16, 12, 0xffffff, 0.5);
		}

		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(planes:Vector.<Plane3D>, numPlanes:int):Boolean
		{
			return _alwaysIn;
		}

		/**
		 * @inheritDoc
		 */
		override public function fromGeometry(geometry:Geometry):void
		{
		}

		/**
		 * @inheritDoc
		 */
		override public function fromSphere(center:Vector3D, radius:Number):void
		{
		}

		/**
		 * @inheritDoc
		 */
		override public function fromExtremes(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number):void
		{
		}

		override public function classifyToPlane(plane:Plane3D):int
		{
			return PlaneClassification.INTERSECT;
		}

		override public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):void
		{
			_alwaysIn = NullBounds(bounds)._alwaysIn;
		}
	}
}
