package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.lights.DirectionalLight;
	import away3d.lights.shadowmaps.CascadeShadowMapper;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;

	import flash.events.Event;

	use namespace arcane;

	public class CascadeShadowMapMethod extends ShadowMapMethodBase
	{
		private var _baseMethod : SimpleShadowMapMethodBase;
		private var _cascadeShadowMapper : CascadeShadowMapper;
		private var _depthMapCoordVaryings : Vector.<ShaderRegisterElement>;
		private var _cascadeProjections : Vector.<ShaderRegisterElement>;

		/**
		 * Creates a new CascadeShadowMapMethod object.
		 */
		public function CascadeShadowMapMethod(shadowMethodBase : SimpleShadowMapMethodBase)
		{
			super(shadowMethodBase.castingLight);
			_baseMethod = shadowMethodBase;
			if (!(_castingLight is DirectionalLight)) throw new Error("CascadeShadowMapMethod is only compatible with DirectionalLight");
			_cascadeShadowMapper = _castingLight.shadowMapper as CascadeShadowMapper;

			if (!_cascadeShadowMapper)
				throw new Error("NearShadowMapMethod requires a light that has a CascadeShadowMapper instance assigned to shadowMapper.");

			_cascadeShadowMapper.addEventListener(Event.CHANGE, onCascadeChange, false, 0, true);
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
		}

		public function get baseMethod() : SimpleShadowMapMethodBase
		{
			return _baseMethod;
		}

		public function set baseMethod(value : SimpleShadowMapMethodBase) : void
		{
			if (_baseMethod == value) return;
			_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseMethod = value;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
			invalidateShaderProgram();
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			var tempVO : MethodVO = new MethodVO();
			_baseMethod.initVO(tempVO);
			vo.needsGlobalVertexPos = true;
			vo.needsProjection = true;
		}

		override arcane function set sharedRegisters(value : ShaderRegisterData) : void
		{
			super.sharedRegisters = value;
			_baseMethod.sharedRegisters = value;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var fragmentData : Vector.<Number> = vo.fragmentData;
			var vertexData : Vector.<Number> = vo.vertexData;
			var index : int = vo.fragmentConstantsIndex;
			fragmentData[index] = 1.0;
			fragmentData[index+1] = 1/255.0;
			fragmentData[index+2] = 1/65025.0;
			fragmentData[index+3] = 1/16581375.0;

			fragmentData[index+6] = .5;
			fragmentData[index+7] = -.5;

			index = vo.vertexConstantsIndex;
			vertexData[index] = .5;
			vertexData[index + 1] = -.5;
			vertexData[index + 2] = 0;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_cascadeProjections = null;
			_depthMapCoordVaryings = null;
		}

		override arcane function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var dataReg : ShaderRegisterElement = regCache.getFreeVertexConstant();

			initProjectionsRegs(regCache);
			vo.vertexConstantsIndex = dataReg.index*4;

			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();

			for (var i : int = 0; i < _cascadeShadowMapper.numCascades; ++i) {
				code += "m44 " + temp + ", " + _sharedRegisters.globalPositionVertex + ", " + _cascadeProjections[i] + "\n" +
						"add " + _depthMapCoordVaryings[i] + ", " + temp + ", " + dataReg + ".zzwz\n";
			}

			return code;
		}

		private function initProjectionsRegs(regCache : ShaderRegisterCache) : void
		{
			_cascadeProjections = new Vector.<ShaderRegisterElement>(_cascadeShadowMapper.numCascades);
			_depthMapCoordVaryings = new Vector.<ShaderRegisterElement>(_cascadeShadowMapper.numCascades);

			for (var i : int = 0; i < _cascadeShadowMapper.numCascades; ++i) {
				_depthMapCoordVaryings[i] = regCache.getFreeVarying();
				_cascadeProjections[i] = regCache.getFreeVertexConstant();
				regCache.getFreeVertexConstant();
				regCache.getFreeVertexConstant();
				regCache.getFreeVertexConstant();
			}
		}

		override arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var numCascades : int = _cascadeShadowMapper.numCascades;
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var planeDistanceReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var planeDistances : Vector.<String> = new <String>[ planeDistanceReg + ".x", planeDistanceReg + ".y", planeDistanceReg + ".z", planeDistanceReg + ".w" ];
			var code : String;

			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;

			var inQuad : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(inQuad, 1);
			var uvCoord : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvCoord, 1);

			// assume lowest partition is selected, will be overwritten later otherwise
			code = "mov " + uvCoord + ", " + _depthMapCoordVaryings[numCascades-1] + "\n";

			for (var i : int = numCascades - 2; i >= 0; --i) {
				var uvProjection : ShaderRegisterElement = _depthMapCoordVaryings[i];

				// calculate if in texturemap (result == 0 or 1, only 1 for a single partition)
				code += "slt " + inQuad + ".z, " + _sharedRegisters.projectionFragment + ".z, " + planeDistances[i] + "\n"; // z = x > minX, w = y > minY

				var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

				// linearly interpolate between old and new uv coords using predicate value == conditional toggle to new value if predicate == 1 (true)
				code += "sub " + temp + ", " + uvProjection + ", " + uvCoord + "\n" +
						"mul " + temp + ", " + temp + ", " + inQuad + ".z\n" +
						"add " + uvCoord + ", " + uvCoord + ", " + temp + "\n";
			}

			regCache.removeFragmentTempUsage(inQuad);

			code += "div " + uvCoord + ", " + uvCoord + ", " + uvCoord + ".w\n" +
					"mul " + uvCoord + ".xy, " + uvCoord + ".xy, " + dataReg + ".zw\n" +
					"add " + uvCoord + ".xy, " + uvCoord + ".xy, " + dataReg + ".zz\n";

			code += _baseMethod.getCascadeFragmentCode(vo, regCache, decReg, depthMapRegister, uvCoord, targetReg) +
					"add " + targetReg + ".w, " + targetReg + ".w, " + dataReg + ".y\n";


			regCache.removeFragmentTempUsage(uvCoord);

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));

			var vertexData : Vector.<Number> = vo.vertexData;
			var vertexIndex : int = vo.vertexConstantsIndex;
			vertexData[vertexIndex + 3] = -_epsilon;

			var numCascades : int = _cascadeShadowMapper.numCascades;
			vertexIndex += 4;
			for (var k : int = 0; k < numCascades; ++k) {
				_cascadeShadowMapper.getDepthProjections(k).copyRawDataTo(vertexData, vertexIndex, true);
				vertexIndex += 16;
			}

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var fragmentIndex : int = vo.fragmentConstantsIndex;
			fragmentData[uint(fragmentIndex + 5)] = 1-_alpha;

			var nearPlaneDistances : Vector.<Number> = _cascadeShadowMapper.nearPlaneDistances;

			fragmentIndex += 8;
			for (var i : uint = 0; i < numCascades; ++i)
				fragmentData[uint(fragmentIndex+i)] = nearPlaneDistances[i];


			_baseMethod.activateForCascade(vo,stage3DProxy);
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
		}

		private function onCascadeChange(event : Event) : void
		{
			invalidateShaderProgram();
		}

		private function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}
	}
}