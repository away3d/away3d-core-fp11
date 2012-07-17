package away3d.animators.data
{
	import away3d.arcane;
	import away3d.materials.passes.MaterialPassBase;

	use namespace arcane;

	/**
	 * The NullAnimation class provides a null object to indicate no animation is performed. This is usually set as default.
	 */
	public class NullAnimation extends AnimationBase
	{
		/**
		 * @inheritDoc
		 */
		override arcane function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : String
		{
			var len : uint = sourceRegisters.length;
			var code : String = "";

			// simply write attributes to targets, do not animate them
			// projection will pick up on targets[0] to do the projection
			for (var i : uint = 0; i < len; ++i)
				code += "mov " + targetRegisters[i] + ", " + sourceRegisters[i] + "\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function createAnimationState() : AnimationStateBase
		{
			return null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function equals(animation : AnimationBase) : Boolean
		{
			return animation is NullAnimation;
		}
	}
}