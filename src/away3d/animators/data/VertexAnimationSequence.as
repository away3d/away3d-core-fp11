package away3d.animators.data
{
	import away3d.arcane;
	import away3d.core.base.Geometry;

	use namespace arcane;

	/**
	 * A sequence for a VertexAnimation type of animation. A sequence is a pre-animated clip consisting out of a number of frames.
	 */
	public class VertexAnimationSequence extends AnimationSequenceBase
	{
		public var _frames : Vector.<Geometry>;

		/**
		 * Creates a new VertexAnimationSequence object.
		 * @param name The name of the animation clip. It will be used as the identifier by sequence controller classes.
		 */
		public function VertexAnimationSequence(name : String)
		{
			super(name);
			_frames = new Vector.<Geometry>();
		}

		/**
		 * Adds a frame with a given duration to the sequence.
		 * @param geometry The Geometry for this frame of the sequence
		 * @param duration milliseconds to show this frame of the sequence
		 */
		arcane function addFrame(geometry : Geometry, duration : uint) : void
		{
			_totalDuration += duration;
			_frames.push(geometry);
			_durations.push(duration);
		}
	}
}