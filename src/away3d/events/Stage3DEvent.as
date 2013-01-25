/**
 *
 */
package away3d.events
{
	import flash.events.Event;

	public class Stage3DEvent extends Event
	{
		public static const CONTEXT3D_CREATED : String = "Context3DCreated";
		public static const CONTEXT3D_DISPOSED : String = "Context3DDisposed";
		public static const CONTEXT3D_RECREATED : String = "Context3DRecreated";
		public static const VIEWPORT_UPDATED : String = "ViewportUpdated";

		public function Stage3DEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
