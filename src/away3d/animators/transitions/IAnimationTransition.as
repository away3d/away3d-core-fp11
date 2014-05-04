package away3d.animators.transitions
{
	import away3d.animators.IAnimator;
	import away3d.animators.nodes.AnimationNodeBase;

	public interface IAnimationTransition
	{
		function getAnimationNode(animator:IAnimator, startNode:AnimationNodeBase, endNode:AnimationNodeBase, startTime:int):AnimationNodeBase
	}
}
