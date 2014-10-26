package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
	import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderCompilerBase;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.CubeTextureBase;
	
	use namespace arcane;
	
	/**
	 * EnvMapDiffuseMethod provides a diffuse shading method that uses a diffuse irradiance environment map to
	 * approximate global lighting rather than lights.
	 */
	public class AmbientEnvMapMethod extends AmbientBasicMethod
	{
		private var _cubeTexture:CubeTextureBase;
		
		/**
		 * Creates a new EnvMapDiffuseMethod object.
		 * @param envMap The cube environment map to use for the diffuse lighting.
		 */
		public function AmbientEnvMapMethod(envMap:CubeTextureBase)
		{
			super();
			_cubeTexture = envMap;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(shaderObject:ShaderObjectBase, vo:MethodVO):void
		{
			super.initVO(shaderObject, vo);

			vo.needsNormals = true;
		}
		
		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public function get envMap():CubeTextureBase
		{
			return _cubeTexture;
		}
		
		public function set envMap(value:CubeTextureBase):void
		{
			_cubeTexture = value;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			super.activate(shaderObject, methodVO, stage);

            stage.activateTexture(methodVO.texturesIndex, _cubeTexture);
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = "";
            var ambientInputRegister:ShaderRegisterElement;
			var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			methodVO.texturesIndex = cubeMapReg.index;
			
			code += ShaderCompilerHelper.getTexCubeSampleCode(targetReg, cubeMapReg, this._cubeTexture, shaderObject.useSmoothTextures, shaderObject.useMipmapping, sharedRegisters.normalFragment);
			
			ambientInputRegister = regCache.getFreeFragmentConstant();
            methodVO.fragmentConstantsIndex = ambientInputRegister.index;
			
			code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + ambientInputRegister + ".xyz\n";
			
			return code;
		}
	}
}
