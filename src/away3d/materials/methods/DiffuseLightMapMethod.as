package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.Texture2DBase;
	
	use namespace arcane;

	/**
	 * LightMapDiffuseMethod provides a diffuse shading method that uses a light map to modulate the calculated diffuse
	 * lighting. It is different from LightMapMethod in that the latter modulates the entire calculated pixel color, rather
	 * than only the diffuse lighting value.
	 */
	public class DiffuseLightMapMethod extends DiffuseCompositeMethod
	{
		/**
		 * Indicates the light map should be multiplied with the calculated shading result.
		 * This can be used to add pre-calculated shadows or occlusion.
		 */
		public static const MULTIPLY:String = "multiply";

		/**
		 * Indicates the light map should be added into the calculated shading result.
		 * This can be used to add pre-calculated lighting or global illumination.
		 */
		public static const ADD:String = "add";
		
		private var _lightMapTexture:Texture2DBase;
		private var _blendMode:String;
		private var _useSecondaryUV:Boolean;

		/**
		 * Creates a new LightMapDiffuseMethod method.
		 * @param lightMap The texture containing the light map.
		 * @param blendMode The blend mode with which the light map should be applied to the lighting result.
		 * @param useSecondaryUV Indicates whether the secondary UV set should be used to map the light map.
		 * @param baseMethod The diffuse method used to calculate the regular light-based lighting.
		 */
		public function DiffuseLightMapMethod(lightMap:Texture2DBase, blendMode:String = "multiply", useSecondaryUV:Boolean = false, baseMethod:DiffuseBasicMethod = null)
		{
			super(null, baseMethod);
			_useSecondaryUV = useSecondaryUV;
			_lightMapTexture = lightMap;
			this.blendMode = blendMode;
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
		 * The blend mode with which the light map should be applied to the lighting result.
		 *
		 * @see DiffuseLightMapMethod.ADD
		 * @see DiffuseLightMapMethod.MULTIPLY
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
		 * The texture containing the light map data.
		 */
		public function get lightMapTexture():Texture2DBase
		{
			return _lightMapTexture;
		}
		
		public function set lightMapTexture(value:Texture2DBase):void
		{
			_lightMapTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
            stage.activateTexture(methodVO.secondaryTexturesIndex, _lightMapTexture);
			super.activate(shaderObject, methodVO, stage);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String;
			var lightMapReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			methodVO.secondaryTexturesIndex = lightMapReg.index;
			
			code = ShaderCompilerHelper.getTex2DSampleCode(temp, sharedRegisters, lightMapReg, this._lightMapTexture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, sharedRegisters.secondaryUVVarying);
			
			switch (_blendMode) {
				case MULTIPLY:
					code += "mul " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
				case ADD:
					code += "add " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
			}
			
			code += super.getFragmentPostLightingCode(shaderObject, methodVO, targetReg, registerCache, sharedRegisters);
			
			return code;
		}
	}
}
