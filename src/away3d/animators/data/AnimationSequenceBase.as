package away3d.animators.data
{
	import away3d.arcane;
	import away3d.events.AnimationEvent;
	import away3d.loading.IResource;

	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * The AnimationSequenceBase provides an abstract base class for pre-animated animation clips.
	 *
	 * todo: support frame bounds
	 */
	public class AnimationSequenceBase extends EventDispatcher implements IResource
	{
		/**
		 * Indicates whether or not the animation sequence loops.
		 */
		public var looping : Boolean = true;

		protected var _name : String;

		protected var _rootDelta : Vector3D;
		arcane var _totalDuration : uint;
		arcane var _fixedFrameRate : Boolean = true;
		arcane var _durations : Vector.<uint>;

		private var _animationEvent : AnimationEvent;

		/**
		 * Creates a new AnimationSequenceBase object.
		 * @param name The name of the animation clip. It will be used as the identifier by sequence controller classes.
		 */
		public function AnimationSequenceBase(name : String)
		{
			_name = name;
			_durations = new Vector.<uint>();
			_rootDelta = new Vector3D();
			_animationEvent = new AnimationEvent(AnimationEvent.PLAYBACK_ENDED, this);
		}

		/**
		 * Indicates whether the frames have a uniform duration, or whether frames are spread out unevenly over the timeline. Defaults to true.
		 */
		public function get fixedFrameRate() : Boolean
		{
			return _fixedFrameRate;
		}

		public function set fixedFrameRate(value : Boolean) : void
		{
			_fixedFrameRate = value;
		}

		/**
		 * The offset by which the root has moved. Typically, root movement in the animation clip is ignored and instead applied to the scene graph position.
		 */
		public function get rootDelta() : Vector3D
		{
			return _rootDelta;
		}

		/**
		 * The name of the animation clip. It will be used as the identifier by sequence controller classes.
		 */
		public function get name() : String
		{
			return _name;
		}

		public function set name(value : String) : void
		{
			_name = value;
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose(deep : Boolean) : void
		{
		}

		/**
		 * The duration of the animation sequence.
		 */
		public function get duration() : uint
		{
			return _totalDuration;
		}

		arcane function notifyPlaybackComplete() : void
		{
			dispatchEvent(_animationEvent);
		}
	}
}