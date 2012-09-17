package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.PlanarReflectionTexture;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	/**
	 * PlanarReflectionMethod is a material method that adds reflections from a PlanarReflectionTexture object.
	 *
	 * @see away3d.textures.PlanarReflectionTexture
	 */
	public class PlanarReflectionMethod extends EffectMethodBase
	{
		private var _texture : PlanarReflectionTexture;
		private var _alpha : Number = 1;
		private var _normalDisplacement : Number = 0;

		/**
		 * Creates a new PlanarReflectionMethod
		 * @param texture The PlanarReflectionTexture used to render the reflected view.
		 * @param alpha The reflectiveness of the surface.
		 */
		public function PlanarReflectionMethod(texture : PlanarReflectionTexture, alpha : Number = 1)
		{
			super();
			_texture = texture;
			_alpha = alpha;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsProjection = true;
			vo.needsNormals = _normalDisplacement > 0;
		}

		/**
		 * The reflectiveness of the surface.
		 */
		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		/**
		 * The PlanarReflectionTexture used to render the reflected view.
		 */
		public function get texture() : PlanarReflectionTexture
		{
			return _texture;
		}

		public function set texture(value : PlanarReflectionTexture) : void
		{
			_texture = value;
		}

		/**
		 * The amount of displacement on the surface, for use with water waves.
		 */
		public function get normalDisplacement() : Number
		{
			return _normalDisplacement;
		}

		public function set normalDisplacement(value : Number) : void
		{
			if (_normalDisplacement == value) return;
			if (_normalDisplacement == 0 || value == 0) invalidateShaderProgram();
			_normalDisplacement = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			vo.fragmentData[vo.fragmentConstantsIndex] = _texture.textureRatioX*.5;
			vo.fragmentData[vo.fragmentConstantsIndex+1] = _texture.textureRatioY*.5;
			vo.fragmentData[vo.fragmentConstantsIndex+3] = _alpha;
			if(_normalDisplacement > 0) {
				vo.fragmentData[vo.fragmentConstantsIndex+2] = _normalDisplacement;
				vo.fragmentData[vo.fragmentConstantsIndex+4] = .5+_texture.textureRatioX*.5 - 1/_texture.width;
				vo.fragmentData[vo.fragmentConstantsIndex+5] = .5+_texture.textureRatioY*.5 - 1/_texture.height;
				vo.fragmentData[vo.fragmentConstantsIndex+6] = .5-_texture.textureRatioX*.5 + 1/_texture.width;
				vo.fragmentData[vo.fragmentConstantsIndex+7] = .5-_texture.textureRatioY*.5 + 1/_texture.height;
			}
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var textureReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();

			var filter : String = vo.useSmoothTextures? "linear" : "nearest";
			var code : String;
			vo.texturesIndex = textureReg.index;
			vo.fragmentConstantsIndex = dataReg.index*4;
			// fc0.x = .5

			var projectionReg : ShaderRegisterElement = _sharedRegisters.projectionFragment;

			regCache.addFragmentTempUsages(temp, 1);

			code = 	"div " + temp + ", " + projectionReg + ", " + projectionReg + ".w\n" +
					"mul " + temp + ", " + temp + ", " + dataReg + ".xyww\n" +
					"add " + temp + ".xy, " + temp + ".xy, fc0.xx\n";

			if (_normalDisplacement > 0) {
				var dataReg2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
				code += "add " + temp + ".w, " + projectionReg + ".w, " + "fc0.w\n" +
						"sub " + temp + ".z, fc0.w, " + _sharedRegisters.normalFragment + ".y\n" +
						"div " + temp + ".z, " + temp + ".z, " + temp + ".w\n" +
						"mul " + temp + ".z, " + dataReg + ".z, " + temp + ".z\n" +
						"add " + temp + ".x, " + temp + ".x, " + temp + ".z\n" +
						"min " + temp + ".x, " + temp + ".x, " + dataReg2 + ".x\n" +
						"max " + temp + ".x, " + temp + ".x, " + dataReg2 + ".z\n";
			}

			var temp2 : ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
			code += "tex " + temp + ", " + temp + ", " + textureReg + " <2d,"+filter+">\n" +
					"sub " + temp2 + ", " + temp + ".w,  fc0.x\n" +
					"kil " + temp2 + "\n" +
					"sub " + temp + ", " + temp + ", " + targetReg + "\n" +
					"mul " + temp + ", " + temp + ", " + dataReg + ".w\n" +
					"add " + targetReg + ", " + targetReg + ", " + temp + "\n";

			regCache.removeFragmentTempUsage(temp);

			return code;
		}
	}
}
