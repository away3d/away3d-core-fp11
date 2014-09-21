package away3d.materials.methods {
    import away3d.arcane;
    import away3d.core.library.AssetType;
    import away3d.core.library.IAsset;
    import away3d.errors.AbstractMethodError;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;

    use namespace arcane;

    /**
     * EffectMethodBase forms an abstract base class for shader methods that are not dependent on light sources,
     * and are in essence post-process effects on the materials.
     */
    public class EffectMethodBase extends ShadingMethodBase implements IAsset {
        public function EffectMethodBase()
        {
            super();
        }

        /**
         * @inheritDoc
         */
        override public function get assetType():String
        {
            return AssetType.EFFECTS_METHOD;
        }

        /**
         * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
         * @param vo The MethodVO object containing the method data for the currently compiled material pass.
         * @param regCache The register cache used during the compilation.
         * @param targetReg The register that will be containing the method's output.
         * @private
         */
        override arcane function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            throw new AbstractMethodError();
            return "";
        }
    }
}
