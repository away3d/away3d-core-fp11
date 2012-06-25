package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.TextureProjector;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class ProjectiveTextureMethod extends EffectMethodBase
	{
		public static const MULTIPLY : String = "multiply";
		public static const ADD : String = "add";
		public static const MIX : String = "mix";

		private var _offsetData : Vector.<Number> = Vector.<Number>([.5, -.5, 1.0, 1.0]);
		private var _projector : TextureProjector;
		private var _uvVarying : ShaderRegisterElement;
		private var _projMatrix : Matrix3D = new Matrix3D();
		private var _mode : String;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function ProjectiveTextureMethod(projector : TextureProjector, mode : String = "multiply")
		{
			super();
			_projector = projector;
			_mode = mode;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_uvVarying = null;
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

		arcane override function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var projReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexVectorTemp();
			vo.vertexConstantsIndex = projReg.index;
			_uvVarying = regCache.getFreeVarying();

			return "m44 " + _uvVarying + ", vt0, " + projReg + "\n";
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var mapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var col : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var toTexReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = toTexReg.index;
			vo.texturesIndex = mapRegister.index;

			code += "div " + col + ", " + _uvVarying + ", " + _uvVarying + ".w						\n" +
					"mul " + col + ".xy, " + col + ".xy, " + toTexReg+".xy	\n" +
					"add " + col + ".xy, " + col + ".xy, " + toTexReg+".xx	\n" +
					"tex " + col + ", " + col + ", " + mapRegister + " <2d,linear,miplinear,clamp>\n";

			if (_mode == MULTIPLY)
				code += "mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n";
			else if (_mode == ADD)
				code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n";
			else if (_mode == MIX) {
				code += "sub " + col + ".xyz, " + col + ".xyz, " + targetReg + ".xyz				\n" +
						"mul " + col + ".xyz, " + col + ".xyz, " + col + ".w						\n" +
						"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n";
			}
			else {
				throw new Error("Unknown mode \""+_mode+"\"");
			}

			return code;
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			_projMatrix.copyFrom(_projector.viewProjection);
			_projMatrix.prepend(renderable.sceneTransform);
			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vo.vertexConstantsIndex, _projMatrix, true);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, vo.fragmentConstantsIndex, _offsetData, 1);
			stage3DProxy.setTextureAt(vo.texturesIndex, _projector.texture.getTextureForStage3D(stage3DProxy));
		}
	}
}
