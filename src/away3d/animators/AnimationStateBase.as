package away3d.animators
{
	import away3d.events.AnimationStateEvent;
	import away3d.animators.nodes.*;
	import away3d.library.assets.*;

	/**
	 * @author robbateman
	 */
	public class AnimationStateBase extends NamedAssetBase implements IAsset
	{
		private var _looping:Boolean = true;
		private var _rootNode:AnimationNodeBase;
		private var _owner:IAnimationSet;
		private var _stateName:String;
		
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
		
		public function get rootNode():AnimationNodeBase
		{	
			return _rootNode;
		}
		
		public function get stateName():String
		{
			return _stateName;
		}
		
		public function AnimationStateBase(rootNode:AnimationNodeBase)
		{
			_rootNode = rootNode;
			_rootNode.addEventListener(AnimationStateEvent.PLAYBACK_COMPLETE, onAnimationStateEvent);
		}
		
		public function reset(time:Number):void
		{
			_rootNode.reset(time);
		}
		
		public function dispose():void
		{
		}

		public function get assetType():String
		{
			return AssetType.ANIMATION_STATE;
		}
		
		public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			_owner = owner;
			_stateName = stateName;
		}
		
		private function onAnimationStateEvent(event:AnimationStateEvent):void
		{
			dispatchEvent(event);
		}
	}
}
