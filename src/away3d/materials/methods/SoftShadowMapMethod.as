package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.DirectionalLight;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;

	use namespace arcane;

	public class SoftShadowMapMethod extends SimpleShadowMapMethodBase
	{
		private var _range : Number = 1;
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

			vo.fragmentData[vo.fragmentConstantsIndex+8] = 1/_numSamples;
		}

		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			var texRange : Number = _range/_castingLight.shadowMapper.depthMapSize;
			var data : Vector.<Number> = vo.fragmentData;
			var index : uint = vo.fragmentConstantsIndex;
			data[index+9] = texRange;
			data[index+10] = -texRange;
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			// todo: move some things to super
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();

			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;

			return getSampleCode(regCache, depthMapRegister, decReg, targetReg, customDataReg);
		}

		private function addSample(uv : ShaderRegisterElement, texture : ShaderRegisterElement, decode : ShaderRegisterElement, target : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			return 	"tex " + temp + ", " + uv + ", " + texture + " <2d,nearest,clamp>\n" +
					"dp4 " + temp + ".z, " + temp + ", " + decode + "\n" +
					"slt " + uv + ".w, " + _depthMapCoordReg + ".z, " + temp + ".z\n" + // 0 if in shadow
					"add " + target + ".w, " + target + ".w, " + uv + ".w\n";
		}

		override arcane function activateForCascade(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var texRange : Number = _range/_castingLight.shadowMapper.depthMapSize;
			var data : Vector.<Number> = vo.fragmentData;
			var index : uint = vo.secondaryFragmentConstantsIndex;
			data[index] = 1/_numSamples;
			data[index+1] = texRange;
			data[index+2] = -texRange;
		}

		override arcane function getCascadeFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, decodeRegister : ShaderRegisterElement, depthTexture : ShaderRegisterElement, depthProjection : ShaderRegisterElement, targetRegister : ShaderRegisterElement) : String
		{
			_depthMapCoordReg = depthProjection;

			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = dataReg.index*4;

			return getSampleCode(regCache, depthTexture, decodeRegister, targetRegister, dataReg);
		}

		private function getSampleCode(regCache : ShaderRegisterCache, depthTexture : ShaderRegisterElement, decodeRegister : ShaderRegisterElement, targetRegister : ShaderRegisterElement, dataReg : ShaderRegisterElement) : String
		{
			var uvReg : ShaderRegisterElement;
			var code : String;
			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);

			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			code = "mov " + uvReg + ", " + _depthMapCoordReg + "\n" +
					"tex " + temp + ", " + _depthMapCoordReg + ", " + depthTexture + " <2d,nearest,clamp>\n" +
					"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
					"slt " + targetRegister + ".w, " + _depthMapCoordReg + ".z, " + temp + ".z\n";    // 0 if in shadow;

			if (_numSamples > 1)
				code += "add " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + dataReg + ".zz\n" + // (-1, -1)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);

			if (_numSamples > 5)
				code += "add " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".zz\n" + // (-2, -2)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);

			if (_numSamples > 2)
				code += "add " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + dataReg + ".yz\n" + // (1, -1)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);

			if (_numSamples > 6)
				code += "add " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".yz\n" + // (2, -2)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);

			if (_numSamples > 3)
				code += "add " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + dataReg + ".zy\n" + // (-1, 1)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);

			if (_numSamples > 7)
				code += "sub " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".zy\n" + // (-2, 2)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);

			if (_numSamples > 4)
				code += "add " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + dataReg + ".yy\n" + // (1, 1)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);

			if (_numSamples > 8)
				code += "add " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".yy\n" + // (2, 2)
						addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);


			regCache.removeFragmentTempUsage(uvReg);
			code += "mul " + targetRegister + ".w, " + targetRegister + ".w, " + dataReg + ".x\n";  // average
			return code;
		}
	}
}