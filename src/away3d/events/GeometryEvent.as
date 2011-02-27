package away3d.events
{
	import away3d.core.base.SubGeometry;

	import flash.events.Event;

	/**
	 * GeometryEvent is an Event dispatched to notify changes on a Geometry object.
	 *
	 * @see away3d.core.base.Geometry
	 */
	public class GeometryEvent extends Event
	{
		/**
		 * Dispatched when a SubGeometry was added from the dispatching Geometry.
		 */
		public static const SUB_GEOMETRY_ADDED : String = "SubGeometryAdded";

		/**
		 * Dispatched when a SubGeometry was removed from the dispatching Geometry.
		 */
		public static const SUB_GEOMETRY_REMOVED : String = "SubGeometryRemoved";

		/**
		 * Dispatched when the Animation property of the dispatching Geometry was changed.
		 */
		public static const ANIMATION_CHANGED : String = "AnimationChanged";

		private var _subGeometry : SubGeometry;

		/**
		 * Create a new GeometryEvent
		 * @param type The event type.
		 * @param subGeometry An optional SubGeometry object that is the subject of this event.
		 */
		public function GeometryEvent(type : String, subGeometry : SubGeometry = null) : void
		{
			super(type, false, false);
			_subGeometry = subGeometry;
		}

		/**
		 * The SubGeometry object that is the subject of this event, if appropriate.
		 */
		public function get subGeometry() : SubGeometry
		{
			return _subGeometry;
		}

		/**
		 * Clones the event.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone() : Event
		{
			return new GeometryEvent(type, _subGeometry);
		}
	}
}
