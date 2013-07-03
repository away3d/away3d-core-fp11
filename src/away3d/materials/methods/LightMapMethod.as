package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;

	/**
	 * LightMapMethod provides a method that allows applying a light map texture to the calculated pixel colour.
	 * It is different from LightMapDiffuseMethod in that the latter only modulates the diffuse shading value rather
	 * than the whole pixel colour.
	 */
	public class LightMapMethod extends EffectMethodBase
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
		public function LightMapMethod(texture:Texture2DBase, blendMode:String = "multiply", useSecondaryUV:Boolean = false)
		{
			super();
			_useSecondaryUV = useSecondaryUV;
			_texture = texture;
			this.blendMode = blendMode;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsUV = !_useSecondaryUV;
			vo.needsSecondaryUV = _useSecondaryUV;
		}

		/**
		 * The blend mode with which the light map should be applied to the lighting result.
		 *
		 * @see LightMapMethod.ADD
		 * @see LightMapMethod.MULTIPLY
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
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			super.activate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String;
			var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			vo.texturesIndex = lightMapReg.index;
			
			code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _useSecondaryUV? _sharedRegisters.secondaryUVVarying : _sharedRegisters.uvVarying);
			
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
