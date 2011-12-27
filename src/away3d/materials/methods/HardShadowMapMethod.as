package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class HardShadowMapMethod extends ShadowMapMethodBase
	{
		/**
		 * Creates a new HardShadowMapMethod object.
		 */
		public function HardShadowMapMethod(castingLight : LightBase)
		{
			super(castingLight);
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
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

		override protected function getPointFragmentCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var epsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var posReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthSampleCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(depthSampleCol, 1);
			var lightDir : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";

			_decIndex = decReg.index;
			_depthMapIndex = depthMapRegister.index;

			code += "sub " + lightDir + ", " + _globalPosReg + ", " + posReg + "\n" +
					"dp3 " + lightDir + ".w, " + lightDir + ".xyz, " + lightDir + ".xyz\n" +
					"mul " + lightDir + ".w, " + lightDir + ".w, " + posReg + ".w\n" +
					"nrm " + lightDir + ".xyz, " + lightDir + ".xyz\n" +

					"tex " + depthSampleCol + ", " + lightDir + ", " + depthMapRegister + " <cube, nearest, clamp>\n" +
					"dp4 " + depthSampleCol+".z, " + depthSampleCol + ", " + decReg + "\n" +
					"add " + targetReg + ".w, " + lightDir+".w, " + epsReg+".x\n" +    // offset by epsilon

					"slt " + targetReg + ".w, " + targetReg + ".w, " + depthSampleCol+".z\n";   // 0 if in shadow

			regCache.removeFragmentTempUsage(depthSampleCol);

			return code;
		}
	}
}