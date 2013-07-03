package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * AlphaMaskMethod allows the use of an additional texture to specify the alpha value of the material. When used
	 * with the secondary uv set, it allows for a tiled main texture with independently varying alpha (useful for water
	 * etc).
	 */
	public class AlphaMaskMethod extends EffectMethodBase
	{
		private var _texture:Texture2DBase;
		private var _useSecondaryUV:Boolean;

		/**
		 * Creates a new AlphaMaskMethod object
		 * @param texture The texture to use as the alpha mask.
		 * @param useSecondaryUV Indicated whether or not the secondary uv set for the mask. This allows mapping alpha independently.
		 */
		public function AlphaMaskMethod(texture:Texture2DBase, useSecondaryUV:Boolean = false)
		{
			super();
			_texture = texture;
			_useSecondaryUV = useSecondaryUV;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsSecondaryUV = _useSecondaryUV;
			vo.needsUV = !_useSecondaryUV;
		}

		/**
		 * Indicated whether or not the secondary uv set for the mask. This allows mapping alpha independently, for
		 * instance to tile the main texture and normal map while providing untiled alpha, for example to define the
		 * transparency over a tiled water surface.
		 */
		public function get useSecondaryUV():Boolean
		{
			return _useSecondaryUV;
		}
		
		public function set useSecondaryUV(value:Boolean):void
		{
			if (_useSecondaryUV == value)
				return;
			_useSecondaryUV = value;
			invalidateShaderProgram();
		}

		/**
		 * The texture to use as the alpha mask.
		 */
		public function get texture():Texture2DBase
		{
			return _texture;
		}
		
		public function set texture(value:Texture2DBase):void
		{
			_texture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg:ShaderRegisterElement = _useSecondaryUV? _sharedRegisters.secondaryUVVarying : _sharedRegisters.uvVarying;
			vo.texturesIndex = textureReg.index;
			
			return getTex2DSampleCode(vo, temp, textureReg, _texture, uvReg) +
				"mul " + targetReg + ", " + targetReg + ", " + temp + ".x\n";
		}
	}
}
