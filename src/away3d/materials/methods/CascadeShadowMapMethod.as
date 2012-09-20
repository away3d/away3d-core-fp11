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
	import away3d.materials.compilation.ShaderRegisterElement;

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

			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsGlobalVertexPos = true;
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

			fragmentData[index+8] = 0.04;
			fragmentData[index+9] = .96;
			fragmentData[index+10] = -.96;
			fragmentData[index+11] = -0.04;

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
			vo.vertexConstantsIndex = (dataReg.index-vo.vertexConstantsOffset)*4;

			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();

			for (var i : int = 0; i < _cascadeShadowMapper.numCascades; ++i) {
				code += "m44 " + temp + ", " + _sharedRegisters.globalPositionVertex + ", " + _cascadeProjections[i] + "\n" +
						"div " + temp + ", " + temp + ", " + temp + ".w\n" +
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
			var boundsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var minBounds : Vector.<String> = new <String>[	boundsReg + ".x", boundsReg + ".z", boundsReg + ".z", boundsReg + ".z", boundsReg + ".x", boundsReg + ".x", boundsReg + ".z", boundsReg + ".x" ];
			var maxBounds : Vector.<String> = new <String>[	boundsReg + ".y", boundsReg + ".w", boundsReg + ".w", boundsReg + ".w", boundsReg + ".y", boundsReg + ".y", boundsReg + ".w", boundsReg + ".y" ];
			var code : String;
			var boundIndex : int = (4-numCascades)*2;

			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;

			var inQuad : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(inQuad, 1);
			var uvCoord : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvCoord, 1);

			// assume lowest partition is selected, will be overwritten later otherwise
			code = "mov " + uvCoord + ", " + _depthMapCoordVaryings[0] + "\n";

			for (var i : int = 1; i < numCascades; ++i) {
				boundIndex += 2;
				var uvProjection : ShaderRegisterElement = _depthMapCoordVaryings[i];

				// calculate if in texturemap (result == 0 or 1, only 1 for a single partition)
				code += "sge " + inQuad + ".z, " + uvProjection + ".x, " + minBounds[boundIndex] + "\n" + // z = x > minX, w = y > minY
						"sge " + inQuad + ".w, " + uvProjection + ".y, " + minBounds[boundIndex+1] + "\n" + // z = x > minX, w = y > minY
						"sge " + inQuad + ".x, " + maxBounds[boundIndex] + ", " + uvProjection + ".x \n" + // z = x < maxX, w = y < maxY
						"sge " + inQuad + ".y, " + maxBounds[boundIndex+1] + ", " + uvProjection + ".y\n" + // z = x < maxX, w = y < maxY

						// if all are true (so point is in this quad), then the multiplication of all == 1, if any is 0, multiplication is 0
						// this is basically (x && y) && (z && w)
						"mul " + inQuad + ".xz, " + inQuad + ".xz, " + inQuad + ".yw\n" +
						"mul " + inQuad + ".z, " + inQuad + ".z, " + inQuad + ".x\n";

				var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

				// linearly interpolate between old and new uv coords using predicate value == conditional toggle to new value if predicate == 1 (true)
				code += "sub " + temp + ", " + uvProjection + ", " + uvCoord + "\n" +
						"mul " + temp + ", " + temp + ", " + inQuad + ".z\n" +
						"add " + uvCoord + ", " + uvCoord + ", " + temp + "\n";
			}

			regCache.removeFragmentTempUsage(inQuad);

			code += "mul " + uvCoord + ".xy, " + uvCoord + ".xy, " + dataReg + ".zw\n" +
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
			stage3DProxy.setTextureAt(vo.texturesIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));

			var vertexData : Vector.<Number> = vo.vertexData;
			var vertexIndex : int = vo.vertexConstantsIndex;
			vertexData[vertexIndex + 3] = -_epsilon;

			var numCascades : int = _cascadeShadowMapper.numCascades;
			var k : int = numCascades;

			vertexIndex += 4;
			for (var i : uint = 0; i < numCascades; ++i) {
				_cascadeShadowMapper.getDepthProjections(--k).copyRawDataTo(vertexData, vertexIndex, true);
				vertexIndex += 16;
			}

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var fragmentIndex : int = vo.fragmentConstantsIndex;
			fragmentData[fragmentIndex + 5] = 1-_alpha;

			_baseMethod.activateForCascade(vo,stage3DProxy);
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{

		}

		private function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}
	}
}