package away3d.animators
{
	import away3d.animators.transitions.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.entities.*;
	import away3d.materials.passes.*;
	import away3d.materials.passes.MaterialPassBase;

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
		function get animationSet() : IAnimationSet;
		
		/**
		 * Returns the current active animation state.
		 */
		function get activeState() : IAnimationState;
		
		/**
		 * Determines whether the animators internal update mechanisms are active. Used in cases
		 * where manual updates are required either via the <code>time</code> property or <code>update()</code> method.
		 * Defaults to true.
		 * 
		 * @see #time
		 * @see #update()
		 */
		function get autoUpdate():Boolean;
		function set autoUpdate(value:Boolean):void;
		
		/**
		 * Gets and sets the internal time clock of the animator.
		 */
		function get time():int;
		function set time(value:int):void;
		
		/**
		 * The amount by which passed time should be scaled. Used to slow down or speed up animations. Defaults to 1.
		 */
		function get playbackSpeed() : Number;
		function set playbackSpeed(value : Number) : void;
		
		function play(stateName : String, stateTransition:StateTransitionBase = null) : void;
		
		/**
		 * Resumes the automatic playback clock controling the active state of the animator.
		 */
		function start() : void;
		
		/**
		 * Pauses the automatic playback clock of the animator, in case manual updates are required via the
		 * <code>time</code> property or <code>update()</code> method.
		 * 
		 * @see #time
		 * @see #update()
		 */
		function stop() : void;
		
		/**
		 * Provides a way to manually update the active state of the animator when automatic
		 * updates are disabled.
		 * 
		 * @see #stop()
		 * @see #autoUpdate
		 */
		function update(time : int) : void;
		
		/**
		 * Sets the GPU render state required by the animation that is dependent of the rendered object.
		 * 
		 * @param stage3DProxy The Stage3DProxy object which is currently being used for rendering.
		 * @param renderable The object currently being rendered.
		 * @param vertexConstantOffset The first available vertex register to write data to if running on the gpu.
		 * @param vertexStreamOffset The first available vertex stream to write vertex data to if running on the gpu.
		 */
		function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		
        /**
         * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
         */
		function testGPUCompatibility(pass : MaterialPassBase) : void;
		
		/**
		 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
		 * 
		 * @private
		 */
		function addOwner(mesh : Mesh) : void
		
		/**
		 * Used by the mesh object from which the animator is removed, unregisters the owner for internal use.
		 * 
		 * @private
		 */
		function removeOwner(mesh : Mesh) : void
	}
}