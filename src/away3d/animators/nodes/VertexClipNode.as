package away3d.animators.nodes
{
	import away3d.core.base.Geometry;
	import away3d.animators.nodes.AnimationNodeBase;

	/**
	 * @author robbateman
	 */
	public class VertexClipNode extends AnimationNodeBase implements IAnimationNode
	{
		private var _totalDuration : uint = 0;
		private var _frames : Vector.<Geometry> = new Vector.<Geometry>();		
		private var _durations : Vector.<uint> = new Vector.<uint>();
		private var _fixedFrameRate:Boolean;
		private var _currentFrame : Geometry;
		private var _nextFrame : Geometry;
		private var _blendWeight : Number;
		
		public var looping : Boolean = true;
		
		public function get currentFrame() : Geometry
		{
			return _currentFrame;
		}
		
		
		public function get nextFrame() : Geometry
		{
			return _nextFrame;
		}
		
		
		public function get blendWeight() : Number
		{
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
		
		public function update(time:Number):void
		{
			var dur : uint, frameTime : uint, current : uint, next : uint;
			var numFrames : int = _durations.length;
			
			if ((time > _totalDuration || time < 0) && looping) {
				time %= _totalDuration;
				if (time < 0) time += _totalDuration;
			}
			
			var lastFrame : uint = numFrames - 1;
			
			if (!looping && time > _totalDuration - _durations[lastFrame]) {
				//_activeSequence.notifyPlaybackComplete();
				current = lastFrame;
				next = lastFrame;
				_blendWeight = 0;
			}
			else if (_fixedFrameRate) {
				var t : Number = time/_totalDuration * numFrames;
				current = t;
				next = current + 1;
				_blendWeight = t - current;
				if (current == numFrames) current = 0;
				if (next >= numFrames) next -= numFrames;
			}
			else {
				do {
					frameTime = dur;
					dur += _durations[current];
					current = next;
					if (++next == numFrames) {
						next = 0;
					}
				} while (time > dur);
				
				_blendWeight = (time - frameTime) / _durations[current];
				
				_currentFrame = _frames[current];
				_nextFrame = _frames[next];
			}
		}
	}
}
