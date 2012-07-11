package away3d.animators.nodes
{
	import away3d.core.base.*;
	
	/**
	 * @author robbateman
	 */
	public interface IVertexAnimationNode extends IAnimationNode
	{
		function get currentGeometry() : Geometry;
		
		function get nextGeometry() : Geometry;
		
		function get blendWeight() : Number;
	}
}
