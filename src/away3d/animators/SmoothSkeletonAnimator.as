package away3d.animators
{

	import away3d.animators.data.AnimationSequenceBase;
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.SkeletonNaryLERPNode;
	import away3d.animators.skeleton.SkeletonTimelineClipNode;
	import away3d.animators.skeleton.SkeletonTreeNode;
	import away3d.arcane;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class SmoothSkeletonAnimator extends SkeletonAnimatorBase
	{
		private var _clips : Array;
		private var _activeClipIndex : int = -1;
		private var _fadeOutClips : Vector.<int>;
		private var _fadeOutSpeeds : Vector.<Number>;
		private var _lerpNode : SkeletonNaryLERPNode;
		private var _crossFadeTime : Number;
		private var _mainWeight : Number = 1;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function SmoothSkeletonAnimator(target : SkeletonAnimationState)
		{
			super(target);
			_clips = [];
			_fadeOutClips = new Vector.<int>();
			_fadeOutSpeeds = new Vector.<Number>();
		}

		override protected function createBlendTree() : SkeletonTreeNode
		{
			_lerpNode = new SkeletonNaryLERPNode();
			return _lerpNode;
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

			if (_activeClipIndex == -1)
				throw new Error("Clip not found!");

			start();
		}

		public function hasSequence(sequenceName:String):Boolean
		{
			if(_clips[sequenceName] == null) return false;
			return true;
		}

		/**
		 * Adds a sequence to the controller.
		 */
		public function addSequence(sequence : SkeletonAnimationSequence) : void
		{
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
			var blendTree : SkeletonTreeNode;

			updateWeights(realDT);

			blendTree = _target.blendTree;

			_lerpNode.time += scaledDT / _lerpNode.duration;

			super.updateAnimation(realDT, scaledDT);

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
				else ++i;

				weights[index] = weight;
				total += weight;
			}
			weights[_activeClipIndex] = _mainWeight = 1 - total;
			_lerpNode.updateWeights(weights);
		}

		/**
		 * Retrieves a sequence with a given name.
		 */
		public function getSequence(sequenceName : String) : AnimationSequenceBase
		{
			return _clips[sequenceName].clip;
		}
	}
}