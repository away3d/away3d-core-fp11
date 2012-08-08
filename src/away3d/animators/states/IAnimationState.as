package away3d.animators.states
{
	import flash.geom.*;
	
	public interface IAnimationState
	{
		function get rootDelta() : Vector3D;
		
		function offset(startTime:int):void;
		
		function update(time:int):void;
		
		function updateTime(time:int):void;
	}
}
