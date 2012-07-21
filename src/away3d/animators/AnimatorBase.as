package away3d.animators
{
	import away3d.arcane;
	import away3d.entities.*;
	import away3d.errors.*;
	import away3d.events.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;

	use namespace arcane;
	
		
	/**
	 * Dispatched when playback of an animation inside the animator object starts.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	[Event(name="start",type="away3d.events.AnimatorEvent")]
			
	/**
	 * Dispatched when playback of an animation inside the animator object stops.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	[Event(name="stop",type="away3d.events.AnimatorEvent")]
	
	/**
	 * Provides an abstract base class for animator classes that control animation output from a data set subtype of <code>AnimationSetBase</code>.
	 *
	 * @see away3d.animators.AnimationSetBase
	 */
	public class AnimatorBase extends EventDispatcher
	{
		private var _broadcaster : Sprite = new Sprite();
		private var _animationSet : IAnimationSet;
		private var _isPlaying : Boolean;
		private var _autoUpdate : Boolean = true;
		private var _startEvent : AnimatorEvent;
		private var _stopEvent : AnimatorEvent;
		private var _time : int;
		private var _playbackSpeed : Number = 1;
		
		protected var _owners : Vector.<Mesh> = new Vector.<Mesh>();
		protected var _activeState:IAnimationState;
		protected var _absoluteTime : Number = 0;
		
		/**
		 * Returns the animation data set in use by the animator.
		 */
		public function get animationSet() : IAnimationSet
		{
			return _animationSet;
		}
		
		/**
		 * Returns the current active animation state.
		 */
		public function get activeState():IAnimationState
		{
			return _activeState;
		}
		
		/**
		 * Determines whether the animators internal update mechanisms are active. Used in cases
		 * where manual updates are required either via the <code>time</code> property or <code>update()</code> method.
		 * Defaults to true.
		 *
		 * @see #time
		 * @see #update()
		 */
		public function get autoUpdate():Boolean
		{
			return _autoUpdate;
		}
		
		public function set autoUpdate(value:Boolean):void
		{
			if (_autoUpdate == value)
				return;
			
			_autoUpdate = value;
			
			if (_autoUpdate)
				start();
			else
				stop();
		}
		
		/**
		 * Gets and sets the internal time clock of the animator.
		 */
		public function get time():int
		{
			return _time;
		}
		
		public function set time(value:int):void
		{
			if (_time == value)
				return;
			
			update(value);
		}
		
		/**
		 * Creates a new <code>AnimatorBase</code> object.
		 *
		 * @param animationSet The animation data set to be used by the animator object.
		 */
		public function AnimatorBase(animationSet:IAnimationSet)
		{
			_animationSet = animationSet;
		}
		
		/**
		 * The amount by which passed time should be scaled. Used to slow down or speed up animations. Defaults to 1.
		 */
		public function get playbackSpeed() : Number
		{
			return _playbackSpeed;
		}

		public function set playbackSpeed(value : Number) : void
		{
			_playbackSpeed = value;
		}
		
		/**
		 * Resumes the automatic playback clock controling the active state of the animator.
		 */
		public function start() : void
		{
			_time = getTimer();
			
			if (_isPlaying || !_autoUpdate)
				return;
			
			_isPlaying = true;
			
			if (!_broadcaster.hasEventListener(Event.ENTER_FRAME))
				_broadcaster.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			if (!hasEventListener(AnimatorEvent.START))
				return;
			
			dispatchEvent(_startEvent ||= new AnimatorEvent(AnimatorEvent.START, this));
		}
		
		/**
		 * Pauses the automatic playback clock of the animator, in case manual updates are required via the
		 * <code>time</code> property or <code>update()</code> method.
		 *
		 * @see #time
		 * @see #update()
		 */
		public function stop() : void
		{
			if (!_isPlaying)
				return;

			_isPlaying = false;

			if (_broadcaster.hasEventListener(Event.ENTER_FRAME))
				_broadcaster.removeEventListener(Event.ENTER_FRAME, onEnterFrame);

			if (!hasEventListener(AnimatorEvent.STOP))
				return;
			
			dispatchEvent(_stopEvent || (_stopEvent = new AnimatorEvent(AnimatorEvent.STOP, this)));
		}
		
		/**
		 * Provides a way to manually update the active state of the animator when automatic
		 * updates are disabled.
		 *
		 * @see #stop()
		 * @see #autoUpdate
		 */
		public function update(time : int) : void
		{
			var dt : Number = (time-_time)*playbackSpeed;
			
			updateDeltaTime(dt);
			
			_time = time;
		}
		
		/**
		 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
		 *
		 * @private
		 */
		public function addOwner(mesh : Mesh) : void
		{
			_owners.push(mesh);
		}
		
		/**
		 * Used by the mesh object from which the animator is removed, unregisters the owner for internal use.
		 *
		 * @private
		 */
		public function removeOwner(mesh : Mesh) : void
		{
			_owners.splice(_owners.indexOf(mesh), 1);
		}
		
		/**
		 * Internal abstract method called when the time delta property of the animator's contents requires updating.
		 *
		 * @private
		 */
		protected function updateDeltaTime(dt:Number):void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Enter frame event handler for automatically updating the active state of the animator.
		 */
		private function onEnterFrame(event : Event = null) : void
		{
			update(getTimer());
		}
	}
}