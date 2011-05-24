package away3d.events
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.data.AnimationSequenceBase;

	import flash.events.Event;

	/**
	 * AnimationEvent is an Event dispatched to notify changes in an animation's state.
	 */
	public class AnimatorEvent extends Event
	{
		/**
		 * Playback of the currently playing (non-looping) clip ended.
		 */
		public static const SEQUENCE_DONE : String = "SequenceDone";

		/**
    	 * Defines the value of the type property of a start event object.
    	 */
    	public static const START:String = "start";

    	/**
    	 * Defines the value of the type property of a stop event object.
    	 */
    	public static const STOP:String = "stop";

		private var _sequence : AnimationSequenceBase;
		private var _animator : AnimatorBase;

		/**
		 * Create a new GeometryEvent
		 * @param type The event type.
		 * @param subGeometry An optional SubGeometry object that is the subject of this event.
		 */
		public function AnimatorEvent(type : String, animator : AnimatorBase, sequence : AnimationSequenceBase = null) : void
		{
			super(type, false, false);
			_sequence = sequence;
			_animator = animator;
		}

		public function get animator() : AnimatorBase
		{
			return _animator;
		}

		/**
		 * The SubGeometry object that is the subject of this event, if appropriate.
		 */
		public function get sequence() : AnimationSequenceBase
		{
			return _sequence;
		}

		/**
		 * Clones the event.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone() : Event
		{
			return new AnimatorEvent(type, _animator, _sequence);
		}
	}
}
