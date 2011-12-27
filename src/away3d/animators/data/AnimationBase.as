package away3d.animators.data
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.materials.passes.MaterialPassBase;

	use namespace arcane;

	/**
	 * AnimationBase is an abstract base for classes that define the animation type for a Geometry.
	 * It creates an AnimationState, which is what defines the current animation state for each Mesh/SubMesh
	 * It also creates an AnimationController, which is what influences the state inside AnimationState (for example a
	 * timeline based controller, a physics based controller, etc)
	 *
	 * @see away3d.core.animation.AnimationControllerBase
	 * @see away3d.core.animation.AnimationStateBase
	 */
	public class AnimationBase
	{
        protected var _usesCPU : Boolean;

		/**
		 * Indicates whether or not this animation runs on CPU or GPU.
		 */
		public function get usesCPU() : Boolean
		{
			return _usesCPU;
		}

		arcane function resetGPUCompatibility() : void
        {
            _usesCPU = false;
        }

        /**
         * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
         */
        arcane function testGPUCompatibility(pass : MaterialPassBase) : void
        {
			// by default, let it run on gpu
        }

		/**
		 * Factory method which creates an animation state specific to this animation type.
		 * @return A concrete subtype of AnimationStateBase that is specific to the concrete subtype of AnimationStateBase
		 *
		 * @private
		 */
		arcane function createAnimationState() : AnimationStateBase
		{
			throw new AbstractMethodError();
		}

		/**
		 * Generates the AGAL Vertex code for the animation, tailored to the material pass's requirements.
		 * @param pass The MaterialPassBase object to whose vertex code the animation's code will be prepended.
		 * @return The AGAL Vertex code that animates the vertex data.
		 *
		 * @private
		 */
		arcane function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : String
		{
			// TODO: not used
			pass = pass;
			throw new AbstractMethodError();
			return null;
		}

		/**
		 * Sets the GPU render state required by the animation that is independent of the rendered mesh.
		 * @param context The context which is currently performing the rendering.
		 * @param pass The material pass which is currently used to render the geometry.
		 *
		 * @private
		 */
		arcane function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void {}

		/**
		 * Clears the GPU render state that has been set by the current animation.
		 * @param context The context which is currently performing the rendering.
		 * @param pass The material pass which is currently used to render the geometry.
		 *
		 * @private
		 */
		arcane function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void {}

		/**
		 * Returns true if the provided AnimationBase instance is considered equivalent to the current AnimationBase instance.
		 * Another instance is considered equivalent if it can be used within the same material pass.
		 * @param animation The animation to compare against.
		 * @return True if the animation is considered equivalent, false otherwise.
		 *
		 * @private
		 */
		arcane function equals(animation : AnimationBase) : Boolean
		{
			return animation == this;
		}
	}
}