package away3d.animators
{
	import away3d.entities.Mesh;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	/**
	 * @author robbateman
	 */
	public interface IAnimator
	{
		function get animationLibrary() : IAnimationLibrary
		
		/**
		 * Sets the GPU render state required by the animation that is dependent of the rendered object.
		 * @param context The context which is currently performing the rendering.
		 * @param pass The material pass which is currently used to render the geometry.
		 * @param renderable The object currently being rendered.
		 * @param vertexConstantOffset The first available vertex register to write data to if running on the gpu.
		 * @param vertexStreamOffset The first available vertex stream to write vertex data to if running on the gpu.
		 */
		function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		
		function testGPUCompatibility(pass : MaterialPassBase) : void;
		
		function addOwner(mesh : Mesh) : void
		
		function removeOwner(mesh : Mesh) : void
	}
}
