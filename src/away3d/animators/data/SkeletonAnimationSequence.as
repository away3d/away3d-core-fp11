package away3d.animators.data
{
	import away3d.arcane;

	import flash.geom.Vector3D;
	import away3d.animators.skeleton.SkeletonPose;

	use namespace arcane;

	/**
	 * A sequence for a SkeletonAnimationSequence type of animation. A sequence is a pre-animated clip consisting out of a number of frames.
	 *
	 * @see away3d.core.animation.skeleton.SkeletonSequenceController
	 */
	public class SkeletonAnimationSequence extends AnimationSequenceBase
	{
		arcane var _frames : Vector.<SkeletonPose>;
		arcane var _additive : Boolean;
		private var _rootPos : Vector3D;

		/**
		 * Creates a new SkeletonAnimationSequence object.
		 * @param name The name of the animation clip. It will be used as the identifier by sequence controller classes.
		 */
		public function SkeletonAnimationSequence(name : String, additive : Boolean = false)
		{
			super(name);
			_additive = additive;
			_frames = new Vector.<SkeletonPose>();
			_rootPos = new Vector3D();
		}

		/**
		 * Adds a frame with a given duration to the sequence.
		 * @param frame The SkeletonPose for this frame of the sequence
		 * @param duration milliseconds to show this frame of the sequence
		 */
		arcane function addFrame(frame : SkeletonPose, duration : uint) : void
		{
			_totalDuration += duration;
			_frames.push(frame);
			_durations.push(duration);
		}
	}
}