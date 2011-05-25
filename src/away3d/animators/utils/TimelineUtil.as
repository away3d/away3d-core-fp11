package away3d.animators.utils
{
	import away3d.animators.data.AnimationSequenceBase;
	import away3d.arcane;
	
	use namespace arcane;

	public class TimelineUtil
	{
		private var _frame0 : uint;
		private var _frame1 : uint;
		private var _blendWeight : Number;
		
		public function TimelineUtil()
		{
		}
		
		
		public function get frame0() : Number
		{
			return _frame0;
		}
		
		
		public function get frame1() : Number
		{
			return _frame1;
		}
		
		
		public function get blendWeight() : Number
		{
			return _blendWeight;
		}
		
		/**
		 * Calculates the frames between which to interpolate.
		 */
		public function updateFrames(time : Number, _activeSequence : AnimationSequenceBase) : void
		{
			var lastFrame : uint, frame : uint, nextFrame : uint;
			var dur : uint, frameTime : uint;
			var durations : Vector.<uint> = _activeSequence._durations;
			var totalDuration : uint = _activeSequence._totalDuration;
			var looping : Boolean = _activeSequence.looping;
			var numFrames : int = durations.length;
			var w : Number;
			
			if ((time > totalDuration || time < 0) && looping) {
				time %= totalDuration;
				if (time < 0) time += totalDuration;
			}
			
			lastFrame = numFrames - 1;
			
			if (!looping && time > totalDuration - durations[lastFrame]) {
				_activeSequence.notifyPlaybackComplete();
				frame = lastFrame;
				nextFrame = lastFrame;
				w = 0;
			}
			else if (_activeSequence._fixedFrameRate) {
				var t : Number = time/totalDuration * numFrames;
				frame = t;
				nextFrame = frame + 1;
				w = t - frame;
				if (frame == numFrames) frame = 0;
				if (nextFrame >= numFrames) nextFrame -= numFrames;
			}
			else {
				do {
					frameTime = dur;
					dur += durations[frame];
					frame = nextFrame;
					if (++nextFrame == numFrames) {
						nextFrame = 0;
					}
				} while (time > dur);
				
				w = (time - frameTime) / durations[frame];
			}
			
			_frame0 = frame;
			_frame1 = nextFrame;
			_blendWeight = w;
		}
	}
}