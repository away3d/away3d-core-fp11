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

		/**
		 * Create a new ShadingMethodBase ob	ject.
		 * @param needsNormals Defines whether or not the method requires normals.
		 * @param needsView Defines whether or not the method requires the view direction.
		 */
		public function LightingMethodBase(needsNormals : Boolean, needsView : Boolean, needsGlobalPos : Boolean)
		{
			super(needsNormals, needsView, needsGlobalPos);
		}

		/**
		 * Get the fragment shader code that will be needed before any per-light code is added.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			// TODO: not used
			regCache = regCache;
			return "";
		}

		/**
		 * Get the fragment shader code that will generate the code relevant to a single light.
		 */
		arcane function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			// TODO: not used
			lightIndex = lightIndex;
			lightDirReg = lightDirReg; 
			lightColReg = lightColReg;
			regCache = regCache;  			
			return "";
		}

		/**
		 * Get the fragment shader code that will generate the code relevant to a single light probe object.
		 * @param lightIndex The index of the light currently processed. This is a continuation of the lightIndex parameter of the getFragmentCodePerLight method.
		 * @param cubeMapReg The register containing the cube map for the current probe
		 * @param weightRegister A string representation of the register + component containing the current weight
		 * @param regCache The register cache providing any necessary registers to the shader
		 */
		arcane function getFragmentCodePerProbe(lightIndex : int, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			// TODO: not used
			cubeMapReg = cubeMapReg;
			lightIndex = lightIndex;
			weightRegister = weightRegister;
			regCache = regCache;
			// lightIndex will just continue on from code per light
			return "";
		}
	}
}
