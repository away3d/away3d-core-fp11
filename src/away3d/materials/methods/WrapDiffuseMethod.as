package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * WrapDiffuseMethod is an alternative to BasicDiffuseMethod in which the light is allowed to be "wrapped around" the normally dark area, to some extent.
	 * It can be used as a crude approximation to Oren-Nayar or subsurface scattering.
	 */
	public class WrapDiffuseMethod extends BasicDiffuseMethod
	{
		private var _wrapData : Vector.<Number>;
		private var _wrapDataRegister : ShaderRegisterElement;
		private var _scatterTextureRegister : ShaderRegisterElement;
		private var _wrapIndex : int;
		private var _scatterTexture : Texture2DBase;
		private var _scatterTextureIndex : int;

		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param wrap A factor to indicate the amount by which the light is allowed to wrap
		 * @param scatterTexture A texture that contains the light colour based on the angle. This can be used to change the light colour due to subsurface scattering when dot < 0
		 */
		public function WrapDiffuseMethod(wrapFactor : Number = .5, scatterTexture : Texture2DBase = null)
		{
			super();
			_wrapData = new Vector.<Number>(4, true);
			_wrapData[2] = .5;
			this.wrapFactor = wrapFactor;
			this.scatterTexture = scatterTexture;
		}

		public function get scatterTexture() : Texture2DBase
		{
			return _scatterTexture;
		}

		public function set scatterTexture(value : Texture2DBase) : void
		{
			if (Boolean(_scatterTexture) != Boolean(value)) invalidateShaderProgram();
			_scatterTexture = value;
		}

		arcane override function cleanCompilationData() : void
		{
			super.arcane::cleanCompilationData();
			_wrapDataRegister = null;
			_scatterTextureRegister = null;
		}

		public function get wrapFactor() : Number
		{
			return _wrapData[0];
		}

		public function set wrapFactor(value : Number) : void
		{
			_wrapData[0] = value;
			_wrapData[1] = 1/(value+1);
		}

		arcane override function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			_wrapDataRegister = regCache.getFreeFragmentConstant();
			_wrapIndex = _wrapDataRegister.index;

			if (_scatterTexture) {
				_scatterTextureRegister = regCache.getFreeTextureReg();
				_scatterTextureIndex = _scatterTextureRegister.index;
			}

			return super.arcane::getFragmentAGALPreLightingCode(regCache);
		}

		arcane override function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;

			// write in temporary if not first light, so we can add to total diffuse colour
			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else {
				t = _totalLightColorReg;
			}

			code += "dp3 " + t + ".x, " + lightDirReg + ".xyz, " + _normalFragmentReg + ".xyz\n" +
					"add " + t + ".y, " + t + ".x, " + _wrapDataRegister + ".x\n" +
					"mul " + t + ".y, " + t + ".y, " + _wrapDataRegister + ".y\n" +
					"sat " + t + ".w, " + t + ".y\n" +
					"mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

			if (_modulateMethod != null) code += _modulateMethod(t, regCache);

			if (_scatterTexture) {
				code += "mul " + t + ".x, " + t + ".x, " + _wrapDataRegister + ".z\n" +
						"add " + t + ".x, " + t + ".x, " + t + ".x\n" +
						"tex " + t + ".xyz, " + t + ".xxx, " + _scatterTextureRegister + " <2d, nearest, clamp>\n" +
						"mul " + t + ".xyz, " + t + ".xyz, " + t + ".w\n" +
						"mul " + t + ".xyz, " + t + ".xyz, " + lightColReg + ".xyz\n";

			}
			else {
				code += "mul " + t + ", " + t + ".w, " + lightColReg + "\n";
			}


			if (lightIndex > 0) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}


		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			super.arcane::activate(stage3DProxy);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _wrapIndex, _wrapData, 1);

			if (_scatterTexture) {
				stage3DProxy.setTextureAt(_scatterTextureIndex, _scatterTexture.getTextureForStage3D(stage3DProxy));
			}
		}
	}
}
