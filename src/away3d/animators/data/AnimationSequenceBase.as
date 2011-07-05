package away3d.animators.data
{
	import away3d.arcane;
	import away3d.events.AnimatorEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;

	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * The AnimationSequenceBase provides an abstract base class for pre-animated animation clips.
	 *
	 * todo: support frame bounds
	 */
	public class AnimationSequenceBase extends NamedAssetBase implements IAsset
	{
		/**
		 * Indicates whether or not the animation sequence loops.
		 */
		public var looping : Boolean = true;

		protected var _rootDelta : Vector3D;
		arcane var _totalDuration : uint;
		arcane var _fixedFrameRate : Boolean = true;
		arcane var _durations : Vector.<uint>;

		private var _animationEvent : AnimatorEvent;

		/**
		 * Creates a new AnimationSequenceBase object.
		 * @param name The name of the animation clip. It will be used as the identifier by sequence controller classes.
		 */
		public function AnimationSequenceBase(name : String)
		{
			super(name);
			_durations = new Vector.<uint>();
			_rootDelta = new Vector3D();
			_animationEvent = new AnimatorEvent(AnimatorEvent.SEQUENCE_DONE, null, this);
		}
		
		
		public function get assetType() : String
		{
			return AssetType.ANIMATION;
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