package away3d.animators
{
	import away3d.animators.nodes.*;
	import away3d.managers.*;
	import away3d.materials.passes.*;
	
	/**
	 * Provides an interface for data set classes that hold animation data for use in animator classes.
	 *
	 * @see away3d.animators.IAnimator
	 */
	public interface IAnimationSet
	{
		/**
		 * Check to determine whether a state is registered in the animation set under the given name.
		 *
		 * @param name The name of the animation state object to be checked.
		 */
		function hasAnimation(name:String):Boolean;
		
		/**
		 * Retrieves the animation state object registered in the animation data set under the given name.
		 *
		 * @param name The name of the animation state object to be retrieved.
		 */
		function getAnimation(name:String):AnimationNodeBase;
		
		/**
		 * Indicates whether the properties of the animation data contained within the set combined with
		 * the vertex registers aslready in use on shading materials allows the animation data to utilise
		 * GPU calls.
		 */
		function get usesCPU():Boolean;
		
		/**
		 * Called by the material to reset the GPU indicator before testing whether register space in the shader
		 * is available for running GPU-based animation code.
		 *
		 * @private
		 */
		function resetGPUCompatibility():void;
		
		/**
		 * Called by the animator to void the GPU indicator when register space in the shader
		 * is no longer available for running GPU-based animation code.
		 *
		 * @private
		 */
		function cancelGPUCompatibility():void;
	}
}
