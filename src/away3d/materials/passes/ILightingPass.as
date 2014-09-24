package away3d.materials.passes {
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;

    public interface ILightingPass extends IMaterialPass {

        /**
         * The amount of point lights that need to be supported.
         */
        function get numPointLights():int;

        /**
         * The amount of directional lights that need to be supported.
         */
        function get numDirectionalLights():int;

        /**
         * The amount of light probes that need to be supported.
         */
        function get numLightProbes():int;

        /**
         * Indicates the offset in the light picker's directional light vector for which to start including lights.
         * This needs to be set before the light picker is assigned.
         */
        function get directionalLightsOffset():Number;

        /**
         * Indicates the offset in the light picker's point light vector for which to start including lights.
         * This needs to be set before the light picker is assigned.
         */
        function get pointLightsOffset():Number;

        /**
         * Indicates the offset in the light picker's light probes vector for which to start including lights.
         * This needs to be set before the light picker is assigned.
         */
        function get lightProbesOffset():Number;

        function usesSpecular():Boolean

        function usesShadows():Boolean

        function getPerLightDiffuseFragmentCode(shaderObject:ShaderLightingObject, lightDirReg:ShaderRegisterElement, diffuseColorReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getPerLightSpecularFragmentCode(shaderObject:ShaderLightingObject, lightDirReg:ShaderRegisterElement, specularColorReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getPerProbeDiffuseFragmentCode(shaderObject:ShaderLightingObject, texReg:ShaderRegisterElement, weightReg:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getPerProbeSpecularFragmentCode(shaderObject:ShaderLightingObject, texReg:ShaderRegisterElement, weightReg:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getPostLightingVertexCode(shaderObject:ShaderLightingObject, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getPostLightingFragmentCode(shaderObject:ShaderLightingObject, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

    }
}
