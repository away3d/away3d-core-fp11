package away3d.animators
{
	import away3d.arcane;

	import flash.geom.Vector3D;
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
	public class SkeletonAnimator extends AnimatorBase
	{
		private var _sequences : Array;
		private var _activeClip : SkeletonTimelineClipNode;
		private var _sequenceAbsent : String;
		private var _timeScale : Number = 1;
		private var _updateRootPosition : Boolean = true;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function SkeletonAnimator()
		{
			_sequences = [];
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

			if (state.numJoints > 0)
				state.blendTree = (_activeClip ||= new SkeletonTimelineClipNode(state.numJoints));
		}

		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(sequenceName : String) : void
		{
			var state : SkeletonAnimationState = SkeletonAnimationState(_animationState);
			if (state && state.numJoints > 0) {
				_activeClip ||= new SkeletonTimelineClipNode(state.numJoints);
				_activeClip.clip = _sequences[sequenceName];
			}

			if (!(_activeClip && _activeClip.clip)) {
				_sequenceAbsent = sequenceName;
			}
			else {
				_sequenceAbsent = null;
				_activeClip.time = 0;
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
			_sequences[sequence.name] = sequence;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone() : AnimatorBase
		{
			var clone : SkeletonAnimator = new SkeletonAnimator();

			clone._sequences = _sequences;

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
			var blendTree: SkeletonTreeNode;
			var delta: Vector3D;

			// keep trying to play
			if (_sequenceAbsent)
				play(_sequenceAbsent);

			if (_activeClip && _activeClip.clip && _activeClip.clip.duration > 0) {
				blendTree = SkeletonAnimationState(_animationState).blendTree;
				_activeClip.time += dt/_activeClip.clip.duration*_timeScale;
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