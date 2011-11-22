package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	/**
	 * Allows the use of an additional texture to specify the alpha value of the material. When used with the secondary uv
	 * set, it allows for a tiled main texture with independently varying alpha (useful for water etc).
	 */
	public class AlphaMaskMethod extends ShadingMethodBase
	{
		private var _textureMapIndex : int;
		private var _texture : Texture2DBase;
		private var _useSecondaryUV : Boolean;

		public function AlphaMaskMethod(texture : Texture2DBase, useSecondaryUV : Boolean = false)
		{
			super(true, true, false);
			_texture = texture;
			_useSecondaryUV = useSecondaryUV;
			_needsUV = !useSecondaryUV;
		}

		public function get useSecondaryUV() : Boolean
		{
			return _useSecondaryUV;
		}

		public function set useSecondaryUV(value : Boolean) : void
		{
			if (_useSecondaryUV == value) return;
			_useSecondaryUV = value;
			_needsUV = !value;
			invalidateShaderProgram();
		}

		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			_texture = value;
		}

		arcane override function get needsSecondaryUV() : Boolean
		{
			return _useSecondaryUV;
		}

		arcane override function get needsUV() : Boolean
		{
			return !_useSecondaryUV;
		}

		arcane override function reset() : void
		{
			super.reset();
			_textureMapIndex = -1;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(_textureMapIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var textureReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement = _useSecondaryUV? _secondaryUVFragmentReg : _uvFragmentReg;
			_textureMapIndex = textureReg.index;

			return 	getTexSampleCode(temp, textureReg, uvReg) +
					"mul " + targetReg + ", " + targetReg + ", " + temp + ".x\n";
		}
	}
}
