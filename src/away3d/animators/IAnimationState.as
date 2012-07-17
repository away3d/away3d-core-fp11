package away3d.animators
{
	import away3d.animators.nodes.*;
	
	/**
	 * Provides an interface for state classes inside an animation set that hold animation node data for specific animation states.
	 *
	 * @see away3d.animators.IAnimationSet
	 */
	public interface IAnimationState
	{
		/**
		 * Determines whether the contents of the animation state have looping characteristics enabled.
		 */
		function get looping():Boolean;
		function set looping(value:Boolean):void;
				
		/**
		 * Returns the root animation node used by the state for determining the output pose of the animation node data.
		 */
		function get rootNode():IAnimationNode;
		
		/**
		 * Returns the name of the state used for retrieval from inside its parent animation set object.
		 * 
		 * @see away3d.animators.IAnimationSet
		 */
		function get stateName():String;
		
		/**
		 * Resets the configuration of the state to its default state.
		 * 
		 * @param time The absolute time (in milliseconds) of the animator's playhead.
		 */
		function reset(time:int):void
		
		/**
		 * Used by the animation set on adding a state, defines the internal owner and state name
		 * properties of the state.
		 * 
		 * @private
		 */
		function addOwner(owner:IAnimationSet, stateName:String):void;
	}
}
