package away3d.animators.transitions
{
	import away3d.animators.*;
	import away3d.animators.states.*;
	import away3d.events.*;
	
	/**
	 *
	 */
	public class CrossfadeTransitionState extends SkeletonBinaryLERPState
	{
		private var _crossfadeTransitionNode:CrossfadeTransitionNode;
		private var _animationStateTransitionComplete:AnimationStateEvent;
		
		function CrossfadeTransitionState(animator:AnimatorBase, skeletonAnimationNode:CrossfadeTransitionNode)
		{
			super(animator, skeletonAnimationNode);
			
			_crossfadeTransitionNode = skeletonAnimationNode;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time:int):void
		{
			blendWeight = Math.abs(time - _crossfadeTransitionNode.startBlend)/(1000*_crossfadeTransitionNode.blendSpeed);
			
			if (blendWeight >= 1) {
				blendWeight = 1;
				_crossfadeTransitionNode.dispatchEvent(_animationStateTransitionComplete ||= new AnimationStateEvent(AnimationStateEvent.TRANSITION_COMPLETE, _animator, this, _crossfadeTransitionNode));
			}
			
			super.updateTime(time);
		}
	}
}
