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
		private var _sequenceAbsent : String;
		private var _timeScale : Number = 1;
		private var _absoluteTime : uint;
		private var _frame1 : uint;
		private var _frame2 : uint;
		private var _blendWeight : Number;

		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function VertexAnimator()
		{
			super();
			_sequences = [];
		}

		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(sequenceName : String) : void
		{
			_activeSequence = _sequences[sequenceName];
			if (!_activeSequence) {
				_sequenceAbsent = sequenceName;
			}
			else {
				reset();
//				_activeSequence.timeScale = _timeScale;
				_sequenceAbsent = null;
			}
		}

		private function reset() : void
		{
			_absoluteTime = 0;
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
//			if (_activeSequence) _activeSequence.timeScale = value;
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
		override public function clone() : AnimatorBase
		{
			var clone : VertexAnimator = new VertexAnimator();

			clone._sequences = _sequences;
			clone._activeSequence = _activeSequence;
			clone._timeScale = _timeScale;

			return clone;
		}

		/**
		 * @inheritDoc
		 *
		 * todo: remove animationState reference, change target to something "IAnimatable" that provides the state?
		 */
		override arcane function updateAnimation(dt : uint) : void
		{
			var animState : VertexAnimationState = VertexAnimationState(_animationState);
			var poses : Vector.<Geometry> = animState.poses;
			var weights : Vector.<Number> = animState.weights;

			// keep trying to play
			if (_sequenceAbsent)
				play(_sequenceAbsent);

			if (_activeSequence) {
				_absoluteTime += dt*_timeScale;
				updateFrames(_absoluteTime);

				var dist : Number = _activeSequence.rootDelta.length;
				var len : uint;
				if (dist > 0) {
					len = _targets.length;
					for (var i : uint = 0; i < len; ++i)
						_targets[i].translateLocal(_activeSequence.rootDelta, dist);
				}

				poses[uint(0)] = _activeSequence._frames[_frame1];
				poses[uint(1)] = _activeSequence._frames[_frame2];
				weights[uint(0)] = 1 - (weights[uint(1)] = _blendWeight);

				animState.invalidateState();

				_animationState.invalidateState();
			}

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