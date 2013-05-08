package away3d.materials.methods
{
	import away3d.*;
	import away3d.errors.*;
	import away3d.library.assets.*;
	import away3d.materials.compilation.*;

	use namespace arcane;

	/**
	 * EffectMethodBase forms an abstract base class for shader methods that are not dependent on light sources,
	 * and are in essence post-process effects on the materials.
	 */
	public class EffectMethodBase extends ShadingMethodBase implements IAsset
	{
		public function EffectMethodBase()
		{
			super();
		}
		
		public function get assetType() : String
		{
			return AssetType.EFFECTS_METHOD;
		}
		
		/**
		 * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			throw new AbstractMethodError();
			vo=vo;regCache=regCache;targetReg=targetReg;
			return "";
		}
	}
}
