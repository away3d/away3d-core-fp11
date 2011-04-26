package away3d.animators
{
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.SkeletonTimelineClipNode;
	import away3d.animators.skeleton.SkeletonTreeNode;
	import away3d.arcane;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class SkeletonAnimator extends SkeletonAnimatorBase
	{
		private var _sequences : Array;
		private var _clipNode : SkeletonTimelineClipNode;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function SkeletonAnimator(target : SkeletonAnimationState)
		{
			super(target);
			_sequences = [];
		}


		override protected function createBlendTree() : SkeletonTreeNode
		{
			return new SkeletonTimelineClipNode(_target.numJoints)
		}

		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(sequenceName : String) : void
		{
			_clipNode.clip = _sequences[sequenceName];

			if (!_clipNode.clip)
				throw new Error("Clip not found!");

			_clipNode.time = 0;

			start();
		}

		/**
		 * Adds a sequence to the controller.
		 */
		public function addSequence(sequence : SkeletonAnimationSequence) : void
		{
			_sequences[sequence.name] = sequence;
		}

		/**
		 * @inheritDoc
		 * @private
		 */
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			_clipNode.time += scaledDT / _clipNode.clip.duration;
			super.updateAnimation(realDT, scaledDT);
		}

		/**
		 * Retrieves a sequence with a given name.
		 * @private
		 */
		/*arcane function getSequence(sequenceName : String) : AnimationSequenceBase
		 {
		 return _sequences[sequenceName];
		 } */
	}
}