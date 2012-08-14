package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.PlanarReflectionTexture;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	/**
	 * Allows the use of an additional texture to specify the alpha value of the material. When used with the secondary uv
	 * set, it allows for a tiled main texture with independently varying alpha (useful for water etc).
	 */
	public class PlanarReflectionMethod extends EffectMethodBase
	{
		private var _texture : PlanarReflectionTexture;
		private var _alpha : Number = 1;

		public function PlanarReflectionMethod(texture : PlanarReflectionTexture, alpha : Number = 1)
		{
			super();
			_texture = texture;
			_alpha = alpha;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			vo.fragmentData[vo.fragmentConstantsIndex+2] = .5;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsProjection = true;
			vo.needsUV = true;
		}

		public function get texture() : PlanarReflectionTexture
		{
			return _texture;
		}

		public function set texture(value : PlanarReflectionTexture) : void
		{
			_texture = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			vo.fragmentData[vo.fragmentConstantsIndex] = _texture.textureRatioX*.5;
			vo.fragmentData[vo.fragmentConstantsIndex+1] = _texture.textureRatioY*.5;
			vo.fragmentData[vo.fragmentConstantsIndex+3] = _alpha;
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var textureReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var filter : String = vo.useSmoothTextures? "linear" : "nearest";
			vo.texturesIndex = textureReg.index;
			vo.fragmentConstantsIndex = dataReg.index*4;

			return  "div " + temp + ", " + _projectionReg + ", " + _projectionReg + ".w\n" +
					"mul " + temp + ", " + temp + ", " + dataReg + ".xyww\n" +
					"add " + temp + ".xy, " + temp + ".xy, " + dataReg + ".z\n" +
					"tex " + temp + ", " + temp + ", " + textureReg + " <2d,"+filter+">\n" +
					"sub " + temp + ".w, " + temp + ".w,  " + dataReg + "z\n" +
					"kil " + temp + ".w\n" +
					"add " + temp + ".w, " + temp + ".w,  " + dataReg + "z\n" +
					"sub " + temp + ", " + temp + ", " + targetReg + "\n" +
					"mul " + temp + ", " + temp + ", " + dataReg + ".w\n" +
					"add " + targetReg + ", " + targetReg + ", " + temp + "\n";
		}
	}
}
