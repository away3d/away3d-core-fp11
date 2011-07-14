package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.core.managers.Stage3DProxy;
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
		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			super.activate(stage3DProxy);

			stage3DProxy.setTextureAt(_cubeMapIndex, _cubeTexture.getTextureForContext(stage3DProxy));
		}

//		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
//		{
//			super.deactivate(stage3DProxy);
//
//			stage3DProxy.setTextureAt(_cubeMapIndex, null);
//		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			_cubeMapIndex = cubeMapReg.index;

			code += "tex " + targetReg + ", " + _normalFragmentReg + ", " + cubeMapReg + " <cube,linear,clamp>\n";

			_ambientInputRegister = regCache.getFreeFragmentConstant();
			_ambientInputIndex = _ambientInputRegister.index;

			code += "add " + targetReg+".xyz, " + targetReg+".xyz, " + _ambientInputRegister+".xyz\n";

			return code;
		}
	}
}
