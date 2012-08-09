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
		private var _skeletonAnimationNode:CrossfadeTransitionNode;
		private var _animationStateTransitionComplete:AnimationStateEvent;
		
		function CrossfadeTransitionState(animator:IAnimator, skeletonAnimationNode:CrossfadeTransitionNode)
		{
			super(animator, skeletonAnimationNode);
			
			_skeletonAnimationNode = skeletonAnimationNode;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time : int) : void
		{
			blendWeight = Math.abs(time - _skeletonAnimationNode.startBlend)/(1000*_skeletonAnimationNode.blendSpeed);
			
			if (blendWeight >= 1) {
				blendWeight = 1;
				_skeletonAnimationNode.dispatchEvent(_animationStateTransitionComplete ||= new AnimationStateEvent(AnimationStateEvent.TRANSITION_COMPLETE, _animator, this, _skeletonAnimationNode));
			}
			
			super.updateTime(time);
		}
	}
}
