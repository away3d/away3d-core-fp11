package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;

	/**
	 * LightMapDiffuseMethod provides a diffuse shading method that uses a light map to modulate the calculated diffuse
	 * lighting. It is different from LightMapMethod in that the latter modulates the entire calculated pixel color, rather
	 * than only the diffuse lighting value.
	 */
	public class LightMapDiffuseMethod extends CompositeDiffuseMethod
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
		
		private var _texture:Texture2DBase;
		private var _blendMode:String;
		private var _useSecondaryUV:Boolean;

		/**
		 * Creates a new LightMapDiffuseMethod method.
		 * @param lightMap The texture containing the light map.
		 * @param blendMode The blend mode with which the light map should be applied to the lighting result.
		 * @param useSecondaryUV Indicates whether the secondary UV set should be used to map the light map.
		 * @param baseMethod The diffuse method used to calculate the regular light-based lighting.
		 */
		public function LightMapDiffuseMethod(lightMap:Texture2DBase, blendMode:String = "multiply", useSecondaryUV:Boolean = false, baseMethod:BasicDiffuseMethod = null)
		{
			super(null, baseMethod);
			_useSecondaryUV = useSecondaryUV;
			_texture = lightMap;
			this.blendMode = blendMode;
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
		 * The blend mode with which the light map should be applied to the lighting result.
		 *
		 * @see LightMapDiffuseMethod.ADD
		 * @see LightMapDiffuseMethod.MULTIPLY
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
			return _texture;
		}
		
		public function set lightMapTexture(value:Texture2DBase):void
		{
			_texture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			stage3DProxy._context3D.setTextureAt(vo.secondaryTexturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			super.activate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String;
			var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			vo.secondaryTexturesIndex = lightMapReg.index;
			
			code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _sharedRegisters.secondaryUVVarying);
			
			switch (_blendMode) {
				case MULTIPLY:
					code += "mul " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
				case ADD:
					code += "add " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
			}
			
			code += super.getFragmentPostLightingCode(vo, regCache, targetReg);
			
			return code;
		}
	}
}
