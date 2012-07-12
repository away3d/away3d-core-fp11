package away3d.animators.nodes
{
	import away3d.animators.nodes.*;
	import away3d.events.*;
	
	import flash.geom.*;

	/**
	 * @author robbateman
	 */
	public class AnimationClipNodeBase extends AnimationNodeBase implements IAnimationNode
	{
		private var _animationStatePlaybackComplete:AnimationStateEvent;
		private var _fixedFrameRate:Boolean = true;
		
		protected var _stitchDirty:Boolean = true;
		protected var _stitchFinalFrame:Boolean = false;
		protected var _blendWeight : Number;
		protected var _framesDirty : Boolean;
		protected var _numFrames : uint = 0;
		protected var _lastFrame : uint;
		protected var _currentFrame : uint;
		protected var _nextFrame : uint;
		protected var _durations : Vector.<Number> = new Vector.<Number>();
		protected var _totalDelta : Vector3D = new Vector3D();
		
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
		
		public function get blendWeight() : Number
		{
			if (_framesDirty)
				updateFrames();
			
			return _blendWeight;
		}
		
		public function get durations():Vector.<Number>
		{
			return _durations;
		}
		
		public function AnimationClipNodeBase()
		{
			super();
		}
		
		override protected function updateLooping():void
		{
			super.updateLooping();
			
			_stitchDirty = true;
		}
		
		protected function updateFrames() : void
		{
			_framesDirty = false;
			
			if (_stitchDirty)
				updateStitch();
			
			var dur : uint = 0, frameTime : uint;
			var time : Number = _time;
			
			if ((time > _totalDuration || time < 0) && _looping) {
				time %= _totalDuration;
				if (time < 0) time += _totalDuration;
			}
			
			if (!_looping && time >= _totalDuration) {
				notifyPlaybackComplete();
				_currentFrame = _lastFrame;
				_nextFrame = _lastFrame;
				_blendWeight = 0;
			}
			else if (_fixedFrameRate) {
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
