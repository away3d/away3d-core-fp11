package away3d.animators.nodes
{
	import away3d.animators.data.*;
	
	/**
	 * Provides an interface for animation node classes that hold animation data for use in the skeleton animator class.
	 * 
	 * @see away3d.animators.SkeletonAnimator
	 */
	public interface ISkeletonAnimationNode extends IAnimationNode
	{
		/**
		 * Returns the output skeleton pose of the animation node.
		 */
		function getSkeletonPose(skeleton:Skeleton):SkeletonPose;
		
	}
}
