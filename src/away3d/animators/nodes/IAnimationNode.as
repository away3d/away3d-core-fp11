package away3d.animators.nodes
{
	import flash.geom.*;
	import flash.events.*;
	
	/**
	 * Provides an interface for animation node classes that hold animation data for use in animator classes.
	 */
	public interface IAnimationNode extends IEventDispatcher
	{
		/**
		 * Determines whether the contents of the animation node have looping characteristics enabled.
		 */
		function get looping():Boolean;
		function set looping(value:Boolean):void
		
		/**
		 * Returns a 3d vector representing the translation delta of the animating entity for the current timestep of animation
		 */		
		function get rootDelta() : Vector3D;
		
		/**
		 * Updates the configuration of the node to its current state.
		 * 
		 * @param time The absolute time (in milliseconds) of the animator's play head position.
		 * 
		 * @see away3d.animators.IAnimator#update()
		 */		
		function update(time:int):void;
		
		/**
		 * Resets the configuration of the node to its default state.
		 * 
		 * @param time The absolute time (in milliseconds) of the animator's playhead position.
		 */
		function reset(time:int):void;
	}
}
