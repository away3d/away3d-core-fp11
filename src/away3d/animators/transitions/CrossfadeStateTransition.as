package away3d.animators.transitions
{
	import away3d.animators.nodes.SkeletonBinaryLERPNode;
	import away3d.animators.transitions.StateTransitionBase;

	public class CrossfadeStateTransition extends StateTransitionBase
	{	
		public function CrossfadeStateTransition(blendSpeed:Number)
		{
			super();
			
			this.blendSpeed = blendSpeed;
			
			_rootNode = new SkeletonBinaryLERPNode();
		}
		
		
		override public function clone(object:StateTransitionBase = null):StateTransitionBase
        {
			var stateTransition:StateTransitionBase = object || new CrossfadeStateTransition(blendSpeed);
			super.clone(stateTransition);
			
			return stateTransition;
		}
	}
}
