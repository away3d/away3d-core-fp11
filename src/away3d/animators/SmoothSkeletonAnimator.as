package away3d.animators
{
	import away3d.arcane;

	import flash.geom.Vector3D;
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
	public class SmoothSkeletonAnimator extends AnimatorBase
	{
		private var _clips : Array;
		private var _tempSequences : Vector.<SkeletonAnimationSequence>;
		private var _activeClipIndex : int = -1;
		private var _sequenceAbsent : String;
		private var _timeScale : Number = 1;
		private var _fadeOutClips : Vector.<int>;
		private var _fadeOutSpeeds : Vector.<Number>;
		private var _lerpNode : SkeletonNaryLERPNode;
		private var _crossFadeTime : Number;
		private var _mainWeight : Number = 1;
		private var _updateRootPosition : Boolean = true;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function SmoothSkeletonAnimator()
		{
			_clips = [];
			_fadeOutClips = new Vector.<int>();
			_fadeOutSpeeds = new Vector.<Number>();
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
			if (!_lerpNode) {
				_lerpNode = new SkeletonNaryLERPNode(state.numJoints);
				state.blendTree = _lerpNode;
				// sequences were added when there wasn't a state available
				if (_tempSequences) convertSequences();
			}
		}

		private function convertSequences() : void
		{
			var len : uint = _tempSequences.length;
			var seq : SkeletonAnimationSequence;
			var node : SkeletonTimelineClipNode;

			for (var i : uint = 0; i < len; ++i) {
				seq = _tempSequences[i];
				node = new SkeletonTimelineClipNode(SkeletonAnimationState(_animationState).numJoints);
				_clips[seq.name] = node;
				node.clip = seq;
				_lerpNode.addInput(node);
			}

			_tempSequences = null;
		}

		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(sequenceName : String, crossFadeTime : Number = 0) : void
		{
			var clip : SkeletonTimelineClipNode;

			_crossFadeTime = crossFadeTime;

			if (_activeClipIndex != -1) {
				_fadeOutClips.push(_activeClipIndex);
				// diminish per second
				_fadeOutSpeeds.push(_mainWeight / crossFadeTime / 1000);
			}

			if (_lerpNode) {
				clip = _clips[sequenceName];
				clip.reset();
				if (clip && clip.duration > 0) {
					_activeClipIndex = _lerpNode.getInputIndex(clip);
					var i : int = _fadeOutClips.indexOf(_activeClipIndex);
					if (i != -1) {
						_fadeOutClips.splice(i, 1);
						_fadeOutSpeeds.splice(i, 1);
					}
				}
			}

			if (_activeClipIndex == -1) {
				_sequenceAbsent = sequenceName;
			}
			else {
				_sequenceAbsent = null;
//				_lerpNode.time = 0;
			}
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
		 */
		public function addSequence(sequence : SkeletonAnimationSequence) : void
		{
			var node : SkeletonTimelineClipNode;
			if (_lerpNode) {
				node = new SkeletonTimelineClipNode(SkeletonAnimationState(_animationState).numJoints);
				_clips[sequence.name] = node;
				node.clip = sequence;
				_lerpNode.addInput(node);
			}
			else {
//				_clips[sequence.name] = sequence;
				_tempSequences ||= new Vector.<SkeletonAnimationSequence>();
				_tempSequences.push(sequence);
			}
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
			var blendTree : SkeletonTreeNode;
			var delta : Vector3D;

			// keep trying to play
			if (_sequenceAbsent)
				play(_sequenceAbsent, _crossFadeTime);

			if (_activeClipIndex != -1) {
				updateWeights(dt);

				blendTree = SkeletonAnimationState(_animationState).blendTree;

				_lerpNode.time += dt / _lerpNode.duration * _timeScale;

				_animationState.invalidateState();
				blendTree.updatePositionData();

				if (_updateRootPosition) {
					delta = blendTree.rootDelta;
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

		private function updateWeights(dt : Number) : void
		{
			var weight : Number;
			var len : uint = _fadeOutClips.length;
			var weights : Vector.<Number> = _lerpNode.blendWeights;
			var total : Number = 0;
			var speed : Number;
			var index : uint;

			for (var i : uint = 0; i < len;) {
				index = _fadeOutClips[i];
				speed = _fadeOutSpeeds[i] * dt;
				weight = weights[index] - speed;
				if (weight <= 0) {
					weight = 0;
					_fadeOutClips.splice(i, 1);
					_fadeOutSpeeds.splice(i, 1);
					--len;
				}
				else {
					++i;
				}
				weights[index] = weight;
				total += weight;
			}
			weights[_activeClipIndex] = _mainWeight = 1 - total;
			_lerpNode.updateWeights(weights);
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