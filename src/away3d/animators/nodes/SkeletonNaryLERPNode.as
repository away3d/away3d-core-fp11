package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.*;
	import away3d.animators.states.*;
	
	use namespace arcane;
	
	/**
	 * A skeleton animation node that uses an n-dimensional array of animation node inputs to blend a lineraly interpolated output of a skeleton pose.
	 */
	public class SkeletonNaryLERPNode extends AnimationNodeBase
	{
		arcane var _inputs:Vector.<AnimationNodeBase> = new Vector.<AnimationNodeBase>();
		private var _numInputs:uint;
		
		public function get numInputs():uint
		{
			return _numInputs;
		}
		
		/**
		 * Creates a new <code>SkeletonNaryLERPNode</code> object.
		 */
		public function SkeletonNaryLERPNode()
		{
			_stateClass = SkeletonNaryLERPState;
		}
		
		/**
		 * Returns an integer representing the input index of the given skeleton animation node.
		 *
		 * @param input The skeleton animation node for with the input index is requested.
		 */
		public function getInputIndex(input:AnimationNodeBase):int
		{
			return _inputs.indexOf(input);
		}
		
		/**
		 * Returns the skeleton animation node object that resides at the given input index.
		 *
		 * @param index The input index for which the skeleton animation node is requested.
		 */
		public function getInputAt(index:uint):AnimationNodeBase
		{
			return _inputs[index];
		}
		
		/**
		 * Adds a new skeleton animation node input to the animation node.
		 */
		public function addInput(input:AnimationNodeBase):void
		{
			_inputs[_numInputs++] = input;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):SkeletonNaryLERPState
		{
			return animator.getAnimationState(this) as SkeletonNaryLERPState;
		}
	}
}
