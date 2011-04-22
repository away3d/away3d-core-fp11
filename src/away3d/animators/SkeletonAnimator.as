package away3d.animators
{
	import away3d.animators.data.AnimationSequenceBase;
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.SkeletonTimelineClipNode;
	import away3d.animators.skeleton.SkeletonTreeNode;
	import away3d.arcane;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class SkeletonAnimator extends AnimatorBase
	{
		private var _sequences : Array;
		private var _clipNode : SkeletonTimelineClipNode;
		private var _updateRootPosition : Boolean = true;
		private var _target : SkeletonAnimationState;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function SkeletonAnimator(target : SkeletonAnimationState)
		{
			_sequences = [];
			_target = target;
			_clipNode = new SkeletonTimelineClipNode(target.numJoints);
			target.blendTree = _clipNode;
		}

		public function get updateRootPosition() : Boolean
		{
			return _updateRootPosition;
		}

		public function set updateRootPosition(value : Boolean) : void
		{
			_updateRootPosition = value;
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
			var blendTree : SkeletonTreeNode = SkeletonAnimationState(_target).blendTree;
			_clipNode.time += scaledDT / _clipNode.clip.duration;
			_target.invalidateState();
			blendTree.updatePositionData();
			if (_updateRootPosition)
				_target.applyRootDelta();
		}

		/**
		 * Retrieves a sequence with a given name.
		 * @private
		 */
		arcane function getSequence(sequenceName : String) : AnimationSequenceBase
		{
			return _sequences[sequenceName];
		}
	}
}