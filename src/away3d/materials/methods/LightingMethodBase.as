package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	/**
	 * LightingMethodBase provides an abstract base method for shading methods that uses lights.
	 * Used for diffuse and specular shaders only.
	 */
	public class LightingMethodBase extends ShadingMethodBase
	{
		/**
		 * A method that is exposed to wrappers in case the strength needs to be controlled
		 */
		arcane var _modulateMethod : Function;

		public function LightingMethodBase()
		{
			super();
		}

		/**
		 * Get the fragment shader code that will be needed before any per-light code is added.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			return "";
		}

		/**
		 * Get the fragment shader code that will generate the code relevant to a single light.
		 */
		arcane function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			return "";
		}

		/**
		 * Get the fragment shader code that will generate the code relevant to a single light probe object.
		 * @param lightIndex The index of the light currently processed. This is a continuation of the lightIndex parameter of the getFragmentCodePerLight method.
		 * @param cubeMapReg The register containing the cube map for the current probe
		 * @param weightRegister A string representation of the register + component containing the current weight
		 * @param regCache The register cache providing any necessary registers to the shader
		 */
		arcane function getFragmentCodePerProbe(vo : MethodVO, lightIndex : int, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			// lightIndex will just continue on from code per light
			return "";
		}

		/**
		 * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			return "";
		}
	}
}
