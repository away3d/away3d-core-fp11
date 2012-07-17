package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display.BitmapData;

	use namespace arcane;

	public class LightMapDiffuseMethod extends CompositeDiffuseMethod
	{
		public static const MULTIPLY : String = "multiply";
		public static const ADD : String = "add";

		private var _texture : Texture2DBase;
		private var _lightMapIndex : int;
		private var _blendMode : String;

		public function LightMapDiffuseMethod(lightMap : Texture2DBase, blendMode : String = "multiply", useSecondaryUV : Boolean = false, baseMethod : BasicDiffuseMethod = null)
		{
			super(null, baseMethod);
			_needsSecondaryUV = useSecondaryUV;
			_needsUV = !useSecondaryUV;

			this.blendMode = blendMode;
			_texture = lightMap;
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

		public function get lightMapTexture() : Texture2DBase
		{
			return _texture;
		}

		public function set lightMapTexture(value : Texture2DBase) : void
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

			code = getTexSampleCode(temp, lightMapReg, _secondaryUVFragmentReg);

			switch (_blendMode) {
				case MULTIPLY:
					code += "mul " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
				case ADD:
					code += "add " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
			}

			code += super.getFragmentPostLightingCode(regCache, targetReg);

			return code;
		}
	}
}
