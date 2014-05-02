package away3d.events {
	import flash.events.Event;

	public class MaterialEvent extends Event{
		public static const SIZE_CHANGED:String = "side"
		public function MaterialEvent(type:String) {
			super(type);
		}
	}
}
