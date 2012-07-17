package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	public class LightMapMethod extends EffectMethodBase
	{
		public static const MULTIPLY : String = "multiply";
		public static const ADD : String = "add";

		private var _texture : Texture2DBase;

		private var _blendMode : String;
		private var _useSecondaryUV : Boolean;

		public function LightMapMethod(texture : Texture2DBase, blendMode : String = "multiply", useSecondaryUV : Boolean = false)
		{
			super();
			_useSecondaryUV = useSecondaryUV;
			_texture = texture;
			this.blendMode = blendMode;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsUV = !_useSecondaryUV;
			vo.needsSecondaryUV = _useSecondaryUV;
		}

		public function get blendMode() : String
		{
			return _blendMode;
		}

		public function set blendMode(value : String) : void
		{
			if (value != ADD && value != MULTIPLY) throw new Error("Unknown blendmode!");
			if (_blendMode == value) return;
			_blendMode = value;
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

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			super.activate(vo, stage3DProxy);
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String;
			var lightMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			vo.texturesIndex = lightMapReg.index;

			code = getTexSampleCode(vo, temp, lightMapReg, _useSecondaryUV? _secondaryUVFragmentReg : _uvFragmentReg);

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
