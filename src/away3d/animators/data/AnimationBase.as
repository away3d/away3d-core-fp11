package away3d.animators.data
{
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.materials.passes.MaterialPassBase;

	import flash.display3D.Context3D;

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
		arcane function getAGALVertexCode(pass : MaterialPassBase) : String
		{
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
		arcane function activate(context : Context3D, pass : MaterialPassBase) : void {}

		/**
		 * Clears the GPU render state that has been set by the current animation.
		 * @param context The context which is currently performing the rendering.
		 * @param pass The material pass which is currently used to render the geometry.
		 *
		 * @private
		 */
		arcane function deactivate(context : Context3D, pass : MaterialPassBase) : void {}

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