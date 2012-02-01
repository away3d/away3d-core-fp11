package away3d.raytracing.data
{

	import away3d.core.data.RenderableListItem;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	public class MouseCollisionVO
	{
		public var entity:Entity;
		public var renderableItems:Vector.<RenderableListItem>;
		public var t:Number;
		public var localRayPosition:Vector3D;
		public var localRayDirection:Vector3D;
		public var cameraIsInEntityBounds:Boolean;

		public function MouseCollisionVO() {
			renderableItems = new Vector.<RenderableListItem>();
		}
	}
}
