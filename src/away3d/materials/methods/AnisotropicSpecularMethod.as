/**
 *
 */
package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class AnisotropicSpecularMethod extends BasicSpecularMethod
	{
		public function AnisotropicSpecularMethod()
		{
			super();
			_needsTangents = true;
			_needsView = true;
		}

		arcane override function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;

			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else t = _totalLightColorReg;

			// (sin(l,t) * sin(v,t) - cos(l,t)*cos(v,t)) ^ k

			code += "nrm " + t + ".xyz, " + _tangentVaryingReg + ".xyz\n" +
					"dp3 " + t + ".w, " + t + ".xyz, " + lightDirReg + ".xyz\n" +
					"dp3 " + t + ".z, " + t + ".xyz, " + _viewDirFragmentReg + ".xyz\n";

			// (sin(t.w) * sin(t.z) - cos(t.w)*cos(t.z)) ^ k
			code += "sin " + t + ".x, " + t + ".w\n" +
					"sin " + t + ".y, " + t + ".z\n" +
			// (t.x * t.y - cos(t.w)*cos(t.z)) ^ k
					"mul " + t + ".x, " + t + ".x, " + t + ".y\n" +
			// (t.x - cos(t.w)*cos(t.z)) ^ k
					"cos " + t + ".z, " + t + ".z\n" +
					"cos " + t + ".w, " + t + ".w\n" +
			// (t.x - t.w*t.z) ^ k
					"mul " + t + ".w, " + t + ".w, " + t + ".z\n" +
			// (t.x - t.w) ^ k
					"sub " + t + ".w, " + t + ".x, " + t + ".w\n";


			if (_useTexture) {
				// apply gloss modulation from texture
				code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
						"pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
			}
			else
				code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";

			// attenuate
			code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

			if (_modulateMethod != null) code += _modulateMethod(t, regCache);

			code += "mul " + t + ".xyz, " + lightColReg + ".xyz, " + t + ".w\n";

			if (lightIndex > 0) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}
	}
}
