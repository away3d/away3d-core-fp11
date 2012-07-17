package away3d.animators.data
{
	/**
	 * Options for setting the animation mode of a vertex animator object.
	 * 
	 * @see away3d.aimators.VertexAnimator
	 */
	public class VertexAnimationMode
	{
		/**
		 * Animation mode that adds all outputs from active vertex animation state to form the current vertex animation pose.
		 */
		public static const ADDITIVE : String = "additive";
		
		/**
		 * Animation mode that picks the output from a single vertex animation state to form the current vertex animation pose.
		 */
		public static const ABSOLUTE : String = "absolute";
	}
}