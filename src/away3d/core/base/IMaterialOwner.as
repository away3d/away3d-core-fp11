package away3d.core.base
{
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.materials.MaterialBase;

	/**
	 * IMaterialOwner provides an interface for objects that can use materials.
	 */
	public interface IMaterialOwner
	{
		/**
		 * The material with which to render the object.
		 */
		function get material() : MaterialBase;
		function set material(value : MaterialBase) : void;

		/**
		 * The animation used by the material to assemble the vertex code.
		 */
		function get animation() : AnimationBase;	// in most cases, this will in fact be NullAnimation
		function get animationState() : AnimationStateBase;
	}
}