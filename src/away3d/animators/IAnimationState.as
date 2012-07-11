package away3d.animators
{
	import away3d.animators.nodes.*;
	
	/**
	 * @author robbateman
	 */
	public interface IAnimationState
	{
		function get looping():Boolean;
		
		function set looping(value:Boolean):void;
		
		function get rootNode():IAnimationNode;
		
		function get stateName():String;
		
		function addOwner(owner:IAnimationSet, stateName:String):void;
	}
}
