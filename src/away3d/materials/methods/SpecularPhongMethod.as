package away3d.materials.methods
{
	import away3d.*;
	import away3d.materials.compilation.*;
	
	use namespace arcane;

	/**
	 * PhongSpecularMethod provides a specular method that provides Phong highlights.
	 */
	public class SpecularPhongMethod extends SpecularBasicMethod
	{
		/**
		 * Creates a new PhongSpecularMethod object.
		 */
		public function SpecularPhongMethod()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(shaderObject:ShaderLightingObject, methodVO:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;
			
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(t, 1);
			}
			
			var viewDirReg:ShaderRegisterElement = sharedRegisters.viewDirFragment;
			var normalReg:ShaderRegisterElement = sharedRegisters.normalFragment;
			
			// phong model
			code += "dp3 " + t + ".w, " + lightDirReg + ", " + normalReg + "\n" + // sca1 = light.normal
				
				//find the reflected light vector R
				"add " + t + ".w, " + t + ".w, " + t + ".w\n" + // sca1 = sca1*2
				"mul " + t + ".xyz, " + normalReg + ", " + t + ".w\n" + // vec1 = normal*sca1
				"sub " + t + ".xyz, " + t + ", " + lightDirReg + "\n" + // vec1 = vec1 - light (light vector is negative)
				
				//smooth the edge as incidence angle approaches 90
				"add" + t + ".w, " + t + ".w, " + sharedRegisters.commons + ".w\n" + // sca1 = sca1 + smoothtep;
				"sat " + t + ".w, " + t + ".w\n" + // sca1 range 0 - 1
				"mul " + t + ".xyz, " + t + ", " + t + ".w\n" + // vec1 = vec1*sca1
				
				//find the dot product between R and V
				"dp3 " + t + ".w, " + t + ", " + viewDirReg + "\n" + // sca1 = vec1.view
				"sat " + t + ".w, " + t + ".w\n";
			
			if (_useTexture) {
				// apply gloss modulation from texture
				code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
					"pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
			} else
				code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";
			
			// attenuate
			if (shaderObject.usesLightFallOff)
				code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";
			
			if (_modulateMethod != null)
				code += _modulateMethod(methodVO, t, registerCache, sharedRegisters);
			
			code += "mul " + t + ".xyz, " + lightColReg + ".xyz, " + t + ".w\n";
			
			if (!_isFirstLight) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				registerCache.removeFragmentTempUsage(t);
			}
			
			_isFirstLight = false;
			
			return code;
		}
	}
}

