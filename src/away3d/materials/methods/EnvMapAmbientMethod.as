package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.materials.utils.AGAL;
	import away3d.materials.utils.CubeMap;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;

	use namespace arcane;

	/**
	 * EnvMapDiffuseMethod provides a diffuse shading method that uses a diffuse irradiance environment map to
	 * approximate global lighting rather than lights.
	 */
	public class EnvMapAmbientMethod extends BasicAmbientMethod
	{
		private var _cubeTexture : CubeTexture3DProxy;
		private var _cubeMapIndex : int;

		/**
		 * Creates a new EnvMapDiffuseMethod object.
		 * @param envMap The cube environment map to use for the diffuse lighting.
		 */
		public function EnvMapAmbientMethod(envMap : CubeMap)
		{
			super();
			_cubeTexture = new CubeTexture3DProxy();
			_cubeTexture.cubeMap = envMap;
			_needsNormals = true;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			_cubeTexture.dispose(deep);
		}

		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public function get envMap() : CubeMap
		{
			return _cubeTexture.cubeMap;
		}

		public function set envMap(value : CubeMap) : void
		{
			_cubeTexture.cubeMap = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function set numLights(value : int) : void
		{
			super.numLights = value;
			_needsNormals = true;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(context : Context3D, contextIndex : uint) : void
		{
			super.activate(context, contextIndex);

			context.setTextureAt(_cubeMapIndex, _cubeTexture.getTextureForContext(context, contextIndex));
		}

		arcane override function deactivate(context : Context3D) : void
		{
			super.deactivate(context);

			context.setTextureAt(_cubeMapIndex, null);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			_cubeMapIndex = cubeMapReg.index;

			code += AGAL.sample(targetReg.toString(), _normalFragmentReg.toString(), "cube", cubeMapReg.toString(), "bilinear", "clamp");

			_ambientInputRegister = regCache.getFreeFragmentConstant();
			_ambientInputIndex = _ambientInputRegister.index;

			code += AGAL.add(targetReg+".xyz", targetReg+".xyz", _ambientInputRegister+".xyz");

			return code;
		}
	}
}
