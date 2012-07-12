package away3d.animators
{
	import away3d.arcane;
	import away3d.animators.nodes.*;
	import away3d.errors.*;
	
	use namespace arcane;
	
	/**
	 * The animation state class used by skeleton-based animation data sets to store animation node data.
	 * 
	 * @see away3d.animators.SkeletonAnimator
	 * @see away3d.animators.SkeletonAnimationSet
	 */
	public class SkeletonAnimationState extends AnimationStateBase implements IAnimationState
	{
		private var _skeletonAnimationSet:SkeletonAnimationSet;
		
		/**
		 * Creates a new <code>SkeletonAnimationState</code> object.
		 * 
		 * @param rootNode Sets the root animation node used by the state for determining the output pose of the animation node data.
		 */
		public function SkeletonAnimationState(rootNode:ISkeletonAnimationNode)
		{
			super(rootNode);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			if (!(owner is SkeletonAnimationSet))
				throw new AnimationSetError("A skeleton animation state can only be added to a skeleton animation set");
			
			super.addOwner(owner, stateName);
						
			_skeletonAnimationSet = owner as SkeletonAnimationSet;
		}
	}
}
