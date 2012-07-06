package away3d.animators
{
	import flash.events.EventDispatcher;
	import away3d.entities.Mesh;
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.events.AnimatorEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;

	use namespace arcane;

	/**
	 * AnimationControllerBase provides an abstract base class for classes that control a subtype of AnimationStateBase.
	 *
	 * @see away3d.core.animation.AnimationStateBase
	 *
	 */
	public class AnimatorBase extends EventDispatcher
	{
		private var _broadcaster : Sprite = new Sprite();
		private var _animationLibrary : IAnimationLibrary;
		private var _isPlaying : Boolean;
		private var _startEvent : AnimatorEvent;
		private var _stopEvent : AnimatorEvent;
		private var _time : int;
		private var _playbackSpeed : Number = 1;
		
		protected var _stateInvalid:Boolean;
		protected var _owners : Vector.<Mesh> = new Vector.<Mesh>();
		
		public function get animationLibrary() : IAnimationLibrary
		{
			return _animationLibrary;
		}
		
		public function AnimatorBase(animationLibrary:IAnimationLibrary)
		{
			_animationLibrary = animationLibrary;
//			start();
		}
		
		public function addOwner(mesh : Mesh) : void
		{
			_owners.push(mesh);
		}

		public function removeOwner(mesh : Mesh) : void
		{
			_owners.splice(_owners.indexOf(mesh), 1);
		}
		
		/**
		 * The amount by which passed time should be scaled. Used to slow down or speed up animations.
		 */
		public function get playbackSpeed() : Number
		{
			return _playbackSpeed;
		}

		public function set playbackSpeed(value : Number) : void
		{
			_playbackSpeed = value;
		}

		public function stop() : void
		{
			notifyStop();
		}

		private function notifyStart() : void
		{
			if (_isPlaying)
				return;

			_isPlaying = true;

			if (!hasEventListener(AnimatorEvent.START))
				return;

			if (!_startEvent)
				_startEvent = new AnimatorEvent(AnimatorEvent.START, this);

			dispatchEvent(_startEvent);
		}

		private function notifyStop() : void
		{
			if (!_isPlaying)
				return;

			_isPlaying = false;

			if (_broadcaster.hasEventListener(Event.ENTER_FRAME))
				_broadcaster.removeEventListener(Event.ENTER_FRAME, onEnterFrame);

			if (!hasEventListener(AnimatorEvent.STOP))
				return;

			if (!_stopEvent)
				_stopEvent = new AnimatorEvent(AnimatorEvent.STOP, this);

			dispatchEvent(_stopEvent);
		}

		/**
		 * Updates the animation state.
		 * @private
		 */
		protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Invalidates the state, so it needs to be updated next time it is requested.
		 */
		public function invalidateState() : void
		{
			_stateInvalid = true;
		}
		
		protected function start() : void
		{
			_time = getTimer();

			if (!_broadcaster.hasEventListener(Event.ENTER_FRAME))
				_broadcaster.addEventListener(Event.ENTER_FRAME, onEnterFrame);

			notifyStart();
		}

		private function onEnterFrame(event : Event = null) : void
		{
			var time : int = getTimer();
			var dt : Number = time-_time;
			updateAnimation(dt, dt*_playbackSpeed);
			_time = time;
		}
	}
}