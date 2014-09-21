package away3d.materials.methods {
    import away3d.arcane;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;

    use namespace arcane;

    /**
     * LightingMethodBase provides an abstract base method for shading methods that uses lights.
     * Used for diffuse and specular shaders only.
     */
    public class LightingMethodBase extends ShadingMethodBase {
        /**
         * A method that is exposed to wrappers in case the strength needs to be controlled
         */
        arcane var _modulateMethod:Function;

        /**
         * Creates a new LightingMethodBase.
         */
        public function LightingMethodBase()
        {
            super();
        }

        /**
         * Get the fragment shader code that will be needed before any per-light code is added.
         * @param methodVO The MethodVO object containing the method data for the currently compiled material pass.
         * @param regCache The register cache used during the compilation.
         * @private
         */
        arcane function getFragmentPreLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        /**
         * Get the fragment shader code that will generate the code relevant to a single light.
         *
         * @param methodVO The MethodVO object containing the method data for the currently compiled material pass.
         * @param lightDirReg The register containing the light direction vector.
         * @param lightColReg The register containing the light colour.
         * @param regCache The register cache used during the compilation.
         */
        arcane function getFragmentCodePerLight(shaderObject:ShaderLightingObject, methodVO:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        /**
         * Get the fragment shader code that will generate the code relevant to a single light probe object.
         *
         * @param methodVO The MethodVO object containing the method data for the currently compiled material pass.
         * @param cubeMapReg The register containing the cube map for the current probe
         * @param weightRegister A String representation of the register + component containing the current weight
         * @param regCache The register cache providing any necessary registers to the shader
         */
        arcane function getFragmentCodePerProbe(shaderObject:ShaderLightingObject, methodVO:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        /**
         * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
         *
         * @param methodVO The MethodVO object containing the method data for the currently compiled material pass.
         * @param regCache The register cache used during the compilation.
         * @param targetReg The register containing the final shading output.
         * @private
         */
        arcane function getFragmentPostLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }
    }
}
