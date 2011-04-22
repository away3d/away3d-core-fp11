package away3d.animators
{
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.animators.data.VertexAnimationSequence;
	import away3d.animators.data.VertexAnimationState;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class VertexAnimator extends AnimatorBase
	{
		private var _sequences : Array;
		private var _activeSequence : VertexAnimationSequence;
		private var _absoluteTime : Number;
		private var _frame1 : uint;
		private var _frame2 : uint;
		private var _blendWeight : Number;
		private var _target : VertexAnimationState;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function VertexAnimator(target : VertexAnimationState)
		{
			super();
			_sequences = [];
			_target = target;
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
			updateFrames(_absoluteTime);

			poses[uint(0)] = _activeSequence._frames[_frame1];
			poses[uint(1)] = _activeSequence._frames[_frame2];
			weights[uint(0)] = 1 - (weights[uint(1)] = _blendWeight);

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

		/**
		 * Calculates the frames between which to interpolate.
		 * @param time The absolute time of the animation sequence.
		 */
		private function updateFrames(time : Number) : void
		{
			var lastFrame : uint, frame : uint, nextFrame : uint;
			var dur : uint, frameTime : uint;
			var frames : Vector.<Geometry> = _activeSequence._frames;
			var durations : Vector.<uint> = _activeSequence._durations;
			var duration : uint = _activeSequence._totalDuration;
			var looping : Boolean = _activeSequence.looping;
			var numFrames : uint = frames.length;
			var w : Number;

			if (numFrames == 0) return;

			if ((time > duration || time < 0) && looping) {
				time %= duration;
				if (time < 0) time += duration;
			}

			lastFrame = numFrames - 1;

			if (!looping && time > duration - durations[lastFrame]) {
				_activeSequence.notifyPlaybackComplete();
				frame = lastFrame;
				nextFrame = lastFrame;
				w = 0;
			}
			else if (_activeSequence._fixedFrameRate) {
				var t : Number = time/duration * numFrames;
				frame = t;
				nextFrame = frame + 1;
				w = t - frame;
				if (frame == numFrames) frame = 0;
				if (nextFrame >= numFrames) nextFrame -= numFrames;
			}
			else {
				do {
					frameTime = dur;
					dur += durations[frame];
					frame = nextFrame;
					if (++nextFrame == numFrames) {
						nextFrame = 0;
					}
				} while (time > dur);

				w = (time - frameTime) / durations[frame];
			}

			_frame1 = frame;
			_frame2 = nextFrame;
			_blendWeight = w;
		}
	}
}