package away3d.animators.nodes
{
	import away3d.animators.*;
	import away3d.animators.states.*;
	
	/**
	 * A skeleton animation node that uses four directional input poses with an input direction to blend a linearly interpolated output of a skeleton pose.
	 */
	public class SkeletonDirectionalNode extends AnimationNodeBase
	{
		/**
		 * Defines the forward configured input node to use for the blended output.
		 */
		public var forward : AnimationNodeBase;
		
		/**
		 * Defines the backwards configured input node to use for the blended output.
		 */
		public var backward : AnimationNodeBase;
		
		/**
		 * Defines the left configured input node to use for the blended output.
		 */
		public var left : AnimationNodeBase;
		
		/**
		 * Defines the right configured input node to use for the blended output.
		 */
		public var right : AnimationNodeBase;
		
		public function SkeletonDirectionalNode()
		{
			_stateClass = SkeletonDirectionalState;
		}
				
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):SkeletonDirectionalState
		{
			return animator.getAnimationState(this) as SkeletonDirectionalState;
		}
		
	}
}
