package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
	import away3d.entities.DirectionalLight;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;

	/**
	 * DitheredShadowMapMethod provides a softened shadowing technique by bilinearly interpolating shadow comparison
	 * results of neighbouring pixels.
	 */
	public class ShadowFilteredMethod extends ShadowMethodBase
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 *
		 * @param castingLight The light casting the shadow
		 */
		public function ShadowFilteredMethod(castingLight:DirectionalLight)
		{
			super(castingLight);
		}

		/**
		 * @inheritDoc
		 */
        override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			super.initConstants(shaderObject, methodVO);
			
			var fragmentData:Vector.<Number> = shaderObject.fragmentConstantData;
			var index:int = methodVO.fragmentConstantsIndex;
			fragmentData[index + 8] = .5;
			var size:int = castingLight.shadowMapper.depthMapSize;
			fragmentData[index + 9] = size;
			fragmentData[index + 10] = 1/size;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(methodVO:MethodVO, targetReg:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var depthMapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			// TODO: not used
			dataReg = dataReg;
			var customDataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg:ShaderRegisterElement;
			var code:String = "";
			methodVO.fragmentConstantsIndex = decReg.index*4;
			
			regCache.addFragmentTempUsages(depthCol, 1);
			
			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);
			
			code += "mov " + uvReg + ", " + _depthMapCoordReg + "\n" +
				
				"tex " + depthCol + ", " + _depthMapCoordReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".z, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" +   // 0 if in shadow
				
				"add " + uvReg + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".z\n" + 	// (1, 0)
				"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".w, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" +   // 0 if in shadow
				
				"mul " + depthCol + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".y\n" +
				"frc " + depthCol + ".x, " + depthCol + ".x\n" +
				"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z\n" +
				"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x\n" +
				"add " + targetReg + ".w, " + uvReg + ".z, " + uvReg + ".w\n" +
				
				"mov " + uvReg + ".x, " + _depthMapCoordReg + ".x\n" +
				"add " + uvReg + ".y, " + _depthMapCoordReg + ".y, " + customDataReg + ".z\n" +	// (0, 1)
				"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".z, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" +   // 0 if in shadow
				
				"add " + uvReg + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".z\n" +	// (1, 1)
				"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d, nearest, clamp>\n" +
				"dp4 " + depthCol + ".z, " + depthCol + ", " + decReg + "\n" +
				"slt " + uvReg + ".w, " + _depthMapCoordReg + ".z, " + depthCol + ".z\n" +   // 0 if in shadow
				
				// recalculate fraction, since we ran out of registers :(
				"mul " + depthCol + ".x, " + _depthMapCoordReg + ".x, " + customDataReg + ".y\n" +
				"frc " + depthCol + ".x, " + depthCol + ".x\n" +
				"sub " + uvReg + ".w, " + uvReg + ".w, " + uvReg + ".z\n" +
				"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x\n" +
				"add " + uvReg + ".w, " + uvReg + ".z, " + uvReg + ".w\n" +
				
				"mul " + depthCol + ".x, " + _depthMapCoordReg + ".y, " + customDataReg + ".y\n" +
				"frc " + depthCol + ".x, " + depthCol + ".x\n" +
				"sub " + uvReg + ".w, " + uvReg + ".w, " + targetReg + ".w\n" +
				"mul " + uvReg + ".w, " + uvReg + ".w, " + depthCol + ".x\n" +
				"add " + targetReg + ".w, " + targetReg + ".w, " + uvReg + ".w\n";
			
			regCache.removeFragmentTempUsage(depthCol);
			regCache.removeFragmentTempUsage(uvReg);
			
			methodVO.texturesIndex = depthMapRegister.index;
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activateForCascade(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			var size:int = _castingLight.shadowMapper.depthMapSize;
			var index:int = methodVO.secondaryFragmentConstantsIndex;
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			data[index] = size;
			data[index + 1] = 1/size;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getCascadeFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement, targetRegister:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String;
			var dataReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			methodVO.secondaryFragmentConstantsIndex = dataReg.index*4;
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			registerCache.addFragmentTempUsages(temp, 1);
			var predicate:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			registerCache.addFragmentTempUsages(predicate, 1);
			
			code = "tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".x, " + depthProjection + ".z, " + temp + ".z\n" +
				
				"add " + depthProjection + ".x, " + depthProjection + ".x, " + dataReg + ".y\n" +
				"tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".z, " + depthProjection + ".z, " + temp + ".z\n" +
				
				"add " + depthProjection + ".y, " + depthProjection + ".y, " + dataReg + ".y\n" +
				"tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".w, " + depthProjection + ".z, " + temp + ".z\n" +
				
				"sub " + depthProjection + ".x, " + depthProjection + ".x, " + dataReg + ".y\n" +
				"tex " + temp + ", " + depthProjection + ", " + depthTexture + " <2d, nearest, clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
				"slt " + predicate + ".y, " + depthProjection + ".z, " + temp + ".z\n" +
				
				"mul " + temp + ".xy, " + depthProjection + ".xy, " + dataReg + ".x\n" +
				"frc " + temp + ".xy, " + temp + ".xy\n" +
				
				// some strange register juggling to prevent agal bugging out
				"sub " + depthProjection + ", " + predicate + ".xyzw, " + predicate + ".zwxy\n" +
				"mul " + depthProjection + ", " + depthProjection + ", " + temp + ".x\n" +
				
				"add " + predicate + ".xy, " + predicate + ".xy, " + depthProjection + ".zw\n" +
				
				"sub " + predicate + ".y, " + predicate + ".y, " + predicate + ".x\n" +
				"mul " + predicate + ".y, " + predicate + ".y, " + temp + ".y\n" +
				"add " + targetRegister + ".w, " + predicate + ".x, " + predicate + ".y\n";
			
			registerCache.removeFragmentTempUsage(temp);
            registerCache.removeFragmentTempUsage(predicate);
			return code;
		}
	}
}
