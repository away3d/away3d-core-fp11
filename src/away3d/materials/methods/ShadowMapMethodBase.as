package away3d.materials.methods
{
	import away3d.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;

	import flash.display3D.Context3DProgramType;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	// todo: provide filter method instead of subclasses, so cascade can use it too
	public class ShadowMapMethodBase extends ShadingMethodBase
	{
		private var _castingLight : LightBase;
		protected var _depthMapIndex : int;
		protected var _depthMapCoordReg : ShaderRegisterElement;
		private var _depthProjIndex : int;
		private var _offsetData : Vector.<Number> = Vector.<Number>([.5, -.5, 1.0, 1.0]);
		private var _toTexIndex : int = -1;
		protected var _data : Vector.<Number>;
		protected var _decIndex : int;
		private var _projMatrix : Matrix3D = new Matrix3D();
		private var _shadowMapper : ShadowMapperBase;

		protected var _usePoint : Boolean;


		public function ShadowMapMethodBase(castingLight : LightBase)
		{
			_usePoint = castingLight is PointLight;
			super(false, true, _usePoint);
			_castingLight = castingLight;
			castingLight.castsShadows = true;
			_shadowMapper = castingLight.shadowMapper;
			var eps : Number = _usePoint? -.01 : -.002;
			_data = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/16581375.0, eps, 0, 0, 1, 0, 0, 0, 1]);
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
			return -_data[4];
		}

		public function set epsilon(value : Number) : void
		{
			_data[4] = -value;
		}


		arcane override function reset() : void
		{
			super.reset();
			_depthMapIndex = -1;
			_depthProjIndex = -1;
			_toTexIndex = -1;
			_decIndex = -1;
		}


		arcane override function set numLights(value : int) : void
		{
			super.numLights = value;
			_needsNormals = value > 0;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();

			_depthMapCoordReg = null;
		}

		arcane final override function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			return _usePoint? getPointVertexCode(regCache) : getPlanarVertexCode(regCache);
		}

		protected function getPointVertexCode(regCache : ShaderRegisterCache) : String
		{
			// nothing extra needed, we'll just get global pos
			return "";
		}

		protected function getPlanarVertexCode(regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var toTexReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			var depthMapProj : ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			_depthProjIndex = depthMapProj.index;
			_depthMapCoordReg = regCache.getFreeVarying();
			_toTexIndex = toTexReg.index;

			code += "m44 " + temp + ", vt0, " + depthMapProj + "\n" +
					"rcp " + temp + ".w, " + temp + ".w\n" +
					"mul " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w\n" +
					"mul " + temp + ".xy, " + temp + ".xy, " + toTexReg + ".xy\n" +
					"add " + temp + ".xy, " + temp + ".xy, " + toTexReg + ".xx\n" +
					"mov " + _depthMapCoordReg + ".xyz, " + temp + ".xyz\n" +
					"mov " + _depthMapCoordReg + ".w, va0.w\n";

			return code;
		}

		arcane final override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			return _usePoint? getPointFragmentCode(regCache, targetReg) : getPlanarFragmentCode(regCache, targetReg);
		}

		protected function getPlanarFragmentCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			throw new AbstractMethodError();
			return "";
		}

		protected function getPointFragmentCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			throw new AbstractMethodError();
			return "";
		}

		arcane override function setRenderState(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			if (!_usePoint) {
				_projMatrix.copyFrom(DirectionalShadowMapper(_shadowMapper).depthProjection);
				_projMatrix.prepend(renderable.sceneTransform);
				stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _depthProjIndex, _projMatrix, true);
			}

		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			// when wrapped (fe: cascade), it's possible this is not set
			if (_toTexIndex != -1)
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _toTexIndex, _offsetData, 1);

			if (_usePoint) {
				var pos : Vector3D = _castingLight.scenePosition;
				_data[8] = pos.x;
				_data[9] = pos.y;
				_data[10] = pos.z;
				// used to decompress distance
				var f : Number = PointLight(_castingLight)._fallOff;
				_data[11] = 1/(2*f*f);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _decIndex, _data, 3);
			}
			else {
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _decIndex, _data, 2);
			}
			stage3DProxy.setTextureAt(_depthMapIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));
		}
	}
}