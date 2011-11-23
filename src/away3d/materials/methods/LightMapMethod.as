package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	public class LightMapMethod extends ShadingMethodBase
	{
		public static const MULTIPLY : String = "multiply";
		public static const ADD : String = "add";

		private var _texture : Texture2DBase;
		private var _lightMapIndex : int;

		private var _blendMode : String;

		public function LightMapMethod(texture : Texture2DBase, blendMode : String = "multiply", useSecondaryUV : Boolean = false)
		{
			super(false, !useSecondaryUV, false);

			_needsSecondaryUV = useSecondaryUV;
			this.blendMode = blendMode;

			_texture = texture;
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

		arcane override function reset() : void
		{
			super.reset();
			_lightMapIndex = -1;
		}

		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			_texture = value;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setTextureAt(_lightMapIndex, _texture.getTextureForStage3D(stage3DProxy));
			super.activate(stage3DProxy);
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String;
			var lightMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			_lightMapIndex = lightMapReg.index;

			code = getTexSampleCode(temp, lightMapReg, _needsSecondaryUV? _secondaryUVFragmentReg : _uvFragmentReg);

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
