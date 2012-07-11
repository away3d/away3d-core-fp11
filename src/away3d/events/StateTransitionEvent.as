package away3d.events
{
	import flash.events.Event;

	/**
	 * Dispatched to notify changes in an animation transition's state.
	 */
	public class StateTransitionEvent extends Event
	{
		/**
		 * Completed transition.
		 */
		public static const TRANSITION_COMPLETE : String = "transitionComplete";

		/**
		 * Create a new StateTransitionEvent
		 * @param type The event type.
		 */
		public function StateTransitionEvent(type:String)
		{
			super(type);
		}

		/**
		 * Clones the event.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone() : Event
		{
			return new StateTransitionEvent(type);
		}
	}
}
