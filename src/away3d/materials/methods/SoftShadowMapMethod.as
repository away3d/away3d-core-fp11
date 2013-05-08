package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.PoissonLookup;
	import away3d.lights.DirectionalLight;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;

	use namespace arcane;

	public class SoftShadowMapMethod extends SimpleShadowMapMethodBase
	{
		private var _range : Number = 1;
		private var _numSamples : int;
		private var _offsets : Vector.<Number>;

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
			else if (_numSamples > 32) _numSamples = 32;

			_offsets = PoissonLookup.getDistribution(_numSamples);
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
			vo.fragmentData[vo.fragmentConstantsIndex+9] = 0;
		}

		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			var texRange : Number = .5*_range/_castingLight.shadowMapper.depthMapSize;
			var data : Vector.<Number> = vo.fragmentData;
			var index : uint = vo.fragmentConstantsIndex+10;
			var len : uint = _numSamples << 1;

			for (var i : int = 0; i < len; ++i)
				data[uint(index + i)] = _offsets[i]*texRange;
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
			// TODO: not used
			dataReg=dataReg;
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
			super.activate(vo, stage3DProxy);
			var texRange : Number = _range/_castingLight.shadowMapper.depthMapSize;
			var data : Vector.<Number> = vo.fragmentData;
			var index : uint = vo.secondaryFragmentConstantsIndex;
			var len : uint = _numSamples << 1;
			data[index] = 1/_numSamples;
			data[uint(index + 1)] = 0;
			index += 2;
			for (var i : int = 0; i < len; ++i)
				data[uint(index+i)] = _offsets[i]*texRange;

			if (len % 4 == 0) {
				data[uint(index+len)] = 0;
				data[uint(index+len+1)] = 0;
			}
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
			var offsets : Vector.<String> = new <String>[ dataReg + ".zw" ];
			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);

			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			var numRegs : int = _numSamples >> 1;
			for (var i : int = 0; i < numRegs; ++i) {
				var reg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
				offsets.push(reg+".xy");
				offsets.push(reg+".zw");
			}

			for (i = 0; i < _numSamples; ++i) {
				if (i == 0) {
					code = "add " + uvReg + ", " + _depthMapCoordReg + ", " + dataReg + ".zwyy\n";
					code += "tex " + temp + ", " + uvReg + ", " + depthTexture + " <2d,nearest,clamp>\n" +
							"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
							"slt " + targetRegister + ".w, " + _depthMapCoordReg + ".z, " + temp + ".z\n";    // 0 if in shadow;
				}
				else {
					code += "add " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + offsets[i] + "\n";
					code += addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);
				}
			}

			regCache.removeFragmentTempUsage(uvReg);
			code += "mul " + targetRegister + ".w, " + targetRegister + ".w, " + dataReg + ".x\n";  // average
			return code;
		}
	}
}