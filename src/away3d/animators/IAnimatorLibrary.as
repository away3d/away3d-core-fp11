package away3d.animators
{
	import away3d.entities.Mesh;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	/**
	 * @author robbateman
	 */
	public interface IAnimatorLibrary
	{
		function get usesCPU() : Boolean;
		
		/**
		 * Generates the AGAL Vertex code for the animation, tailored to the material pass's requirements.
		 * @param pass The MaterialPassBase object to whose vertex code the animation's code will be prepended.
		 * @return The AGAL Vertex code that animates the vertex data.
		 *
		 * @private
		 */
		function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : String;

		/**
		 * Sets the GPU render state required by the animation that is independent of the rendered mesh.
		 * @param context The context which is currently performing the rendering.
		 * @param pass The material pass which is currently used to render the geometry.
		 *
		 * @private
		 */
		function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void

		/**
		 * Clears the GPU render state that has been set by the current animation.
		 * @param context The context which is currently performing the rendering.
		 * @param pass The material pass which is currently used to render the geometry.
		 *
		 * @private
		 */
		function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		
		function resetGPUCompatibility() : void;
	}
}
