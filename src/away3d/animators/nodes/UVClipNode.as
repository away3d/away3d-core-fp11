package away3d.animators.nodes
{
	import away3d.animators.data.*;

	/**
	 * @author robbateman
	 */
	public class UVClipNode extends AnimationClipNodeBase implements IUVAnimationNode
	{
		private var _frames : Vector.<UVAnimationFrame> = new Vector.<UVAnimationFrame>();
		private var _currentUVFrame : UVAnimationFrame;
		private var _nextUVFrame : UVAnimationFrame;
		
		public function get currentUVFrame() : UVAnimationFrame
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentUVFrame;
		}
		
		
		public function get nextUVFrame() : UVAnimationFrame
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextUVFrame;
		}
		
		public function get frames():Vector.<UVAnimationFrame>
		{
			return _frames;
		}
		
		public function UVClipNode()
		{
		}
		
		public function addFrame(uvFrame : UVAnimationFrame, duration : uint) : void
		{
			_frames.push(uvFrame);
			_durations.push(duration);
			
			_numFrames = _durations.length;
			
			_stitchDirty = true;
		}
		
		override protected function updateTime(time:int):void
		{
			super.updateTime(time);
			
			_framesDirty = true;
		}

		override protected function updateFrames() : void
		{
			super.updateFrames();
			
			_currentUVFrame = _frames[_currentFrame];
			
			if (_looping && _nextFrame >= _lastFrame)
				_nextUVFrame = _frames[0];
			else
				_nextUVFrame = _frames[_nextFrame];
		}
		
		override protected function updateStitch():void
		{
			super.updateStitch();
			
			var i:uint = _numFrames - 1;
			while (i--) {
				_totalDuration += _durations[i];
			}
			
			if (_stitchFinalFrame || !_looping) {
				_totalDuration += _durations[_numFrames - 1];
			}
		}
	}
}
