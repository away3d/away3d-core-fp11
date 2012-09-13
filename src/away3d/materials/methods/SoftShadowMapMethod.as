package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.DirectionalLight;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;

	use namespace arcane;

	public class SoftShadowMapMethod extends ShadowMapMethodBase
	{
		private var _range : Number = 1.5;
		private var _numSamples : int;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function SoftShadowMapMethod(castingLight : DirectionalLight, numSamples : int = 5)
		{
			super(castingLight);

			this.numSamples = numSamples;
		}

		public function get numSamples() : int
		{
			return _numSamples;
		}

		public function set numSamples(value : int) : void
		{
			_numSamples = value;
			if (_numSamples < 1) _numSamples = 1;
			else if (_numSamples > 8) _numSamples = 8;
			invalidateShaderProgram();
		}

		public function get range() : Number
		{
			return _range;
		}

		public function set range(value : Number) : void
		{
			_range = value;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			fragmentData[index+8] = 1/_numSamples;

		}

		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			vo.fragmentData[vo.fragmentConstantsIndex+9] = _range/castingLight.shadowMapper.depthMapSize;
			vo.fragmentData[vo.fragmentConstantsIndex+10] = -_range/castingLight.shadowMapper.depthMapSize;
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
					"slt " + targetReg+".w, " + uvReg+".z, " + depthCol+".z\n";    // 0 if in shadow;

			if (_numSamples > 1)
				code += "add " + uvReg+".xy, " + _depthMapCoordReg+".xy, " + customDataReg+".zz\n" + 	// (-1, -1)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if (_numSamples > 5)
				code += "add " + uvReg+".xy, " + uvReg+".xy, " + customDataReg+".zz\n" + 	// (-2, -2)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if(_numSamples > 2)
				code += "add " + uvReg+".xy, " + _depthMapCoordReg+".xy, " + customDataReg+".yz\n" + 		// (1, -1)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if(_numSamples > 6)
				code += "add " + uvReg+".xy, " + uvReg+".xy, " + customDataReg+".yz\n" + 		// (2, -2)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if(_numSamples > 3)
				code += "add " + uvReg+".xy, " + _depthMapCoordReg+".xy, " + customDataReg+".zy\n" + 	// (-1, 1)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if(_numSamples > 7)
				code += "sub " + uvReg+".xy, " + uvReg+".xy, " + customDataReg+".zy\n" + 	// (-2, 2)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if(_numSamples > 4)
				code += "add " + uvReg+".xy, " + _depthMapCoordReg+".xy, " + customDataReg+".yy\n" +	// (1, 1)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +  // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if(_numSamples > 8)
				code += "add " + uvReg+".xy, " + uvReg+".xy, " + customDataReg+".yy\n" + 	// (2, 2)
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";


			regCache.removeFragmentTempUsage(depthCol);
			code += "mul " + targetReg+".w, " + targetReg+".w, " + customDataReg+".x\n";  // average

			vo.texturesIndex = depthMapRegister.index;

			return code;
		}
	}
}