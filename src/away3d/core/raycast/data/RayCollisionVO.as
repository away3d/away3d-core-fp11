package away3d.core.raycast.data
{

	import flash.geom.Point;
	import flash.geom.Vector3D;

	public class RayCollisionVO
	{
		public var localRayPosition:Vector3D;
		public var localRayDirection:Vector3D;
		public var collisionNearT:Number;
		public var collisionFarT:Number;
		public var collisionUV:Point;
		public var rayOriginIsInsideBounds:Boolean;

		public function get collisionPoint():Vector3D {
			var point:Vector3D = new Vector3D();
			point.x = localRayPosition.x + collisionNearT * localRayDirection.x;
			point.y = localRayPosition.y + collisionNearT * localRayDirection.y;
			point.z = localRayPosition.z + collisionNearT * localRayDirection.z;
			return point;
		}
	}
}
