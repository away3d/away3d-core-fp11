package away3d.animators.nodes
{
	import away3d.animators.*;
	import away3d.animators.states.*;
	
	/**
	 * A skeleton animation node that uses a difference input pose with a base input pose to blend a linearly interpolated output of a skeleton pose.
	 */
	public class SkeletonDifferenceNode extends AnimationNodeBase
	{
		/**
		 * Defines a base input node to use for the blended output.
		 */
		public var baseInput : AnimationNodeBase;
		
		/**
		 * Defines a difference input node to use for the blended output.
		 */
		public var differenceInput : AnimationNodeBase;
		
		/**
		 * Creates a new <code>SkeletonAdditiveNode</code> object.
		 */
		public function SkeletonDifferenceNode()
		{
			_stateClass = SkeletonDifferenceState;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):SkeletonDifferenceState
		{
			return animator.getAnimationState(this) as SkeletonDifferenceState;
		}
	}
}
