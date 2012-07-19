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

	/**
	 * ProjectiveTextureMethod is a material method used to project a texture unto the surface of an object.
	 * This can be used for various effects apart from acting like a normal projector, such as projecting fake shadows
	 * unto a surface, the impact of light coming through a stained glass window, ...
	 */
	public class ProjectiveTextureMethod extends EffectMethodBase
	{
		public static const MULTIPLY : String = "multiply";
		public static const ADD : String = "add";
		public static const MIX : String = "mix";

		private var _projector : TextureProjector;
		private var _uvVarying : ShaderRegisterElement;
		private var _projMatrix : Matrix3D = new Matrix3D();
		private var _mode : String;

		/**
		 * Creates a new ProjectiveTextureMethod object.
		 *
		 * @param projector The TextureProjector object that defines the projection properties as well as the texture.
		 * @param mode The blend mode with which the texture is blended unto the surface.
		 *
		 * @see away3d.entities.TextureProjector
		 */
		public function ProjectiveTextureMethod(projector : TextureProjector, mode : String = "multiply")
		{
			super();
			_projector = projector;
			_mode = mode;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = .5;
			data[index+1] = -.5;
			data[index+2] = 1.0;
			data[index+3] = 1.0
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_uvVarying = null;
		}

		/**
		 * The blend mode with which the texture is blended unto the object.
		 * ProjectiveTextureMethod.MULTIPLY can be used to project shadows. To prevent clamping, the texture's alpha should be white!
		 * ProjectiveTextureMethod.ADD can be used to project light, such as a slide projector or light coming through stained glass. To prevent clamping, the texture's alpha should be black!
		 * ProjectiveTextureMethod.MIX provides normal alpha blending. To prevent clamping, the texture's alpha should be transparent!
		 */
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

		/**
		 * The TextureProjector object that defines the projection properties as well as the texture.
		 *
		 * @see away3d.entities.TextureProjector
		 */
		public function get projector() : TextureProjector
		{
			return _projector;
		}

		public function set projector(value : TextureProjector) : void
		{
			_projector = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var projReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexVectorTemp();
			vo.vertexConstantsIndex = (projReg.index-vo.vertexConstantsOffset)*4;
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
			vo.fragmentConstantsIndex = toTexReg.index*4;
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
			_projMatrix.copyRawDataTo(vo.vertexData, vo.vertexConstantsIndex, true);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(vo.texturesIndex, _projector.texture.getTextureForStage3D(stage3DProxy));
		}
	}
}
