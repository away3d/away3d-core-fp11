package away3d.core.raycast.colliders.bounds.vo
{

	import flash.geom.Vector3D;

	public class BoundsCollisionVO
	{
		public var localRayPosition:Vector3D;
		public var localRayDirection:Vector3D;
		public var collisionNearT:Number;
		public var collisionFarT:Number;
		public var rayOriginIsInsideBounds:Boolean;
	}
}
