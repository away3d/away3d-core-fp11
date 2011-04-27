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

		/**
		 * @inheritDoc
		 */
		/*arcane override function applyState(state : AnimationStateBase, dt : uint) : void
		 {
		 super.applyState(state, dt);
		 updateFrames(_animationTimes[state]);

		 var animState : VertexAnimationState = VertexAnimationState(state);
		 var poses : Vector.<Geometry> = animState.poses;
		 var weights : Vector.<Number> = animState.weights;

		 poses[uint(0)] = _frames[_frame1];
		 poses[uint(1)] = _frames[_frame2];
		 weights[uint(0)] = 1 - _blendWeight;
		 weights[uint(1)] = _blendWeight;

		 state.invalidateState();
		 }     */
	}
}