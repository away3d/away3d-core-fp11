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
	 * LightMapMethod provides a method that allows applying a light map texture to the calculated pixel colour.
	 * It is different from LightMapDiffuseMethod in that the latter only modulates the diffuse shading value rather
	 * than the whole pixel colour.
	 */
	public class EffectLightMapMethod extends EffectMethodBase
	{
		/**
		 * Indicates the light map should be multiplied with the calculated shading result.
		 */
		public static const MULTIPLY:String = "multiply";

		/**
		 * Indicates the light map should be added into the calculated shading result.
		 */
		public static const ADD:String = "add";
		
		private var _texture:Texture2DBase;
		
		private var _blendMode:String;
		private var _useSecondaryUV:Boolean;

		/**
		 * Creates a new LightMapMethod object.
		 * @param texture The texture containing the light map.
		 * @param blendMode The blend mode with which the light map should be applied to the lighting result.
		 * @param useSecondaryUV Indicates whether the secondary UV set should be used to map the light map.
		 */
		public function EffectLightMapMethod(texture:Texture2DBase, blendMode:String = "multiply", useSecondaryUV:Boolean = false)
		{
			super();
			_useSecondaryUV = useSecondaryUV;
			_texture = texture;
			this.blendMode = blendMode;
		}

		/**
		 * @inheritDoc
		 */
        override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			methodVO.needsUV = !_useSecondaryUV;
            methodVO.needsSecondaryUV = _useSecondaryUV;
		}

		/**
		 * The blend mode with which the light map should be applied to the lighting result.
		 *
		 * @see EffectLightMapMethod.ADD
		 * @see EffectLightMapMethod.MULTIPLY
		 */
		public function get blendMode():String
		{
			return _blendMode;
		}
		
		public function set blendMode(value:String):void
		{
			if (value != ADD && value != MULTIPLY)
				throw new Error("Unknown blendmode!");
			if (_blendMode == value)
				return;
			_blendMode = value;
			invalidateShaderProgram();
		}
		
		/**
		 * Return true if the LightMap should use the secondary UV
		 */
		public function get useSecondaryUV():Boolean
		{
			return _useSecondaryUV;
		}
		/**
		 * The texture containing the light map.
		 */
		public function get texture():Texture2DBase
		{
			return _texture;
		}
		
		public function set texture(value:Texture2DBase):void
		{
			if (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)
				invalidateShaderProgram();
			_texture = value;
		}

		/**
		 * @inheritDoc
		 */
        arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			stage.activateTexture(methodVO.texturesIndex, _texture);
			super.activate(shaderObject,methodVO,stage);
		}

		/**
		 * @inheritDoc
		 */
        arcane override function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String;
			var lightMapReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			methodVO.texturesIndex = lightMapReg.index;
			
			code = ShaderCompilerHelper.getTex2DSampleCode(temp, sharedRegisters, lightMapReg, _texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, _useSecondaryUV? sharedRegisters.secondaryUVVarying : sharedRegisters.uvVarying);
			
			switch (_blendMode) {
				case MULTIPLY:
					code += "mul " + targetReg + ", " + targetReg + ", " + temp + "\n";
					break;
				case ADD:
					code += "add " + targetReg + ", " + targetReg + ", " + temp + "\n";
					break;
			}
			
			return code;
		}
	}
}
