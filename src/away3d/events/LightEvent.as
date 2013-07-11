package away3d.events
{
	import flash.events.Event;
	
	public class LightEvent extends Event
	{
		public static const CASTS_SHADOW_CHANGE:String = "castsShadowChange";
		
		public function LightEvent(type:String)
		{
			super(type);
		}
		
		override public function clone():Event
		{
			return new LightEvent(type);
		}
	}
}
