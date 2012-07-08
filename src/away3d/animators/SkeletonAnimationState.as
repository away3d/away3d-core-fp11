package away3d.animators
{
	import away3d.arcane;
	import away3d.animators.nodes.*;
	import away3d.errors.*;
	
	use namespace arcane;
	
	/**
	 * @author robbateman
	 */
	public class SkeletonAnimationState extends AnimationStateBase implements IAnimationState
	{
		private var _skeletonAnimationSet:SkeletonAnimationSet;
		
		public function SkeletonAnimationState(rootNode:SkeletonNodeBase)
		{
			super(rootNode);
		}
		
		
		override public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			if (!(owner is SkeletonAnimationSet))
				throw new AnimationSetError("A skeleton animation state can only be added to a skeleton animation set");
			
			super.addOwner(owner, stateName);
						
			_skeletonAnimationSet = owner as SkeletonAnimationSet;
		}
	}
}
