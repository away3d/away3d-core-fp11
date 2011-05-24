package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.entities.TextureProjector;
	import away3d.lights.LightBase;
	import away3d.materials.utils.AGAL;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class ProjectiveTextureMethod extends ShadingMethodBase
	{
		public static const MULTIPLY : String = "multiply";
		public static const ADD : String = "add";
		public static const MIX : String = "mix";

		private var _offsetData : Vector.<Number> = Vector.<Number>([.5, -.5, 1.0, 1.0]);
		private var _projector : TextureProjector;
		private var _projectionIndex : int;
		private var _uvVarying : ShaderRegisterElement;
		private var _toTexIndex : int;
		private var _projMatrix : Matrix3D = new Matrix3D();
		private var _mapIndex : int;
		private var _mode : String;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function ProjectiveTextureMethod(projector : TextureProjector, mode : String = "multiply")
		{
			super(false, false, false);
			_projector = projector;
			_mode = mode;
		}

		public function get mode() : String
		{
			return _mode;
		}

		public function set mode(value : String) : void
		{
			if (_mode == value) return;
			_mode = value;
			invalidateShaderProgram();
		}

		public function get projector() : TextureProjector
		{
			return _projector;
		}

		public function set projector(value : TextureProjector) : void
		{
			_projector = value;
		}

		arcane override function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var toTexReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			var projReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			_projectionIndex = projReg.index;
			_uvVarying = regCache.getFreeVarying();
			_toTexIndex = toTexReg.index;
			code += AGAL.m44(temp.toString(), "vt0", projReg.toString());
			code += AGAL.div(temp.toString(), temp.toString(), temp+".w");
			code += AGAL.mul(temp+".xy", temp+".xy", toTexReg+".xy");
			code += AGAL.add(temp+".xy", temp+".xy", toTexReg+".xx");
			code += AGAL.mov(_uvVarying.toString(), temp.toString());
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var mapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var col : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			_mapIndex = mapRegister.index;

			code += AGAL.sample(col.toString(), _uvVarying.toString(), "2d", mapRegister.toString(), "trilinear", "clamp");
			if (_mode == MULTIPLY)
				code += AGAL.mul(targetReg+".xyz", targetReg+".xyz", col+".xyz");
			else if (_mode == ADD)
				code += AGAL.add(targetReg+".xyz", targetReg+".xyz", col+".xyz");
			else if (_mode == MIX) {
				code += AGAL.sub(col+".xyz", col+".xyz", targetReg+".xyz");
                code += AGAL.mul(col+".xyz", col+".xyz", col+".w");
                code += AGAL.add(targetReg+".xyz", targetReg+".xyz", col+".xyz");
			}
			else {
				throw new Error("Unknown mode \""+_mode+"\"");
			}

			return code;
		}

		arcane override function setRenderState(renderable : IRenderable, context : Context3D, contextIndex : uint, camera : Camera3D, lights : Vector.<LightBase>) : void
		{
			_projMatrix.copyFrom(_projector.viewProjection);
			_projMatrix.prepend(renderable.sceneTransform);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _projectionIndex, _projMatrix, true);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(context : Context3D, contextIndex : uint) : void
		{
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _toTexIndex, _offsetData, 1);
			context.setTextureAt(_mapIndex, _projector.texture.getTextureForContext(context, contextIndex));
		}

		arcane override function deactivate(context : Context3D) : void
		{
			context.setTextureAt(_mapIndex, null);
		}
	}
}
