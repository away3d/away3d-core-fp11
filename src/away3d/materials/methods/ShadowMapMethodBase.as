package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.LightBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;

	import flash.display3D.Context3DProgramType;

	import flash.geom.Matrix3D;

	use namespace arcane;

	public class ShadowMapMethodBase extends ShadingMethodBase
	{
		private var _castingLight : LightBase;
		protected var _depthMapIndex : int;
		protected var _depthMapVar : ShaderRegisterElement;
		private var _depthProjIndex : int;
		private var _offsetData : Vector.<Number> = Vector.<Number>([.5, -.5, 1.0, 1.0]);
		private var _toTexIndex : int;
		protected var _data : Vector.<Number>;
		protected var _decIndex : int;
		private var _projMatrix : Matrix3D = new Matrix3D();


		public function ShadowMapMethodBase(castingLight : LightBase)
		{
			super(false, true, false);
			_castingLight = castingLight;
			castingLight.castsShadows = true;
			_data = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/16581375.0, -.003, 0, 0, 1]);
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

			_depthMapVar = null;
		}

		arcane override function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var toTexReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			var depthMapProj : ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			_depthProjIndex = depthMapProj.index;
			_depthMapVar = regCache.getFreeVarying();
			_toTexIndex = toTexReg.index;

			code += "m44 " + temp + ", vt0, " + depthMapProj + "\n" +
					"rcp " + temp+".w, " + temp+".w\n" +
					"mul " + temp+".xyz, " + temp+".xyz, " + temp+".w\n" +
					"mul " + temp+".xy, " + temp+".xy, " + toTexReg+".xy\n" +
					"add " + temp+".xy, " + temp+".xy, " + toTexReg+".xx\n" +
					"mov " + _depthMapVar+".xyz, " + temp+".xyz\n" +
					"mov " + _depthMapVar+".w, va0.w\n";

			return code;
		}

		arcane override function setRenderState(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lights : Vector.<LightBase>) : void
		{
			_projMatrix.copyFrom(_castingLight.shadowMapper.depthProjection);
			_projMatrix.prepend(renderable.sceneTransform);
			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _depthProjIndex, _projMatrix, true);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _toTexIndex, _offsetData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _decIndex, _data, 2);
			stage3DProxy.setTextureAt(_depthMapIndex, _castingLight.shadowMapper.getDepthMap(stage3DProxy));
		}
	}
}
