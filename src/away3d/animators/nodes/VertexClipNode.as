package away3d.animators.nodes
{
	import away3d.core.base.*;
	import away3d.library.assets.*;

	/**
	 * @author robbateman
	 */
	public class VertexClipNode extends AnimationNodeBase
	{
		private var _totalDuration : uint = 0;
		private var _framesDirty : Boolean;
		private var _frames : Vector.<Geometry> = new Vector.<Geometry>();		
		private var _durations : Vector.<uint> = new Vector.<uint>();
		private var _fixedFrameRate:Boolean;
		private var _currentGeometry : Geometry;
		private var _nextGeometry : Geometry;
		private var _blendWeight : Number;
		
		public function get currentGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentGeometry;
		}
		
		
		public function get nextGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextGeometry;
		}
		
		
		public function get blendWeight() : Number
		{
			if (_framesDirty)
				updateFrames();
			
			return _blendWeight;
		}
		
		public function VertexClipNode()
		{
		}
		
		public function addFrame(geometry : Geometry, duration : uint) : void
		{
			_totalDuration += duration;
			_frames.push(geometry);
			_durations.push(duration);
		}
		
		override protected function updateTime(time:Number):void
		{
			super.updateTime(time);
			
			_framesDirty = true;
		}

		private function updateFrames() : void
		{
			var dur : uint, frameTime : uint, currentFrame : uint, nextFrame : uint;
			var numFrames : int = _durations.length;
			
			if ((_time > _totalDuration || _time < 0) && looping) {
				_time %= _totalDuration;
				if (_time < 0) _time += _totalDuration;
			}
			
			var lastFrame : uint = numFrames - 1;
			
			if (!looping && _time > _totalDuration - _durations[lastFrame]) {
				//_activeSequence.notifyPlaybackComplete();
				currentFrame = lastFrame;
				nextFrame = lastFrame;
				_blendWeight = 0;
			}
			else if (_fixedFrameRate) {
				var t : Number = _time/_totalDuration * numFrames;
				currentFrame = t;
				nextFrame = currentFrame + 1;
				_blendWeight = t - currentFrame;
				if (currentFrame == numFrames) currentFrame = 0;
				if (nextFrame >= numFrames) nextFrame -= numFrames;
			}
			else {
				do {
					frameTime = dur;
					dur += _durations[currentFrame];
					currentFrame = nextFrame;
					if (++nextFrame == numFrames) {
						nextFrame = 0;
					}
				} while (_time > dur);
				
				_blendWeight = (_time - frameTime) / _durations[currentFrame];
			}
			
			_currentGeometry = _frames[currentFrame];
			_nextGeometry = _frames[nextFrame];
		}
	}
}
