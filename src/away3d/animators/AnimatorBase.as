package away3d.animators
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import away3d.arcane;
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.animators.states.AnimationStateBase;
	import away3d.animators.states.IAnimationState;
	import away3d.entities.Mesh;
	import away3d.events.AnimatorEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	
	use namespace arcane;
	
	/**
	 * Dispatched when playback of an animation inside the animator object starts.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	[Event(name="start", type="away3d.events.AnimatorEvent")]
	
	/**
	 * Dispatched when playback of an animation inside the animator object stops.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	[Event(name="stop", type="away3d.events.AnimatorEvent")]
	
	/**
	 * Dispatched when playback of an animation reaches the end of an animation.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	[Event(name="cycle_complete", type="away3d.events.AnimatorEvent")]
	
	/**
	 * Provides an abstract base class for animator classes that control animation output from a data set subtype of <code>AnimationSetBase</code>.
	 *
	 * @see away3d.animators.AnimationSetBase
	 */
	public class AnimatorBase extends NamedAssetBase implements IAsset
	{
		private var _broadcaster:Sprite = new Sprite();
		private var _isPlaying:Boolean;
		private var _autoUpdate:Boolean = true;
		private var _startEvent:AnimatorEvent;
		private var _stopEvent:AnimatorEvent;
		private var _cycleEvent:AnimatorEvent;
		private var _time:int;
		private var _playbackSpeed:Number = 1;
		
		protected var _animationSet:IAnimationSet;
		protected var _owners:Vector.<Mesh> = new Vector.<Mesh>();
		protected var _activeNode:AnimationNodeBase;
		protected var _activeState:IAnimationState;
		protected var _activeAnimationName:String;
		protected var _absoluteTime:Number = 0;
		private var _animationStates:Dictionary = new Dictionary(true);
		
		/**
		 * Enables translation of the animated mesh from data returned per frame via the positionDelta property of the active animation node. Defaults to true.
		 *
		 * @see away3d.animators.states.IAnimationState#positionDelta
		 */
		public var updatePosition:Boolean = true;
		
		public function getAnimationState(node:AnimationNodeBase):AnimationStateBase
		{
			var className:Class = node.stateClass;
			
			return _animationStates[node] ||= new className(this, node);
		}
		
		public function getAnimationStateByName(name:String):AnimationStateBase
		{
			return getAnimationState(_animationSet.getAnimation(name));
		}
		
		/**
		 * Returns the internal absolute time of the animator, calculated by the current time and the playback speed.
		 *
		 * @see #time
		 * @see #playbackSpeed
		 */
		public function get absoluteTime():Number
		{
			return _absoluteTime;
		}
		
		/**
		 * Returns the animation data set in use by the animator.
		 */
		public function get animationSet():IAnimationSet
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
		 * Returns the current active animation node.
		 */
		public function get activeAnimation():AnimationNodeBase
		{
			return _animationSet.getAnimation(_activeAnimationName);
		}
		
		/**
		 * Returns the current active animation node.
		 */
		public function get activeAnimationName():String
		{
			return _activeAnimationName;
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
		 * Sets the animation phase of the current active state's animation clip(s).
		 *
		 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
		 */
		public function phase(value:Number):void
		{
			_activeState.phase(value);
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
		public function get playbackSpeed():Number
		{
			return _playbackSpeed;
		}
		
		public function set playbackSpeed(value:Number):void
		{
			_playbackSpeed = value;
		}
		
		/**
		 * Resumes the automatic playback clock controling the active state of the animator.
		 */
		public function start():void
		{
			if (_isPlaying || !_autoUpdate)
				return;
			
			_time = _absoluteTime = getTimer();
			
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
		public function stop():void
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
		public function update(time:int):void
		{
			var dt:Number = (time - _time)*playbackSpeed;
			
			updateDeltaTime(dt);
			
			_time = time;
		}
		
		public function reset(name:String, offset:Number = 0):void
		{
			getAnimationState(_animationSet.getAnimation(name)).offset(offset + _absoluteTime);
		}
		
		/**
		 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
		 *
		 * @private
		 */
		public function addOwner(mesh:Mesh):void
		{
			_owners.push(mesh);
		}
		
		/**
		 * Used by the mesh object from which the animator is removed, unregisters the owner for internal use.
		 *
		 * @private
		 */
		public function removeOwner(mesh:Mesh):void
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
			_absoluteTime += dt;
			
			_activeState.update(_absoluteTime);
			
			if (updatePosition)
				applyPositionDelta();
		}
		
		/**
		 * Enter frame event handler for automatically updating the active state of the animator.
		 */
		private function onEnterFrame(event:Event = null):void
		{
			update(getTimer());
		}
		
		private function applyPositionDelta():void
		{
			var delta:Vector3D = _activeState.positionDelta;
			var dist:Number = delta.length;
			var len:uint;
			if (dist > 0) {
				len = _owners.length;
				for (var i:uint = 0; i < len; ++i)
					_owners[i].translateLocal(delta, dist);
			}
		}
		
		/**
		 *  for internal use.
		 *
		 * @private
		 */
		public function dispatchCycleEvent():void
		{
			if (hasEventListener(AnimatorEvent.CYCLE_COMPLETE))
				dispatchEvent(_cycleEvent || (_cycleEvent = new AnimatorEvent(AnimatorEvent.CYCLE_COMPLETE, this)));
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function get assetType():String
		{
			return AssetType.ANIMATOR;
		}
	}
}
