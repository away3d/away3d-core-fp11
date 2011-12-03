package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.lights.DirectionalLight;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class HardShadowMapMethod extends DirectionalShadowMapMethodBase
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function HardShadowMapMethod(castingLight : DirectionalLight)
		{
			super(castingLight);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var epsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";

			_decIndex = decReg.index;

			code += "tex " + depthCol + ", " + _depthMapCoordReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"add " + targetReg + ".w, " + _depthMapCoordReg+".z, " + epsReg+".x\n" +    // offset by epsilon

					"slt " + targetReg + ".w, " + targetReg + ".w, " + depthCol+".z\n";   // 0 if in shadow


			_depthMapIndex = depthMapRegister.index;

			return code;
		}
	}
}
