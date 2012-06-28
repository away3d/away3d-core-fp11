package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.lights.DirectionalLight;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class SoftShadowMapMethod extends ShadowMapMethodBase
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function SoftShadowMapMethod(castingLight : DirectionalLight)
		{
			super(castingLight);
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			fragmentData[index+8] = 1/9;
			fragmentData[index+9] = 1/castingLight.shadowMapper.depthMapSize;
			fragmentData[index+10] = 0;
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : String = "";
			vo.fragmentConstantsIndex = decReg.index*4;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();

			code += "mov " + uvReg + ", " + _depthMapCoordReg + "\n" +

					"tex " + depthCol + ", " + _depthMapCoordReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"add " + uvReg+".z, " + _depthMapCoordReg+".z, " + dataReg+".x\n" +     // offset by epsilon
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + targetReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow

					"sub " + uvReg+".x, " + _depthMapCoordReg+".x, " + customDataReg+".y\n" + 	// (-1, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".x, " + _depthMapCoordReg+".x, " + customDataReg+".y\n" + 		// (1, 0)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"mov " + uvReg+".x, " + _depthMapCoordReg+".x\n" +
					"sub " + uvReg+".y, " + _depthMapCoordReg+".y, " + customDataReg+".y\n" + 	// (0, -1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".y, " + _depthMapCoordReg+".y, " + customDataReg+".y\n" +	// (0, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +  // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			code += "sub " + uvReg+".xy, " + _depthMapCoordReg+".xy, " + customDataReg+".yy\n" + // (0, -1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".y, " + _depthMapCoordReg+".y, " + customDataReg+".y\n" +	// (-1, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"add " + uvReg+".xy, " + _depthMapCoordReg+".xy, " + customDataReg+".yy\n" +  // (1, 1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +

					"sub " + uvReg+".y, " + _depthMapCoordReg+".y, " + customDataReg+".y\n" +	// (1, -1)
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +   // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			regCache.removeFragmentTempUsage(depthCol);
			code += "mul " + targetReg+".w, " + targetReg+".w, " + customDataReg+".x\n";  // average

			vo.texturesIndex = depthMapRegister.index;

			return code;
		}
	}
}