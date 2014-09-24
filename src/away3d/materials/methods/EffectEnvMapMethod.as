package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.CubeTextureBase;
	import away3d.textures.Texture2DBase;
	
	import flash.display3D.Context3D;
	
	use namespace arcane;

	/**
	 * EnvMapMethod provides a material method to perform reflection mapping using cube maps.
	 */
	public class EffectEnvMapMethod extends EffectMethodBase
	{
		private var _cubeTexture:CubeTextureBase;
		private var _alpha:Number;
		private var _mask:Texture2DBase;

		/**
		 * Creates an EnvMapMethod object.
		 * @param envMap The environment map containing the reflected scene.
		 * @param alpha The reflectivity of the surface.
		 */
		public function EffectEnvMapMethod(envMap:CubeTextureBase, alpha:Number = 1)
		{
			super();
			_cubeTexture = envMap;
			_alpha = alpha;
		}

		/**
		 * An optional texture to modulate the reflectivity of the surface.
		 */
		public function get mask():Texture2DBase
		{
			return _mask;
		}
		
		public function set mask(value:Texture2DBase):void
		{
			if (Boolean(value) != Boolean(_mask) ||
				(value && _mask && (value.hasMipMaps != _mask.hasMipMaps || value.format != _mask.format))) {
				invalidateShaderProgram();
			}
			_mask = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			methodVO.needsNormals = true;
			methodVO.needsView = true;
			methodVO.needsUV = _mask != null;
		}
		
		/**
		 * The cubic environment map containing the reflected scene.
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
		override public function dispose():void
		{
		}
		
		/**
		 * The reflectivity of the surface.
		 */
		public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			_alpha = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
            shaderObject.fragmentConstantData[methodVO.fragmentConstantsIndex] = _alpha;
            stage.activateCubeTexture(methodVO.texturesIndex, _cubeTexture);
			if (_mask)
				stage.activateTexture(methodVO.texturesIndex+1, _mask);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var dataRegister:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			var code:String = "";
			var cubeMapReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
            methodVO.texturesIndex = cubeMapReg.index;
            methodVO.fragmentConstantsIndex = dataRegister.index*4;

            registerCache.addFragmentTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			
			// r = I - 2(I.N)*N
			code += "dp3 " + temp + ".w, " + sharedRegisters.viewDirFragment + ".xyz, " + sharedRegisters.normalFragment + ".xyz		\n" +
				"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
				"mul " + temp + ".xyz, " + sharedRegisters.normalFragment + ".xyz, " + temp + ".w						\n" +
				"sub " + temp + ".xyz, " + temp + ".xyz, " + sharedRegisters.viewDirFragment + ".xyz					\n" +
                ShaderCompilerHelper.getTexCubeSampleCode(temp, cubeMapReg, _cubeTexture, shaderObject.useSmoothTextures, shaderObject.useMipmapping, temp) +
				"sub " + temp2 + ".w, " + temp + ".w, fc0.x									\n" +               	// -.5
				"kil " + temp2 + ".w\n" +	// used for real time reflection mapping - if alpha is not 1 (mock texture) kil output
				"sub " + temp + ", " + temp + ", " + targetReg + "											\n";
			
			if (_mask) {
				var maskReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
				code += ShaderCompilerHelper.getTex2DSampleCode(temp2, sharedRegisters, registerCache.getFreeTextureReg(), _mask, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping) +
					"mul " + temp + ", " + temp2 + ", " + temp + "\n";
			}
			code += "mul " + temp + ", " + temp + ", " + dataRegister + ".x										\n" +
				"add " + targetReg + ", " + targetReg + ", " + temp + "										\n";

            registerCache.removeFragmentTempUsage(temp);
			
			return code;
		}
	}
}
