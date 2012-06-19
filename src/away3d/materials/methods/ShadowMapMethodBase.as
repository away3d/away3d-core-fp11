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
		private var _vertexData : Vector.<Number> = Vector.<Number>([.5, -.5, 1.0, 1.0]);
		private var _vertexDataIndex : int = -1;
		protected var _fragmentData : Vector.<Number>;
		protected var _fragmentDataIndex : int;
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
			_fragmentData = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/16581375.0, eps, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]);
		}

		public function get alpha() : Number
		{
			return 1-_fragmentData[5];
		}

		public function set alpha(value : Number) : void
		{
			_fragmentData[5] = 1-value;
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
			return -_fragmentData[4];
		}

		public function set epsilon(value : Number) : void
		{
			_fragmentData[4] = -value;
		}


		arcane override function reset() : void
		{
			super.reset();
			_depthMapIndex = -1;
			_depthProjIndex = -1;
			_vertexDataIndex = -1;
			_fragmentDataIndex = -1;
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

		arcane override function getVertexCode(regCache : ShaderRegisterCache) : String
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
			_vertexDataIndex = toTexReg.index;

			code += "m44 " + temp + ", vt0, " + depthMapProj + "\n" +
					"rcp " + temp + ".w, " + temp + ".w\n" +
					"mul " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w\n" +
					"mul " + temp + ".xy, " + temp + ".xy, " + toTexReg + ".xy\n" +
					"add " + temp + ".xy, " + temp + ".xy, " + toTexReg + ".xx\n" +
					"mov " + _depthMapCoordReg + ".xyz, " + temp + ".xyz\n" +
					"mov " + _depthMapCoordReg + ".w, va0.w\n";

			return code;
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = _usePoint? getPointFragmentCode(regCache, targetReg) : getPlanarFragmentCode(regCache, targetReg);
			code += "add " + targetReg + ".w, " + targetReg + ".w, fc" + (_fragmentDataIndex+1) + ".y\n" +
					"sat " + targetReg + ".w, " + targetReg + ".w\n";
			return code;
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
			if (_vertexDataIndex != -1)
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _vertexDataIndex, _vertexData, 1);

			if (_usePoint) {
				var pos : Vector3D = _castingLight.scenePosition;
				_fragmentData[12] = pos.x;
				_fragmentData[13] = pos.y;
				_fragmentData[14] = pos.z;
				// used to decompress distance
				var f : Number = PointLight(_castingLight)._fallOff;
				_fragmentData[15] = 1/(2*f*f);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _fragmentDataIndex, _fragmentData, 4);
			}
			else {
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _fragmentDataIndex, _fragmentData, 3);
			}
			stage3DProxy.setTextureAt(_depthMapIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));
		}
	}
}