package away3d.materials.methods
{
	import away3d.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	// todo: provide filter method instead of subclasses, so cascade can use it too
	public class ShadowMapMethodBase extends ShadingMethodBase
	{
		private var _castingLight : LightBase;
		protected var _depthMapCoordReg : ShaderRegisterElement;
		private var _projMatrix : Matrix3D = new Matrix3D();
		private var _shadowMapper : ShadowMapperBase;

		protected var _usePoint : Boolean;
		private var _epsilon : Number;
		private var _alpha : Number = 1;


		public function ShadowMapMethodBase(castingLight : LightBase)
		{
			_usePoint = castingLight is PointLight;
			super();
			_castingLight = castingLight;
			castingLight.castsShadows = true;
			_shadowMapper = castingLight.shadowMapper;
			_epsilon = _usePoint? .01 : .002;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsView = true;
			vo.needsGlobalPos = _usePoint;
			vo.needsNormals = vo.numLights > 0;
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

			fragmentData[index+6] = 0;
			fragmentData[index+7] = 1;

			if (_usePoint) {
				fragmentData[index+8] = 0;
				fragmentData[index+9] = 0;
				fragmentData[index+10] = 0;
				fragmentData[index+11] = 1;
			}

			index = vo.vertexConstantsIndex;
			if (index != -1) {
				vertexData[index] = .5;
				vertexData[index + 1] = -.5;
				vertexData[index + 2] = 1.0;
				vertexData[index + 3] = 1.0;
			}
		}

		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		/**
		 * Wrappers that override the vertex shader need to set this explicitly
		 */
		arcane function get depthMapCoordReg() : ShaderRegisterElement
		{
			return _depthMapCoordReg;
		}

		arcane function set depthMapCoordReg(value : ShaderRegisterElement) : void
		{
			_depthMapCoordReg = value;
		}

		public function get castingLight() : LightBase
		{
			return _castingLight;
		}

		public function get epsilon() : Number
		{
			return _epsilon;
		}

		public function set epsilon(value : Number) : void
		{
			_epsilon = value;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();

			_depthMapCoordReg = null;
		}

		arcane override function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return _usePoint? getPointVertexCode(vo, regCache) : getPlanarVertexCode(vo, regCache);
		}

		protected function getPointVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			vo.vertexConstantsIndex = -1;
			return "";
		}

		protected function getPlanarVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			var toTexReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			var depthMapProj : ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			_depthMapCoordReg = regCache.getFreeVarying();
			vo.vertexConstantsIndex = (toTexReg.index-vo.vertexConstantsOffset)*4;

			code += "m44 " + temp + ", vt0, " + depthMapProj + "\n" +
					"rcp " + temp + ".w, " + temp + ".w\n" +
					"mul " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w\n" +
					"mul " + temp + ".xy, " + temp + ".xy, " + toTexReg + ".xy\n" +
					"add " + temp + ".xy, " + temp + ".xy, " + toTexReg + ".xx\n" +
					"mov " + _depthMapCoordReg + ".xyz, " + temp + ".xyz\n" +
					"mov " + _depthMapCoordReg + ".w, va0.w\n";

			return code;
		}

		arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = _usePoint? getPointFragmentCode(vo, regCache, targetReg) : getPlanarFragmentCode(vo, regCache, targetReg);
			code += "add " + targetReg + ".w, " + targetReg + ".w, fc" + (vo.fragmentConstantsIndex/4+1) + ".y\n" +
					"sat " + targetReg + ".w, " + targetReg + ".w\n";
			return code;
		}

		protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			throw new AbstractMethodError();
			return "";
		}

		protected function getPointFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			throw new AbstractMethodError();
			return "";
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			if (!_usePoint) {
				_projMatrix.copyFrom(DirectionalShadowMapper(_shadowMapper).depthProjection);
				_projMatrix.prepend(renderable.sceneTransform);
				_projMatrix.copyRawDataTo(vo.vertexData, vo.vertexConstantsIndex + 4, true);
			}
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			fragmentData[index+4] = -_epsilon;
			fragmentData[index+5] = 1-_alpha;
			if (_usePoint) {
				var pos : Vector3D = _castingLight.scenePosition;
				fragmentData[index+8] = pos.x;
				fragmentData[index+9] = pos.y;
				fragmentData[index+10] = pos.z;
				// used to decompress distance
				var f : Number = PointLight(_castingLight)._fallOff;
				fragmentData[index+11] = 1/(2*f*f);
			}
			stage3DProxy.setTextureAt(vo.texturesIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));
		}
	}
}
