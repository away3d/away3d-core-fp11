package away3d.materials.methods
{
    import away3d.arcane;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.Texture2DBase;

    use namespace arcane;
	
	/**
	 * AlphaMaskMethod allows the use of an additional texture to specify the alpha value of the material. When used
	 * with the secondary uv set, it allows for a tiled main texture with independently varying alpha (useful for water
	 * etc).
	 */
	public class EffectAlphaMaskMethod extends EffectMethodBase
	{
		private var _texture:Texture2DBase;
		private var _useSecondaryUV:Boolean;

		/**
		 * Creates a new AlphaMaskMethod object
		 * @param texture The texture to use as the alpha mask.
		 * @param useSecondaryUV Indicated whether or not the secondary uv set for the mask. This allows mapping alpha independently.
		 */
		public function EffectAlphaMaskMethod(texture:Texture2DBase, useSecondaryUV:Boolean = false)
		{
			super();
			_texture = texture;
			_useSecondaryUV = useSecondaryUV;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
            methodVO.needsSecondaryUV = _useSecondaryUV;
            methodVO.needsUV = !_useSecondaryUV;
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
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
            stage.activateTexture(methodVO.texturesIndex, _texture);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var textureReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			var uvReg:ShaderRegisterElement = _useSecondaryUV? sharedRegisters.secondaryUVVarying : sharedRegisters.uvVarying;
			methodVO.texturesIndex = textureReg.index;
			
			return ShaderCompilerHelper.getTex2DSampleCode(temp, sharedRegisters, textureReg, _texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, uvReg) +
				"mul " + targetReg + ", " + targetReg + ", " + temp + ".x\n";
		}
	}
}
