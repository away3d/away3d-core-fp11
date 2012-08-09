package away3d.animators.states
{
	import flash.geom.*;
	
	public interface IAnimationState
	{
		function get positionDelta() : Vector3D;
		
		function offset(startTime:int):void;
		
		function update(time:int):void;
		
		/**
		 * Sets the animation phase of the node.
		 * 
		 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
		 */
		function phase(value:Number):void;
	}
}
