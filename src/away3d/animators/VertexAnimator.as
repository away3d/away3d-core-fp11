package away3d.animators
{
	import away3d.animators.data.VertexAnimationSequence;
	import away3d.animators.data.VertexAnimationState;
	import away3d.animators.utils.TimelineUtil;
	import away3d.arcane;
	import away3d.core.base.Geometry;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class VertexAnimator extends AnimatorBase
	{
		private var _sequences : Array;
		private var _activeSequence : VertexAnimationSequence;
		private var _absoluteTime : Number;
		private var _target : VertexAnimationState;
		private var _tlUtil : TimelineUtil;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function VertexAnimator(target : VertexAnimationState)
		{
			super();
			_sequences = [];
			_target = target;
			_tlUtil = new TimelineUtil();
		}

		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(sequenceName : String) : void
		{
			_activeSequence = _sequences[sequenceName];
			if (!_activeSequence)
				throw new Error("Clip not found!");

			reset();
			start();
		}

		private function reset() : void
		{
			_absoluteTime = 0;
		}

		/**
		 * Adds a sequence to the controller.
		 */
		public function addSequence(sequence : VertexAnimationSequence) : void
		{
			_sequences[sequence.name] = sequence;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			var poses : Vector.<Geometry> = _target.poses;
			var weights : Vector.<Number> = _target.weights;

			_absoluteTime += scaledDT;
			_tlUtil.updateFrames(_absoluteTime, _activeSequence);

			poses[uint(0)] = _activeSequence._frames[_tlUtil.frame0];
			poses[uint(1)] = _activeSequence._frames[_tlUtil.frame1];
			weights[uint(0)] = 1 - (weights[uint(1)] = _tlUtil.blendWeight);

			_target.invalidateState();
		}

		/**
		 * Retrieves a sequence with a given name.
		 * @private
		 */
		arcane function getSequence(sequenceName : String) : VertexAnimationSequence
		{
			return _sequences[sequenceName];
		}


	}
}