package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * DepthDiffuseMethod provides a debug method to visualise depth maps
	 */
	public class DepthDiffuseMethod extends BasicDiffuseMethod
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function DepthDiffuseMethod()
		{
			super();
		}


		override arcane function initConstants(vo : MethodVO) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			data[index] = 1.0;
			data[index+1] = 1/255.0;
			data[index+2] = 1/65025.0;
			data[index+3] = 1/16581375.0;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var temp : ShaderRegisterElement;
			var decReg : ShaderRegisterElement;

			if (!_useTexture) throw new Error("DepthDiffuseMethod requires texture!");

			// incorporate input from ambient
			if (vo.numLights > 0) {
				if (_shadowRegister)
					code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _shadowRegister + ".w\n";
				code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz, " + targetReg + ".xyz\n" +
						"sat " + targetReg + ".xyz, " + targetReg + ".xyz\n";
				regCache.removeFragmentTempUsage(_totalLightColorReg);
			}

			temp = vo.numLights > 0 ? regCache.getFreeFragmentVectorTemp() : targetReg;

			_diffuseInputRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _diffuseInputRegister.index;
			decReg = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = decReg.index*4;
			code += getTexSampleCode(vo, temp, _diffuseInputRegister) +
					"dp4 " + temp + ".x, " + temp + ", "+ decReg + "\n" +
					"mov " + temp + ".yzw, " + temp + ".xxx			\n";

			if (vo.numLights == 0)
				return code;

			code += "mul " + targetReg + ".xyz, " + temp + ".xyz, " + targetReg + ".xyz\n" +
					"mov " + targetReg + ".w, " + temp + ".w\n";

			return code;
		}
	}
}
