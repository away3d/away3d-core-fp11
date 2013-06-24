package away3d.bounds
{
	import away3d.core.base.*;
	import away3d.core.math.Plane3D;
	import away3d.core.math.PlaneClassification;
	import away3d.primitives.*;
	
	import flash.geom.*;
	
	/**
	 * NullBounds represents a debug bounding "volume" that is either considered always in, or always out of the frustum.
	 * NullBounds is useful for entities that are always considered in the frustum, such as directional lights or skyboxes.
	 */
	public class NullBounds extends BoundingVolumeBase
	{
		private var _alwaysIn:Boolean;
		private var _renderable:WireframePrimitiveBase;
		
		public function NullBounds(alwaysIn:Boolean = true, renderable:WireframePrimitiveBase = null)
		{
			super();
			_alwaysIn = alwaysIn;
			_renderable = renderable;
			_max.x = _max.y = _max.z = Number.POSITIVE_INFINITY;
			_min.x = _min.y = _min.z = _alwaysIn? Number.NEGATIVE_INFINITY : Number.POSITIVE_INFINITY;
		}
		
		override public function clone():BoundingVolumeBase
		{
			return new NullBounds(_alwaysIn);
		}
		
		override protected function createBoundingRenderable():WireframePrimitiveBase
		{
			return _renderable || new WireframeSphere(100, 16, 12, 0xffffff, 0.5);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(planes:Vector.<Plane3D>, numPlanes:int):Boolean
		{
			planes = planes;
			numPlanes = numPlanes;
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
			plane = plane;
			return PlaneClassification.INTERSECT;
		}
		
		override public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):void
		{
			matrix = matrix;
			_alwaysIn = NullBounds(bounds)._alwaysIn;
		}
	}
}
