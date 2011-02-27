package away3d.events
{
	import away3d.animators.data.AnimationSequenceBase;

	import flash.events.Event;

	/**
	 * AnimationEvent is an Event dispatched to notify changes in an animation's state.
	 */
	public class AnimationEvent extends Event
	{
		/**
		 * Playback of the currently playing (non-looping) clip ended.
		 */
		public static const PLAYBACK_ENDED : String = "PlaybackEnded";

		private var _sequence : AnimationSequenceBase;

		/**
		 * Create a new GeometryEvent
		 * @param type The event type.
		 * @param subGeometry An optional SubGeometry object that is the subject of this event.
		 */
		public function AnimationEvent(type : String, sequence : AnimationSequenceBase = null) : void
		{
			super(type, false, false);
			_sequence = sequence;
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
			return new AnimationEvent(type, _sequence);
		}
	}
}
