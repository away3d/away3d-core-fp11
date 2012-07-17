package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	/**
	 * EffectMethodBase forms an abstract base class for shader methods that are not dependent on light sources,
	 * and are in essence post-process effects on the materials.
	 */
	public class EffectMethodBase extends ShadingMethodBase
	{
		public function EffectMethodBase()
		{
			super();
		}

		/**
		 * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			throw new AbstractMethodError();
			return "";
		}
	}
}
