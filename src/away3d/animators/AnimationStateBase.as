package away3d.animators
{
	import away3d.animators.nodes.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	
	/**
	 * Dispatched when a non-looping clip node inside an animation state reaches the end of its timeline.
	 * 
	 * @eventType away3d.events.AnimatorEvent
	 */
	[Event(name="playbackComplete",type="away3d.events.AnimationStateEvent")]
	
	/**
	 * Provides an abstract base class for state classes that hold animation node data for specific animation states.
	 *
	 * @see away3d.animators.AnimatorBase
	 */
	public class AnimationStateBase extends NamedAssetBase implements IAsset
	{
		private var _looping:Boolean = true;
		private var _rootNode:IAnimationNode;
		private var _owner:IAnimationSet;
		private var _stateName:String;
		
		/**
		 * Determines whether the contents of the animation state have looping characteristics enabled.
		 */
		public function get looping():Boolean
		{	
			return _looping;
		}
		
		public function set looping(value:Boolean):void
		{	
			if (_looping == value)
				return;
			
			_looping = value;
			
			_rootNode.looping = value;
		}
		
		/**
		 * Returns the root animation node used by the state for determining the output pose of the animation node data.
		 */
		public function get rootNode():IAnimationNode
		{	
			return _rootNode;
		}
		
		/**
		 * Returns the name of the state used for retrieval from inside its parent animation set object.
		 * 
		 * @see away3d.animators.AnimationSetBase
		 */
		public function get stateName():String
		{
			return _stateName;
		}
		
		/**
		 * Creates a new <code>AnimationSetBase</code> object.
		 * 
		 * @param rootNode The root animation node used by the state for determining the output pose of the animation node data.
		 */
		public function AnimationStateBase(rootNode:IAnimationNode)
		{
			_rootNode = rootNode;
			_rootNode.addEventListener(AnimationStateEvent.PLAYBACK_COMPLETE, onAnimationStateEvent);
		}
		
		/**
		 * Resets the configuration of the state to its default state.
		 * 
		 * @param time The absolute time (in milliseconds) of the animator's playhead.
		 */
		public function reset(time:int):void
		{
			_rootNode.reset(time);
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
			return AssetType.ANIMATION_STATE;
		}
		
		/**
		 * Used by the animation set on adding a state, defines the internal owner and state name
		 * properties of the state.
		 * 
		 * @private
		 */
		public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			_owner = owner;
			_stateName = stateName;
		}
		
		/**
		 * Event handler triggered by the root animation node on receiving an animation state event.
		 * 
		 * @private
		 */
		private function onAnimationStateEvent(event:AnimationStateEvent):void
		{
			dispatchEvent(event);
		}
	}
}
