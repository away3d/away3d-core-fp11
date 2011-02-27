package away3d.core.managers
{
	import away3d.animators.data.AnimationBase;
	import away3d.errors.AbstractMethodError;
	import away3d.materials.passes.MaterialPassBase;

	import flash.display3D.Context3D;
	import flash.display3D.Program3D;

	/**
	 * Program3DAssemblerBase provides an abstract base class for subtypes that can assemble the shader code provided
	 * by the animation and the material into a single Program3D instance, adding projection code.
	 */
	public class Program3DAssemblerBase
	{
		/**
		 * Compiles a Program3D instance for the given animation and material pass.
		 * @param context The Context3D object for which to generate the Program3D object.
		 * @param pass The material pass for which to generate the Program3D object.
		 * @param animation The animation to use in the requested Program3D.
		 * @param program The target Program3D object.
		 * @param polyOffsetReg The name of an optional offset register, containing a vector by which will cause the geometry to be "inflated" along the normal. This is typically used when rendering single object depth maps.
		 */
		public function assemble(context : Context3D, pass : MaterialPassBase, animation : AnimationBase, program : Program3D, polyOffsetReg : String = null) : void
		{
			throw new AbstractMethodError();
		}
	}
}