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
	public class BlendingSkeletonAnimator extends AnimatorBase
	{
		private var _clips : Array;
		private var _tempAbsSequences : Vector.<SkeletonAnimationSequence>;
		private var _tempAddSequences : Vector.<SkeletonAnimationSequence>;
		private var _timeScale : Number = 1;
		private var _lerpNode : SkeletonNaryLERPNode;
		private var _mainNode : SkeletonTreeNode;
		private var _additiveNodes : Array;
		private var _activeAbsClips : Vector.<int>;
		private var _numActiveClips : uint;
		private var _blendWeights : Vector.<Number>;
		private var _updateRootPosition : Boolean = true;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function BlendingSkeletonAnimator()
		{
			_clips = [];
			_activeAbsClips = new Vector.<int>();
			_blendWeights = new Vector.<Number>();
			_additiveNodes = [];
		}

        public function get rootDelta() : Vector3D
        {
            return _mainNode? _mainNode.rootDelta : null;
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
		 * @inheritDoc
		 */
		override public function set animationState(value : AnimationStateBase) : void
		{
			var state : SkeletonAnimationState = SkeletonAnimationState(value);
			super.animationState = value;

			if (state.numJoints > 0) {
				if (!_lerpNode) initTree(state);
			}
		}

		private function initTree(state : SkeletonAnimationState) : void
		{
			_lerpNode = new SkeletonNaryLERPNode(state.numJoints);

			state.blendTree = _lerpNode;
//				sequences were added when there wasn't a state available
			_mainNode = _lerpNode;

			convertSequences();
		}

		private function convertSequences() : void
		{
			var len : uint;
			var i : uint;

			if (_tempAbsSequences) {
				len = _tempAbsSequences.length;
				for (i = 0; i < len; ++i)
					createLERPInput(_tempAbsSequences[i])
			}

			if (_tempAddSequences) {
				len = _tempAddSequences.length;
				for (i = 0; i < len; ++i)
					createAdditiveNode(_tempAddSequences[i]);
			}

			_tempAbsSequences = null;
			_tempAddSequences = null;
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
		 * The amount by which passed time should be scaled. Used to slow down or speed up animations.
		 */
		public function get timeScale() : Number
		{
			return _timeScale;
		}

		public function set timeScale(value : Number) : void
		{
			_timeScale = value;
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
			if (_mainNode) {
				createAdditiveNode(sequence);
			}
			else {
				_tempAddSequences ||= new Vector.<SkeletonAnimationSequence>();
				_tempAddSequences.push(sequence);
			}
		}

		private function createAdditiveNode(sequence : SkeletonAnimationSequence) : void
		{
			var node : SkeletonTimelineClipNode;
			var additive : SkeletonAdditiveNode;
			additive = new SkeletonAdditiveNode(SkeletonAnimationState(_animationState).numJoints);
			node = new SkeletonTimelineClipNode(SkeletonAnimationState(_animationState).numJoints);
			node.clip = sequence;
			_clips[sequence.name] = node;
			_additiveNodes[sequence.name] = additive;
			additive.differenceInput = node;
			additive.baseInput = _mainNode;
			_mainNode = additive;
			SkeletonAnimationState(_animationState).blendTree = _mainNode;
		}

		private function addAbsoluteSequence(sequence : SkeletonAnimationSequence) : void
		{
			_blendWeights[_blendWeights.length] = 0;

			if (_lerpNode) {
				createLERPInput(sequence);
			}
			else {
				_tempAbsSequences ||= new Vector.<SkeletonAnimationSequence>();
				_tempAbsSequences.push(sequence);
			}
		}

		private function createLERPInput(sequence : SkeletonAnimationSequence) : void
		{
			var node : SkeletonTimelineClipNode = new SkeletonTimelineClipNode(SkeletonAnimationState(_animationState).numJoints);
			_clips[sequence.name] = node;
			node.clip = sequence;
			_lerpNode.addInput(node);
		}

		/**
		 * @inheritDoc
		 */
		override public function clone() : AnimatorBase
		{
			var clone : SmoothSkeletonAnimator = new SmoothSkeletonAnimator();

			for each (var clip : SkeletonTimelineClipNode in _clips)
				clone.addSequence(clip.clip);

			return clone;
		}

		/**
		 * @inheritDoc
		 * @private
		 *
		 * todo: remove animationState reference, change target to something "IAnimatable" that provides the state?
		 */
		override arcane function updateAnimation(dt : uint) : void
		{
			var delta : Vector3D;

			if (!_mainNode && SkeletonAnimationState(_animationState).numJoints > 0)
				initTree(SkeletonAnimationState(_animationState));

			if (_mainNode && _numActiveClips > 0) {
				_mainNode.time += dt / _mainNode.duration * _timeScale;

				_animationState.invalidateState();
				_mainNode.updatePositionData();
				if (_updateRootPosition) {
					delta = _mainNode.rootDelta;
					var dist : Number = delta.length;
					var len : uint;

					if (dist > 0) {
						len = _targets.length;
						for (var i : uint = 0; i < len; ++i)
							_targets[i].translateLocal(delta, dist);
					}
				}
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
	}
}