package away3d.animators
{
	import away3d.arcane;

	import flash.geom.Vector3D;
	import away3d.animators.skeleton.SkeletonAdditiveNode;
	import away3d.animators.skeleton.SkeletonClipNodeBase;
	import away3d.animators.skeleton.SkeletonNaryLERPNode;
	import away3d.animators.skeleton.SkeletonTimelineClipNode;
	import away3d.animators.skeleton.SkeletonTreeNode;
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.data.AnimationSequenceBase;
	import away3d.animators.data.AnimationStateBase;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class BlendingSkeletonAnimator extends SkeletonAnimatorBase
	{
		private var _clips : Array;
		private var _lerpNode : SkeletonNaryLERPNode;
		private var _mainNode : SkeletonTreeNode;
		private var _additiveNodes : Array;
		private var _activeAbsClips : Vector.<int>;
		private var _numActiveClips : uint;
		private var _blendWeights : Vector.<Number>;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function BlendingSkeletonAnimator(target : SkeletonAnimationState)
		{
			super(target);
			_clips = [];
			_activeAbsClips = new Vector.<int>();
			_blendWeights = new Vector.<Number>();
			_additiveNodes = [];
		}

		override protected function createBlendTree() : SkeletonTreeNode
		{
			_lerpNode = new SkeletonNaryLERPNode();


//			mainNode also necessary since might be different from lerpNode when using additive blending
			_mainNode = _lerpNode;
			return _lerpNode;
		}

		public function setWeight(clipName : String, weight : Number) : void
		{
			if (weight > 1) weight = 1;
			else if (weight < 0) weight = 0;

			var clip : SkeletonClipNodeBase = _clips[clipName];

			if (!clip) return;

			if (clip.clip._additive) {
				SkeletonAdditiveNode(_additiveNodes[clipName]).blendWeight = weight;
			} else {
				setLERPWeightFor(clip, weight);
			}
		}

		private function setLERPWeightFor(clip : SkeletonClipNodeBase, weight : Number) : void
		{
			var inputIndex : uint = _lerpNode.getInputIndex(clip);
			var total : Number = 0;
			var i : int, lerpIndex : int;
			var realWeights : Vector.<Number> = _lerpNode.blendWeights;

			lerpIndex = _activeAbsClips.indexOf(inputIndex);

			_blendWeights[inputIndex] = weight;

			if (weight == 0) {
				// remove from active clips if weight = 0;
				realWeights[lerpIndex] = 0;
				if (lerpIndex >= 0) {
					// remove item (faster than splice)
					_activeAbsClips[lerpIndex] = _activeAbsClips[--_numActiveClips];
					_activeAbsClips.pop();
				}
			}
			else {
				if (lerpIndex < 0)
					_activeAbsClips[_numActiveClips++] = inputIndex;
			}

			// recalculate weights, so all add to 1
			for (i = 0; i < _numActiveClips; ++i) {
				lerpIndex = _activeAbsClips[i];
				total += _blendWeights[lerpIndex];
			}

			for (i = 0; i < _numActiveClips; ++i) {
				lerpIndex = _activeAbsClips[i];
				realWeights[lerpIndex] = _blendWeights[lerpIndex] / total;
			}

			_lerpNode.updateWeights(realWeights);
		}

		/**
		 * Adds a sequence to the controller.
		 * Differentiate between timeline based and phase? Or should be property of sequence?
		 */
		public function addSequence(sequence : SkeletonAnimationSequence) : void
		{
			if (sequence._additive) {
				addAdditiveSequence(sequence);
			}
			else {
				addAbsoluteSequence(sequence);
			}
		}

		private function addAdditiveSequence(sequence : SkeletonAnimationSequence) : void
		{
			var node : SkeletonTimelineClipNode;
			var additive : SkeletonAdditiveNode;
			additive = new SkeletonAdditiveNode();
			node = new SkeletonTimelineClipNode();
			node.clip = sequence;
			_clips[sequence.name] = node;
			_additiveNodes[sequence.name] = additive;
			additive.differenceInput = node;
			additive.baseInput = _mainNode;
			_mainNode = additive;
			_target.blendTree = _mainNode;
		}

		private function addAbsoluteSequence(sequence : SkeletonAnimationSequence) : void
		{
			_blendWeights[_blendWeights.length] = 0;

			var node : SkeletonTimelineClipNode = new SkeletonTimelineClipNode();
			_clips[sequence.name] = node;
			node.clip = sequence;
			_lerpNode.addInput(node);
		}

		/**
		 * @inheritDoc
		 * @private
		 */
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			if (_numActiveClips > 0) {
				_mainNode.time += scaledDT / _mainNode.duration;

				super.updateAnimation(realDT, scaledDT);
			}
		}

		/**
		 * Retrieves a sequence with a given name.
		 * @private
		 */
		arcane function getSequence(sequenceName : String) : AnimationSequenceBase
		{
			return _clips[sequenceName];
		}

		public function play() : void
		{
			start();
		}
	}
}