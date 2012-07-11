package away3d.events
{
	import away3d.animators.*;
	import away3d.animators.nodes.*;

	import flash.events.Event;

	/**
	 * Dispatched to notify changes in an animation's state.
	 */
	public class AnimationStateEvent extends Event
	{
		/**
    	 * Fires when a non-looping clip node reaches the end of its timeline.
    	 */
    	public static const PLAYBACK_COMPLETE:String = "playbackComplete";
		
		private var _animationState:IAnimationState;
		private var _animationNode:AnimationNodeBase;
		
		/**
		 * Create a new AnimatonStateEvent
		 * @param type The event type.
		 * @param animator An optional SubGeometry object that is the subject of this event.
		 */
		public function AnimationStateEvent(type : String, animationState : IAnimationState, animationNode:AnimationNodeBase) : void
		{
			super(type, false, false);
			_animationState = animationState;
			_animationNode = animationNode;
		}

		public function get animationState() : IAnimationState
		{
			return _animationState;
		}

		/**
		 * Clones the event.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone() : Event
		{
			return new AnimationStateEvent(type, _animationState, _animationNode);
		}
	}
}
