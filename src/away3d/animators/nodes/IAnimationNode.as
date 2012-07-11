package away3d.animators.nodes
{
	import flash.geom.*;
	import flash.events.*;
	
	/**
	 * @author robbateman
	 */
	public interface IAnimationNode extends IEventDispatcher
	{
		function get looping():Boolean;
		function set looping(value:Boolean):void
		
		
		function get rootDelta() : Vector3D;
		
		
		function update(time:Number):void;
		
		function reset(time:Number):void;
	}
}
