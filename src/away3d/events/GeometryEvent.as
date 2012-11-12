package away3d.events
{
	import away3d.core.base.ISubGeometry;

	import flash.events.Event;

	/**
	 * Dispatched to notify changes in a geometry object's state.
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

		public static const BOUNDS_INVALID : String = "BoundsInvalid";

		private var _subGeometry : ISubGeometry;

		/**
		 * Create a new GeometryEvent
		 * @param type The event type.
		 * @param subGeometry An optional SubGeometry object that is the subject of this event.
		 */
		public function GeometryEvent(type : String, subGeometry : ISubGeometry = null) : void
		{
			super(type, false, false);
			_subGeometry = subGeometry;
		}

		/**
		 * The SubGeometry object that is the subject of this event, if appropriate.
		 */
		public function get subGeometry() : ISubGeometry
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
