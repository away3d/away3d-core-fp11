package away3d.materials.methods
{
	import away3d.arcane;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;

    use namespace arcane;
	
	/**
	 * DepthDiffuseMethod provides a debug method to visualise depth maps
	 */
	public class DiffuseDepthMethod extends DiffuseBasicMethod
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function DiffuseDepthMethod()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			var index:int = methodVO.fragmentConstantsIndex;
			data[index] = 1.0;
			data[index + 1] = 1/255.0;
			data[index + 2] = 1/65025.0;
			data[index + 3] = 1/16581375.0;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = "";
			var temp:ShaderRegisterElement;
			var decReg:ShaderRegisterElement;
			
			if (!_useTexture)
				throw new Error("DepthDiffuseMethod requires texture!");
			
			// incorporate input from ambient
			if (shaderObject.numLights > 0) {
				if (sharedRegisters.shadedTarget)
					code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + sharedRegisters.shadowTarget + ".w\n";
				code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz, " + targetReg + ".xyz\n" +
					"sat " + targetReg + ".xyz, " + targetReg + ".xyz\n";
				registerCache.removeFragmentTempUsage(_totalLightColorReg);
			}
			
			temp = shaderObject.numLights > 0? registerCache.getFreeFragmentVectorTemp() : targetReg;
			
			_diffuseInputRegister = registerCache.getFreeTextureReg();
			methodVO.texturesIndex = _diffuseInputRegister.index;
			decReg = registerCache.getFreeFragmentConstant();
			methodVO.fragmentConstantsIndex = decReg.index*4;
			code += ShaderCompilerHelper.getTex2DSampleCode(temp, sharedRegisters, _diffuseInputRegister, texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping) +
				"dp4 " + temp + ".x, " + temp + ", " + decReg + "\n" +
				"mov " + temp + ".yz, " + temp + ".xx			\n" +
				"mov " + temp + ".w, " + decReg + ".x\n" +
				"sub " + temp + ".xyz, " + decReg + ".xxx, " + temp + ".xyz\n";
			
			if (shaderObject.numLights == 0)
				return code;
			
			code += "mul " + targetReg + ".xyz, " + temp + ".xyz, " + targetReg + ".xyz\n" +
				"mov " + targetReg + ".w, " + temp + ".w\n";
			
			return code;
		}
	}
}
