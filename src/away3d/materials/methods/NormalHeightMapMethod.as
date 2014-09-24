package away3d.materials.methods
{
	import away3d.arcane;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.methods.NormalHeightMapMethod;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.Texture2DBase;
	
	use namespace arcane;

	/**
	 * HeightMapNormalMethod provides a normal map method that uses a height map to calculate the normals.
	 */
	public class NormalHeightMapMethod extends NormalBasicMethod
	{
		private var _worldXYRatio:Number;
		private var _worldXZRatio:Number;

		/**
		 * Creates a new HeightMapNormalMethod method.
		 * @param heightMap The texture containing the height data. 0 means low, 1 means high.
		 * @param worldWidth The width of the 'world'. This is used to map uv coordinates' u component to scene dimensions.
		 * @param worldHeight The height of the 'world'. This is used to map the height map values to scene dimensions.
		 * @param worldDepth The depth of the 'world'. This is used to map uv coordinates' v component to scene dimensions.
		 */
		public function NormalHeightMapMethod(heightMap:Texture2DBase, worldWidth:Number, worldHeight:Number, worldDepth:Number)
		{
			super();
			normalMap = heightMap;
			_worldXYRatio = worldWidth/worldHeight;
			_worldXZRatio = worldDepth/worldHeight;
		}

		/**
		 * @inheritDoc
		 */
        override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			var index:int = methodVO.fragmentConstantsIndex;
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			data[index] = 1/normalMap.width;
			data[index + 1] = 1/normalMap.height;
			data[index + 2] = 0;
			data[index + 3] = 1;
			data[index + 4] = _worldXYRatio;
			data[index + 5] = _worldXZRatio;
		}

		/**
		 * @inheritDoc
		 */
		arcane function get tangentSpace():Boolean
		{
			return false;
		}

		/**
		 * @inheritDoc
		 */
		override public function copyFrom(method:ShadingMethodBase):void
		{
			super.copyFrom(method);
			_worldXYRatio = NormalHeightMapMethod(method)._worldXYRatio;
			_worldXZRatio = NormalHeightMapMethod(method)._worldXZRatio;
		}

		/**
		 * @inheritDoc
		 */
        arcane override function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			var dataReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			var dataReg2:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			_normalTextureRegister = registerCache.getFreeTextureReg();
			methodVO.texturesIndex = _normalTextureRegister.index;
			methodVO.fragmentConstantsIndex = dataReg.index*4;
			
			return ShaderCompilerHelper.getTex2DSampleCode(targetReg, sharedRegisters, _normalTextureRegister, normalMap, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, sharedRegisters.uvVarying, "clamp") +
				
				"add " + temp + ", " + sharedRegisters.uvVarying + ", " + dataReg + ".xzzz\n" +
                ShaderCompilerHelper.getTex2DSampleCode(temp, sharedRegisters, _normalTextureRegister, normalMap, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, temp, "clamp") +
				"sub " + targetReg + ".x, " + targetReg + ".x, " + temp + ".x\n" +
				
				"add " + temp + ", " + sharedRegisters.uvVarying + ", " + dataReg + ".zyzz\n" +
                ShaderCompilerHelper.getTex2DSampleCode(temp, sharedRegisters, _normalTextureRegister, normalMap, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, temp, "clamp") +
				"sub " + targetReg + ".z, " + targetReg + ".z, " + temp + ".x\n" +
				
				"mov " + targetReg + ".y, " + dataReg + ".w\n" +
				"mul " + targetReg + ".xz, " + targetReg + ".xz, " + dataReg2 + ".xy\n" +
				"nrm " + targetReg + ".xyz, " + targetReg + ".xyz\n";
		}
	}
}
