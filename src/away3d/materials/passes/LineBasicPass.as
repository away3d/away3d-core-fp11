package away3d.materials.passes {
    import away3d.arcane;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;

    use namespace arcane;

    public class LineBasicPass extends MaterialPassBase{
        public function LineBasicPass()
        {
        }

        override public function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var targetReg:ShaderRegisterElement = sharedRegisters.shadedTarget;
            return "mov " + targetReg + ", v0\n";
        }
    }
}
