package away3d.animators
{
	import away3d.arcane;
	import away3d.core.base.Object3D;
	import away3d.errors.AbstractMethodError;
	import away3d.animators.data.AnimationStateBase;

	import away3d.events.AnimatorEvent;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Timer;
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
		protected var _targets : Vector.<Object3D>;

		private var _broadcaster:Sprite = new Sprite();
		protected var _animationState : AnimationStateBase;
		private var _numTargets : uint;
		private var _isPlaying:Boolean;
		private var _startEvent:AnimatorEvent;
		private var _stopEvent:AnimatorEvent;
		private var _time : int;
//		private var _animationManager : AnimationManager;

		public function AnimatorBase()
		{
			_targets = new Vector.<Object3D>();
			start();
//			_animationManager = AnimationManager.getInstance();
		}

		private function notifyStart():void
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

		private function notifyStop():void
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
		 * The animation state on which this controller acts
		 */
		public function get animationState() : AnimationStateBase
		{
			return _animationState;
		}

		public function set animationState(value : AnimationStateBase) : void
		{
			_animationState = value;
		}

		/**
		 * Clones the current object.
		 * @return An exact duplicate of this object.
		 */
		public function clone() : AnimatorBase
		{
			throw new AbstractMethodError();
		}

		/**
		 * Updates the animation state.
		 * @param deltaTime The time step passed since the last update
		 * @param target The target on which to perform the animation
		 * @private
		 */
		arcane function updateAnimation(deltaTime : uint) : void
		{
			throw new AbstractMethodError();
		}

		arcane function addTarget(object : Object3D) : void
		{
			// if first target, add to manager so it can be updated.
//			if (_numTargets == 0) _animationManager.registerController(this);

			_targets[_numTargets++] = object;
		}


		arcane function removeTarget(object : Object3D) : void
		{
			_targets.splice(_targets.indexOf(object), 1);

			// if no targets triggered anymore, add to manager so it can be updated.
//			if (--_numTargets == 0) _animationManager.unregisterController(this);
		}

		protected function start():void
		{
			_time = getTimer();

			if (!_broadcaster.hasEventListener(Event.ENTER_FRAME))
				_broadcaster.addEventListener(Event.ENTER_FRAME, onEnterFrame);

			notifyStart();
		}

		private function onEnterFrame(event:Event = null):void
		{
			var time : int = getTimer();
			updateAnimation(getTimer() - _time);
			_time = time;
		}
	}
}