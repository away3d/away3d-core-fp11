package away3d.events {
	import flash.events.Event;

	/**
	 * @author Paul Tondeur
	 */
	public class Scene3DEvent extends Event {
		public function Scene3DEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false) {
			super(type, bubbles, cancelable);
		}
	}
}
