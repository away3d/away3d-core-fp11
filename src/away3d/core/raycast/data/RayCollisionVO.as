package away3d.core.raycast.data
{

	import flash.geom.Point;
	import flash.geom.Vector3D;

	public class RayCollisionVO
	{
		public var localRayPosition:Vector3D;
		public var localRayDirection:Vector3D;
		public var nearT:Number;
		public var farT:Number;
		public var uv:Point;
		public var normal:Vector3D;
		public var rayOriginIsInsideBounds:Boolean;
		public var position:Vector3D;
	}
}
