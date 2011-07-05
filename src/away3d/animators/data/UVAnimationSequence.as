package away3d.animators.data
{
	import away3d.arcane;

	use namespace arcane;

	public class UVAnimationSequence extends AnimationSequenceBase
	{
		arcane var _frames : Vector.<UVAnimationFrame>;
		
		public function UVAnimationSequence(name:String)
		{
			super(name);
			
			_frames = new Vector.<UVAnimationFrame>();
		}
		
		
		arcane function addFrame(frame : UVAnimationFrame, duration : Number) : void
		{
			_totalDuration += duration;
			_frames.push(frame);
			_durations.push(duration);
		}
	}
}