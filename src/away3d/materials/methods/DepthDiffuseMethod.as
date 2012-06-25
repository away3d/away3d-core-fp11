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
		private var _depthData : Vector.<Number>;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function DepthDiffuseMethod()
		{
			super();
			_depthData = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/16581375.0]);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var temp : ShaderRegisterElement;
			var decReg : ShaderRegisterElement;

			// incorporate input from ambient
			if (vo.numLights > 0) {
				if (_shadowRegister)
					code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _shadowRegister + ".w\n";
				code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz, " + targetReg + ".xyz\n" +
						"sat " + targetReg + ".xyz, " + targetReg + ".xyz\n";
				regCache.removeFragmentTempUsage(_totalLightColorReg);
			}

			temp = vo.numLights > 0 ? regCache.getFreeFragmentVectorTemp() : targetReg;

			if (_useTexture) {
				_diffuseInputRegister = regCache.getFreeTextureReg();
				vo.texturesIndex = _diffuseInputRegister.index;
				decReg = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = decReg.index;
				code += getTexSampleCode(vo, temp, _diffuseInputRegister) +
						"dp4 " + temp + ".x, " + temp + ", "+ decReg + "\n" +
						"mov " + temp + ".yzw, " + temp + ".xxx			\n";
			}
			else {
				_diffuseInputRegister = regCache.getFreeFragmentConstant();
				code += "mov " + temp + ", " + _diffuseInputRegister + "\n";
				vo.fragmentConstantsIndex = _diffuseInputRegister.index;
			}

			if (vo.numLights == 0)
				return code;

			code += "mul " + targetReg + ".xyz, " + temp + ".xyz, " + targetReg + ".xyz\n" +
					"mov " + targetReg + ".w, " + temp + ".w\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			if (_useTexture)
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, vo.fragmentConstantsIndex, _depthData, 1);
		}
	}
}
