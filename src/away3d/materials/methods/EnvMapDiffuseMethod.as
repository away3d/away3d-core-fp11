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
	public class EnvMapDiffuseMethod extends BasicDiffuseMethod
	{
		private var _cubeTexture : CubeTexture3DProxy;
		private var _cubeMapIndex : int;

		/**
		 * Creates a new EnvMapDiffuseMethod object.
		 * @param envMap The cube environment map to use for the diffuse lighting.
		 */
		public function EnvMapDiffuseMethod(envMap : CubeMap)
		{
			_cubeTexture = new CubeTexture3DProxy();
			_cubeTexture.cubeMap = envMap;
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
		arcane override function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			return "";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			return "";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			code += AGAL.sample(temp.toString(), _normalFragmentReg.toString(), "cube", cubeMapReg.toString(), "bilinear", "clamp");
			code += AGAL.add(temp+".xyz", temp+".xyz", targetReg+".xyz");
			code += AGAL.sat(temp+".xyz", temp+".xyz");

			_cubeMapIndex = cubeMapReg.index;

            if (_useTexture) {
				_diffuseInputRegister = regCache.getFreeTextureReg();
				code += getTexSampleCode(targetReg, _diffuseInputRegister);
			}
			else {
				_diffuseInputRegister = regCache.getFreeFragmentConstant();
				code += AGAL.mov(targetReg.toString(), _diffuseInputRegister.toString());
			}

			_diffuseInputIndex = _diffuseInputRegister.index;

			code += AGAL.mul(targetReg.toString(), targetReg.toString(), temp.toString());

			return code;
		}
	}
}
