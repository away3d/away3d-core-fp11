package away3d.animators.states
{
	import away3d.animators.*;
	import away3d.animators.nodes.*;
	
	import flash.geom.*;
	
	/**
	 *
	 */
	public class AnimationStateBase implements IAnimationState
	{
		protected var _animationNode:AnimationNodeBase;
		protected var _rootDelta:Vector3D = new Vector3D();
		protected var _positionDeltaDirty:Boolean = true;
		
		protected var _time:int;
		protected var _startTime:int;
		protected var _animator:IAnimator;
		
		/**
		 * Returns a 3d vector representing the translation delta of the animating entity for the current timestep of animation
		 */
		public function get positionDelta():Vector3D
		{
			if (_positionDeltaDirty)
				updatePositionDelta();
			
			return _rootDelta;
		}
		
		function AnimationStateBase(animator:IAnimator, animationNode:AnimationNodeBase)
		{
			_animator = animator;
			_animationNode = animationNode;
		}
		
		/**
		 * Resets the start time of the node to a  new value.
		 *
		 * @param startTime The absolute start time (in milliseconds) of the node's starting time.
		 */
		public function offset(startTime:int):void
		{
			_startTime = startTime;
			
			_positionDeltaDirty = true;
		}
		
		/**
		 * Updates the configuration of the node to its current state.
		 *
		 * @param time The absolute time (in milliseconds) of the animator's play head position.
		 *
		 * @see away3d.animators.AnimatorBase#update()
		 */
		public function update(time:int):void
		{
			if (_time == time - _startTime)
				return;
			
			updateTime(time);
		}
		
		/**
		 * Sets the animation phase of the node.
		 *
		 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
		 */
		public function phase(value:Number):void
		{
		}
		
		/**
		 * Updates the node's internal playhead position.
		 *
		 * @param time The local time (in milliseconds) of the node's playhead position.
		 */
		protected function updateTime(time:int):void
		{
			_time = time - _startTime;
			
			_positionDeltaDirty = true;
		}
		
		/**
		 * Updates the node's root delta position
		 */
		protected function updatePositionDelta():void
		{
		}
	}
}
