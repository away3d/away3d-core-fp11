package away3d.events {
	import flash.events.Event;

	public class RendererEvent extends Event{
		public static const VIEWPORT_UPDATED:String = "viewportUpdated";
		public static const SCISSOR_UPDATED:String = "scissorUpdated";

		public function RendererEvent(type:String) {
			super(type);
		}
	}
}
