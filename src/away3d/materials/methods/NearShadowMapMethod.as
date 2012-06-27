package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.lights.LightBase;
	import away3d.lights.shadowmaps.NearDirectionalShadowMapper;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	// TODO: shadow mappers references in materials should be an interface so that this class should NOT extend ShadowMapMethodBase just for some delegation work
	public class NearShadowMapMethod extends ShadowMapMethodBase
	{
		private var _baseMethod : ShadowMapMethodBase;

		private var _fadeRatio : Number;
		private var _shadowMapper : NearDirectionalShadowMapper;
		private var _light : LightBase;

		public function NearShadowMapMethod(baseMethod : ShadowMapMethodBase, fadeRatio : Number = .1)
		{
			super(baseMethod.castingLight);
			_baseMethod = baseMethod;
			_fadeRatio = fadeRatio;
			_light = baseMethod.castingLight;
			_shadowMapper = _light.shadowMapper as NearDirectionalShadowMapper;
			if (!_shadowMapper)
				throw new Error("NearShadowMapMethod requires a light that has a NearDirectionalShadowMapper instance assigned to shadowMapper.");
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);
			_baseMethod.initConstants(vo);

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			fragmentData[index+2] = 0;
			fragmentData[index+3] = 1;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			_baseMethod.initVO(vo);
			vo.needsProjection = true;
		}

		override public function dispose() : void
		{
			_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		override public function get alpha() : Number
		{
			return _baseMethod.alpha;
		}

		override public function set alpha(value : Number) : void
		{
			_baseMethod.alpha = value;
		}

		override public function get epsilon() : Number
		{
			return _baseMethod.epsilon;
		}

		override public function set epsilon(value : Number) : void
		{
			_baseMethod.epsilon = value;
		}

		public function get fadeRatio() : Number
		{
			return _fadeRatio;
		}

		public function set fadeRatio(value : Number) : void
		{
			_fadeRatio = value;
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = _baseMethod.getFragmentCode(vo, regCache, targetReg);
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
			vo.secondaryFragmentConstantsIndex = dataReg.index*4;

			code +=	"abs " + temp + ", " + _projectionReg + ".w\n" +
					"sub " + temp + ", " + temp + ", " + dataReg + ".x\n" +
					"mul " + temp + ", " + temp + ", " + dataReg + ".y\n" +
					"sat " + temp + ", " + temp + "\n" +
					"sub " + temp + ", " + dataReg + ".w," + temp + "\n" +
					"sub " + targetReg + ".w, " + dataReg + ".w," + targetReg + ".w\n" +
					"mul " + targetReg + ".w, " + targetReg + ".w, " + temp + "\n" +
					"sub " + targetReg + ".w, " + dataReg + ".w," + targetReg + ".w\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			_baseMethod.activate(vo, stage3DProxy);
		}

		arcane override function deactivate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			_baseMethod.deactivate(vo, stage3DProxy);
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			// todo: move this to activate (needs camera)
			var near : Number = camera.lens.near;
			var d : Number = camera.lens.far - near;
			var maxDistance : Number = _shadowMapper.coverageRatio;
			var minDistance : Number = maxDistance*(1-_fadeRatio);

			maxDistance = near + maxDistance*d;
			minDistance = near + minDistance*d;

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			fragmentData[index] = minDistance;
			fragmentData[index+1] = 1/(maxDistance-minDistance);
			_baseMethod.setRenderState(vo, renderable, stage3DProxy, camera);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return _baseMethod.getVertexCode(vo, regCache);
		}


		/**
		 * @inheritDoc
		 */
		override arcane function reset() : void
		{
			_baseMethod.reset();
		}


		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_baseMethod.cleanCompilationData();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set globalPosReg(value : ShaderRegisterElement) : void
		{
			_baseMethod.globalPosReg = _globalPosReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set UVFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseMethod.UVFragmentReg = _uvFragmentReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set secondaryUVFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseMethod.secondaryUVFragmentReg = _secondaryUVFragmentReg = value;
		}

		override arcane function set viewDirFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseMethod.viewDirFragmentReg = _viewDirFragmentReg = value;
		}

		override public function set viewDirVaryingReg(value : ShaderRegisterElement) : void
		{
			_viewDirVaryingReg = _baseMethod.viewDirVaryingReg = value;
		}


		arcane override function set projectionReg(value : ShaderRegisterElement) : void
		{
			_projectionReg = _baseMethod.projectionReg = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set normalFragmentReg(value : ShaderRegisterElement) : void
		{
			_baseMethod.normalFragmentReg = _normalFragmentReg = value;
		}

		private function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}
	}
}
