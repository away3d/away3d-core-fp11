package away3d.animators
{
	import away3d.animators.nodes.*;
	import away3d.animators.states.*;
	import away3d.cameras.Camera3D;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.entities.*;
	import away3d.materials.passes.*;
	
	/**
	 * Provides an interface for animator classes that control animation output from a data set subtype of <code>AnimationSetBase</code>.
	 *
	 * @see away3d.animators.IAnimationSet
	 */
	public interface IAnimator
	{
		/**
		 * Returns the animation data set in use by the animator.
		 */
		function get animationSet():IAnimationSet;
		
		/**
		 * Sets the GPU render state required by the animation that is dependent of the rendered object.
		 *
		 * @param stage3DProxy The Stage3DProxy object which is currently being used for rendering.
		 * @param renderable The object currently being rendered.
		 * @param vertexConstantOffset The first available vertex register to write data to if running on the gpu.
		 * @param vertexStreamOffset The first available vertex stream to write vertex data to if running on the gpu.
		 */
		function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		
		/**
		 * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
		 */
		function testGPUCompatibility(pass:MaterialPassBase):void;
		
		/**
		 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
		 *
		 * @private
		 */
		function addOwner(mesh:Mesh):void
		
		/**
		 * Used by the mesh object from which the animator is removed, unregisters the owner for internal use.
		 *
		 * @private
		 */
		function removeOwner(mesh:Mesh):void
		
		function getAnimationState(node:AnimationNodeBase):AnimationStateBase;
		
		function getAnimationStateByName(name:String):AnimationStateBase;
		
		/**
		 * Returns a shallow clone (re-using the same IAnimationSet) of this IAnimator.
		 */
		function clone():IAnimator;
		
		function dispose():void;
	}
}
