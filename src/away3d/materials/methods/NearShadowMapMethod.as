package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.LightBase;
	import away3d.lights.shadowmaps.NearDirectionalShadowMapper;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	// TODO: shadow mappers references in materials should be an interface so that this class should NOT extend ShadowMapMethodBase just for some delegation work
	public class NearShadowMapMethod extends ShadowMapMethodBase
	{
		private var _baseMethod : ShadowMapMethodBase;

		private var _dataIndex : int;
		private var _fadeRatio : Number;
		private var _shadowMapper : NearDirectionalShadowMapper;
		private var _light : LightBase;

		public function NearShadowMapMethod(baseMethod : ShadowMapMethodBase, fadeRatio : Number = .1)
		{
			super(baseMethod.castingLight);
			_baseMethod = baseMethod;
			_needsProjection = true;
			_fadeRatio = fadeRatio;
			_fragmentData = new Vector.<Number>(4, true);
			_fragmentData[2] = 0;
			_fragmentData[3] = 1;
			_light = baseMethod.castingLight;
			_shadowMapper = _light.shadowMapper as NearDirectionalShadowMapper;
			if (!_shadowMapper)
				throw new Error("NearShadowMapMethod requires a light that has a NearDirectionalShadowMapper instance assigned to shadowMapper.");
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

		/**
		 * @inheritDoc
		 */
		override arcane function set parentPass(value : MaterialPassBase) : void
		{
			super.parentPass = value;
			_baseMethod.parentPass = value;
		}


		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = _baseMethod.getFragmentPostLightingCode(regCache, targetReg);
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
			_dataIndex = dataReg.index;

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
		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			_baseMethod.activate(stage3DProxy);
		}

		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			_baseMethod.deactivate(stage3DProxy);
		}

		arcane override function setRenderState(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var near : Number = camera.lens.near;
			var d : Number = camera.lens.far - near;
			var maxDistance : Number = _shadowMapper.coverageRatio;
			var minDistance : Number = maxDistance*(1-_fadeRatio);

			maxDistance = near + maxDistance*d;
			minDistance = near + minDistance*d;

			_fragmentData[0] = minDistance;
			_fragmentData[1] = 1/(maxDistance-minDistance);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataIndex, _fragmentData,  1);
			_baseMethod.setRenderState(renderable, stage3DProxy, camera);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsUV() : Boolean
		{
			return _baseMethod.needsUV;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			return _baseMethod.getVertexCode(regCache);
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
		override arcane function get mipmap() : Boolean
		{
			return _mipmap;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set mipmap(value : Boolean) : void
		{
			_baseMethod.mipmap = _mipmap = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get smooth() : Boolean
		{
			return _smooth;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set smooth(value : Boolean) : void
		{
			_baseMethod.smooth = _smooth = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get repeat() : Boolean
		{
			return _repeat;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set repeat(value : Boolean) : void
		{
			_baseMethod.repeat = _repeat = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get numLights() : int
		{
			return _numLights;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set numLights(value : int) : void
		{
			_numLights = _baseMethod.numLights = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsGlobalPos() : Boolean
		{
			return _needsGlobalPos || _baseMethod.needsGlobalPos;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsView() : Boolean
		{
			return _needsView || _baseMethod.needsView;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function get needsNormals() : Boolean
		{
			return _needsNormals || _baseMethod.needsNormals;
		}

		arcane override function get needsProjection() : Boolean
		{
			return _needsProjection || _baseMethod.needsProjection;
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
	}
}
