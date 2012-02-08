package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	use namespace arcane;

	public class BasicNormalMethod extends ShadingMethodBase
	{
		private var _texture : Texture2DBase;
		private var _useTexture : Boolean;
		protected var _normalMapIndex : int = -1;
		protected var _normalTextureRegister : ShaderRegisterElement;

		public function BasicNormalMethod()
		{
			super(false, false, false);
		}

		arcane function get tangentSpace() : Boolean
		{
			return true;
		}

		/**
		 * Override this is normal method output is not based on a texture (if not, it will usually always return true)
		 */
		arcane function get hasOutput() : Boolean
		{
			return _useTexture;
		}

		override public function copyFrom(method : ShadingMethodBase) : void
		{
			normalMap = BasicNormalMethod(method).normalMap;
		}

		arcane override function get needsUV() : Boolean
		{
			return Boolean(_texture);
		}

		public function get normalMap() : Texture2DBase
		{
			return _texture;
		}

		public function set normalMap(value : Texture2DBase) : void
		{
			if (!value || !_useTexture) invalidateShaderProgram();
			_useTexture = Boolean(value);
			_texture = value;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_normalTextureRegister = null;
		}

		arcane override function reset() : void
		{
			_normalMapIndex = -1;
		}

		override public function dispose() : void
		{
			if (_texture) _texture = null;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			if (_normalMapIndex >= 0) stage3DProxy.setTextureAt(_normalMapIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			_normalTextureRegister = regCache.getFreeTextureReg();
			_normalMapIndex = _normalTextureRegister.index;
			return getTexSampleCode(targetReg, _normalTextureRegister);
		}
	}
}
