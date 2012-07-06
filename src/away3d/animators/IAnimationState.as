package away3d.animators
{
	import away3d.animators.nodes.IAnimationNode;
	/**
	 * @author robbateman
	 */
	public interface IAnimationState
	{
		function get rootNode():IAnimationNode;
		
		function get stateName():String;
		
		function addOwner(owner:IAnimationSet, stateName:String):void;
	}
}
