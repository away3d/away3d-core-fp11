package away3d.events
{
	import away3d.animators.*;

	import flash.events.*;

	/**
	 * AnimationEvent is an Event dispatched to notify changes in an animation's state.
	 */
	public class AnimatorEvent extends Event
	{
		/**
    	 * Defines the value of the type property of a start event object.
    	 */
    	public static const START:String = "start";

    	/**
    	 * Defines the value of the type property of a stop event object.
    	 */
    	public static const STOP:String = "stop";
		
		private var _animator : AnimatorBase;

		/**
		 * Create a new GeometryEvent
		 * @param type The event type.
		 * @param subGeometry An optional SubGeometry object that is the subject of this event.
		 */
		public function AnimatorEvent(type : String, animator : AnimatorBase) : void
		{
			super(type, false, false);
			_animator = animator;
		}

		public function get animator() : AnimatorBase
		{
			return _animator;
		}

		/**
		 * Clones the event.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone() : Event
		{
			return new AnimatorEvent(type, _animator);
		}
	}
}
