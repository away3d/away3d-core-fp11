package away3d.animators.states
{
	import away3d.animators.*;
	import away3d.animators.nodes.*;
	import away3d.events.*;
	
	/**
	 *
	 */
	public class AnimationClipState extends AnimationStateBase
	{
		private var _animationClipNode:AnimationClipNodeBase;
		private var _animationStatePlaybackComplete:AnimationStateEvent;
		protected var _blendWeight:Number;
		protected var _currentFrame:uint;
		protected var _nextFrame:uint;
		
		protected var _oldFrame:uint;
		protected var _timeDir:int;
		protected var _framesDirty:Boolean = true;
		
		/**
		 * Returns a fractional value between 0 and 1 representing the blending ratio of the current playhead position
		 * between the current frame (0) and next frame (1) of the animation.
		 *
		 * @see #currentFrame
		 * @see #nextFrame
		 */
		public function get blendWeight():Number
		{
			if (_framesDirty)
				updateFrames();
			
			return _blendWeight;
		}
		
		/**
		 * Returns the current frame of animation in the clip based on the internal playhead position.
		 */
		public function get currentFrame():uint
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentFrame;
		}
		
		/**
		 * Returns the next frame of animation in the clip based on the internal playhead position.
		 */
		public function get nextFrame():uint
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextFrame;
		}
		
		function AnimationClipState(animator:IAnimator, animationClipNode:AnimationClipNodeBase)
		{
			super(animator, animationClipNode);
			
			_animationClipNode = animationClipNode;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function update(time:int):void
		{
			if (!_animationClipNode.looping) {
				if (time > _startTime + _animationClipNode.totalDuration)
					time = _startTime + _animationClipNode.totalDuration;
				else if (time < _startTime)
					time = _startTime;
			}
			
			if (_time == time - _startTime)
				return;
			
			updateTime(time);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function phase(value:Number):void
		{
			var time:int = value*_animationClipNode.totalDuration + _startTime;
			
			if (_time == time - _startTime)
				return;
			
			updateTime(time);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time:int):void
		{
			_framesDirty = true;
			
			_timeDir = (time - _startTime > _time)? 1 : -1;
			
			super.updateTime(time);
		}
		
		/**
		 * Updates the nodes internal playhead to determine the current and next animation frame, and the blendWeight between the two.
		 *
		 * @see #currentFrame
		 * @see #nextFrame
		 * @see #blendWeight
		 */
		protected function updateFrames():void
		{
			_framesDirty = false;
			
			var looping:Boolean = _animationClipNode.looping;
			var totalDuration:uint = _animationClipNode.totalDuration;
			var lastFrame:uint = _animationClipNode.lastFrame;
			var time:int = _time;
			
			//trace("time", time, totalDuration)
			if (looping && (time >= totalDuration || time < 0)) {
				time %= totalDuration;
				if (time < 0)
					time += totalDuration;
			}
			
			if (!looping && time >= totalDuration) {
				notifyPlaybackComplete();
				_currentFrame = lastFrame;
				_nextFrame = lastFrame;
				_blendWeight = 0;
			} else if (!looping && time <= 0) {
				_currentFrame = 0;
				_nextFrame = 0;
				_blendWeight = 0;
			} else if (_animationClipNode.fixedFrameRate) {
				var t:Number = time/totalDuration*lastFrame;
				_currentFrame = t;
				_blendWeight = t - _currentFrame;
				_nextFrame = _currentFrame + 1;
			} else {
				_currentFrame = 0;
				_nextFrame = 0;
				
				var dur:uint = 0, frameTime:uint;
				var durations:Vector.<uint> = _animationClipNode.durations;
				
				do {
					frameTime = dur;
					dur += durations[nextFrame];
					_currentFrame = _nextFrame++;
				} while (time > dur);
				
				if (_currentFrame == lastFrame) {
					_currentFrame = 0;
					_nextFrame = 1;
				}
				
				_blendWeight = (time - frameTime)/durations[_currentFrame];
			}
		}
		
		private function notifyPlaybackComplete():void
		{
			_animationClipNode.dispatchEvent(_animationStatePlaybackComplete ||= new AnimationStateEvent(AnimationStateEvent.PLAYBACK_COMPLETE, _animator, this, _animationClipNode));
		}
	}
}
