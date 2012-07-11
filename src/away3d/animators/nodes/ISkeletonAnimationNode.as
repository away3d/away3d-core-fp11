package away3d.animators.nodes
{
	import away3d.animators.skeleton.*;
	
	/**
	 * @author robbateman
	 */
	public interface ISkeletonAnimationNode extends IAnimationNode
	{
		function getSkeletonPose(skeleton:Skeleton):SkeletonPose;
		
	}
}
