package away3d.animators.nodes
{
	import away3d.animators.data.*;
	
	/**
	 * @author robbateman
	 */
	public interface IUVAnimationNode extends IAnimationNode
	{
		function get currentUVFrame() : UVAnimationFrame;
		
		function get nextUVFrame() : UVAnimationFrame;
		
		function get blendWeight() : Number;
	}
}
