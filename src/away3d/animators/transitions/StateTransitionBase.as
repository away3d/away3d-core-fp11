package away3d.animators.transitions
{
	import away3d.animators.nodes.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	
	
	public class StateTransitionBase extends NamedAssetBase implements IAsset
	{
		private var _stateTransitionComplete:StateTransitionEvent;
		private var _blendWeight:Number;
		
		protected var _rootNode:SkeletonBinaryLERPNode;
		
		public var startTime:Number = 0;
		
		public var blendSpeed:Number = 0.5;
		
		public function get rootNode():SkeletonBinaryLERPNode
		{
			return _rootNode;
		}
		
		public function get blendWeight():Number
		{
			return _blendWeight;
		}
		
		public function set blendWeight(value:Number):void
		{
			if (_blendWeight == value)
				return;
			
			_blendWeight = value;
			
			_rootNode.blendWeight = value;
		}
		
		public function get startNode():ISkeletonAnimationNode
		{
			return _rootNode.inputA;
		}
		
		public function set startNode(value:ISkeletonAnimationNode):void
		{
			if (_rootNode.inputA == value)
				return;
			
			_rootNode.inputA = value;
		}
		
		
		public function get endNode():ISkeletonAnimationNode
		{
			return _rootNode.inputB;
		}
		
		public function set endNode(value:ISkeletonAnimationNode):void
		{
			if (_rootNode.inputB == value)
				return;
			
			_rootNode.inputB = value;
		}
		
		public function get assetType():String
		{
			return AssetType.STATE_TRANSITION;
		}
				
		public function StateTransitionBase()
		{
			super();
		}
		
		public function update(time:Number):void
		{
			_blendWeight = _rootNode.blendWeight = Math.abs(time - startTime)/(1000*blendSpeed);
			
			_rootNode.update(time);
			
			if (_blendWeight >= 1) {
				_blendWeight = 1;
				dispatchEvent(_stateTransitionComplete || (_stateTransitionComplete = new StateTransitionEvent(StateTransitionEvent.TRANSITION_COMPLETE)));
			}
		}
		
		public function dispose():void
		{
		}
		
		public function clone(object:StateTransitionBase = null):StateTransitionBase
        {
			var stateTransition:StateTransitionBase = object || new StateTransitionBase();
			stateTransition.startTime = startTime;
			stateTransition.blendSpeed = blendSpeed;
			stateTransition.startNode = startNode;
			stateTransition.endNode = endNode;
			stateTransition.rootNode.blendWeight = _rootNode.blendWeight;
			
			return stateTransition;
		}
	}
}
