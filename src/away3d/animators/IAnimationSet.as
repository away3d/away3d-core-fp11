package away3d.animators
{
	import away3d.animators.nodes.*;
	import away3d.core.managers.*;
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
		 * @param stateName The name of the animation state object to be checked.
		 */
		function hasAnimation(name:String):Boolean;
		
		/**
		 * Retrieves the animation state object registered in the animation data set under the given name.
		 *
		 * @param stateName The name of the animation state object to be retrieved.
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
		
		/**
		 * Generates the AGAL Vertex code for the animation, tailored to the material pass's requirements.
		 *
		 * @param pass The MaterialPassBase object to whose vertex code the animation's code will be prepended.
		 * @sourceRegisters The animatable attribute registers of the material pass.
		 * @targetRegisters The animatable target registers of the material pass.
		 * @return The AGAL Vertex code that animates the vertex data.
		 *
		 * @private
		 */
		function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Vector.<String>, targetRegisters:Vector.<String>, profile:String):String;
		
		/**
		 * Generates the AGAL Fragment code for the animation, tailored to the material pass's requirements.
		 *
		 * @param pass The MaterialPassBase object to whose vertex code the animation's code will be prepended.
		 * @return The AGAL Vertex code that animates the vertex data.
		 *
		 * @private
		 */
		function getAGALFragmentCode(pass:MaterialPassBase, shadedTarget:String, profile:String):String;
		
		/**
		 * Generates the extra AGAL Fragment code for the animation when UVs are required, tailored to the material pass's requirements.
		 *
		 * @param pass The MaterialPassBase object to whose vertex code the animation's code will be prepended.
		 * @param UVSource String representing the UV source register.
		 * @param UVTarget String representing the UV target register.
		 * @return The AGAL UV code that animates the UV data.
		 *
		 * @private
		 */
		function getAGALUVCode(pass:MaterialPassBase, UVSource:String, UVTarget:String):String;
		
		/**
		 * Resets any constants used in the creation of AGAL for the vertex and fragment shaders.
		 *
		 * @param pass The material pass currently being used to render the geometry.
		 *
		 * @private
		 */
		function doneAGALCode(pass:MaterialPassBase):void;
		
		/**
		 * Sets the GPU render state required by the animation that is independent of the rendered mesh.
		 *
		 * @param stage3DProxy The proxy currently performing the rendering.
		 * @param pass The material pass currently being used to render the geometry.
		 *
		 * @private
		 */
		function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		
		/**
		 * Clears the GPU render state that has been set by the current animation.
		 *
		 * @param stage3DProxy The proxy currently performing the rendering.
		 * @param pass The material pass currently being used to render the geometry.
		 *
		 * @private
		 */
		function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
	}
}
