package away3d.events {
	import flash.events.Event;

	public class SubGeometryEvent extends Event {
		/**
		 * Dispatched when a TriangleSubGeometry's index data has been updated.
		 */
		public static const INDICES_UPDATED:String = "indicesUpdated";

		/**
		 * Dispatched when a TriangleSubGeometry's vertex data has been updated.
		 */
		public static const VERTICES_UPDATED:String = "verticesUpdated";

		private var _dataType:String;

		public function SubGeometryEvent(type:String, dataType:String = "") {
			super(type);
			_dataType = dataType;
		}

		/**
		 * The data type of the vertex data.
		 */
		public function get dataType():String {
			return _dataType;
		}

		/**
		 * Clones the event.
		 *
		 * @return An exact duplicate of the current object.
		 */
		override public function clone():Event {
			return new SubGeometryEvent(type, _dataType);
		}
	}
}
