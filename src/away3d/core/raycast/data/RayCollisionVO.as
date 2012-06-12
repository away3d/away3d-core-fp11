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
		public var collisionPoint:Vector3D;
	}
}
