package away3d.events
{
	import away3d.containers.ObjectContainer3D;

	import flash.events.Event;

	public class Scene3DEvent extends Event
	{
		public static const ADDED_TO_SCENE : String = "addedToScene";
		public static const REMOVED_FROM_SCENE : String = "removedFromScene";
		public static const PARTITION_CHANGED : String = "partitionChanged";

		public var objectContainer3D : ObjectContainer3D;

		override public function get target() : Object
		{
			return objectContainer3D;
		}

		public function Scene3DEvent(type : String, objectContainer : ObjectContainer3D)
		{
			objectContainer3D = objectContainer;
			super(type);
		}

		public override function clone() : Event
		{
			return new Scene3DEvent(type, objectContainer3D);
		}
	}
}