package away3d.animators.nodes
{
	import away3d.animators.nodes.*;
	import away3d.events.*;
	
	import flash.geom.*;

	/**
	 * Provides an abstract base class for nodes with time-based animation data in an animation blend tree.
	 */
	public class AnimationClipNodeBase extends AnimationNodeBase implements IAnimationNode
	{
		private var _animationStatePlaybackComplete:AnimationStateEvent;
		
		protected var _stitchDirty:Boolean = true;
		protected var _stitchFinalFrame:Boolean = false;
		protected var _blendWeight : Number;
		protected var _framesDirty : Boolean = true;
		protected var _numFrames : uint = 0;
		protected var _lastFrame : uint;
		protected var _currentFrame : uint;
		protected var _nextFrame : uint;
		protected var _durations : Vector.<uint> = new Vector.<uint>();
		protected var _totalDelta : Vector3D = new Vector3D();
		
		public var fixedFrameRate:Boolean = true;
		
		/**
		 * Defines if looping content blends the final frame of animation data with the first (true) or works on the
		 * assumption that both first and last frames are identical (false). Defaults to false.
		 */
		public function get stitchFinalFrame() : Boolean
		{
			return _stitchFinalFrame;
		}
		
		public function set stitchFinalFrame(value:Boolean):void
		{
			if (_stitchFinalFrame == value)
				return;
			
			_stitchFinalFrame = value;
			
			_stitchDirty = true;
			_framesDirty = true;
		}
		
		/**
		 * Returns a fractional value between 0 and 1 representing the blending ratio of the current playhead position
		 * between the current frame (0) and next frame (1) of the animation.
		 * 
		 * @see #currentFrame
		 * @see #nextFrame
		 */
		public function get blendWeight() : Number
		{
			if (_framesDirty)
				updateFrames();
			
			return _blendWeight;
		}
		
		/**
		 * Returns a vector of time values representing the duration (in milliseconds) of each animation frame in the clip.
		 */
		public function get durations():Vector.<uint>
		{
			return _durations;
		}
		
		/**
		 * Returns the current frame of animation in the clip based on the internal playhead position.
		 */
		public function get currentFrame() : uint
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentFrame;
		}
		
		/**
		 * Returns the next frame of animation in the clip based on the internal playhead position.
		 */
		public function get nextFrame() : uint
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextFrame;
		}
		/**
		 * Creates a new <code>AnimationClipNodeBase</code> object.
		 */
		public function AnimationClipNodeBase()
		{
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateLooping():void
		{
			super.updateLooping();
			
			_stitchDirty = true;
		}
		
		/**
		 * Updates the nodes internal playhead to determine the current and next animation frame, and the blendWeight between the two.
		 * 
		 * @see #currentFrame
		 * @see #nextFrame
		 * @see #blendWeight
		 */
		protected function updateFrames() : void
		{
			_framesDirty = false;
			
			if (_stitchDirty)
				updateStitch();
			
			var dur : uint = 0, frameTime : uint;
			var time : int = _time;
			
			if ((time >= _totalDuration || time < 0) && _looping) {
				time %= _totalDuration;
				if (time < 0) time += _totalDuration;
			}
			
			if (!_looping && time >= _totalDuration) {
				notifyPlaybackComplete();
				_currentFrame = _lastFrame;
				_nextFrame = _lastFrame;
				_blendWeight = 0;
			}
			else if (fixedFrameRate) {
				var t : Number = time/_totalDuration * _lastFrame;
				_currentFrame = t;
				_blendWeight = t - _currentFrame;
				_nextFrame = _currentFrame + 1;
			}
			else {
				_currentFrame = 0;
				_nextFrame = 0;
				do {
					frameTime = dur;
					dur += _durations[_nextFrame];
					_currentFrame = _nextFrame++;
				} while (time > dur);
				
				if (_currentFrame == _lastFrame) {
					_currentFrame = 0;
					_nextFrame = 1;
				}
				
				_blendWeight = (time - frameTime) / _durations[_currentFrame];
			}
		}
		
		/**
		 * Updates the node's final frame stitch state.
		 * 
		 * @see #stitchFinalFrame
		 */
		protected function updateStitch():void
		{
			_stitchDirty = false;
			
			_lastFrame = (_stitchFinalFrame)? _numFrames : _numFrames - 1;
			
			_totalDuration = 0;
			_totalDelta.x = 0;
			_totalDelta.y = 0;
			_totalDelta.z = 0;
		}
		
		private function notifyPlaybackComplete():void
		{
			dispatchEvent(_animationStatePlaybackComplete || (_animationStatePlaybackComplete = new AnimationStateEvent(AnimationStateEvent.PLAYBACK_COMPLETE, null, this)));
		}
	}
}
