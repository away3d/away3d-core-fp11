package away3d.materials.methods {
    import away3d.arcane;
    import away3d.core.library.NamedAssetBase;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.events.ShadingMethodEvent;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.passes.MaterialPassBase;

    use namespace arcane;

    /**
     * ShadingMethodBase provides an abstract base method for shading methods, used by compiled passes to compile
     * the final shading program.
     */
    public class ShadingMethodBase extends NamedAssetBase {
        protected var _passes:Vector.<MaterialPassBase>;

        /**
         * Create a new ShadingMethodBase object.
         */
        public function ShadingMethodBase()
        {
        }


        arcane function isUsed(shaderObject:ShaderObjectBase):Boolean
        {
            return true;
        }

        /**
         * Initializes the properties for a MethodVO, including register and texture indices.
         *
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         *
         * @internal
         */
        arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {

        }

        /**
         * Initializes unchanging shader constants using the data from a MethodVO.
         *
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         *
         * @internal
         */
        arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {


        }

        /**
         * Indicates whether or not this method expects normals in tangent space. Override for object-space normals.
         */
        arcane function usesTangentSpace():Boolean
        {
            return true;
        }

        /**
         * Any passes required that render to a texture used by this method.
         */
        public function get passes():Vector.<MaterialPassBase>
        {
            return _passes;
        }

        /**
         * Cleans up any resources used by the current object.
         */
        override public function dispose():void
        {

        }

        /**
         * Resets the compilation state of the method.
         *
         * @internal
         */
        arcane function reset():void
        {
            cleanCompilationData();
        }

        /**
         * Resets the method's state for compilation.
         *
         * @internal
         */
        arcane function cleanCompilationData():void
        {
        }

        /**
         * Get the vertex shader code for this method.
         * @param vo The MethodVO object linking this method with the pass currently being compiled.
         * @param regCache The register cache used during the compilation.
         *
         * @internal
         */
        arcane function getVertexCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        /**
         * @inheritDoc
         */
        arcane function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return null;
        }

        /**
         * Sets the render state for this method.
         *
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         * @param stage The Stage object currently used for rendering.
         *
         * @internal
         */
        arcane function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
        {

        }

        /**
         * Sets the render state for a single renderable.
         *
         * @param vo The MethodVO object linking this method with the pass currently being compiled.
         * @param renderable The renderable currently being rendered.
         * @param stage The Stage object currently used for rendering.
         * @param camera The camera from which the scene is currently rendered.
         *
         * @internal
         */
        public function setRenderState(shaderObject:ShaderObjectBase, methodVO:MethodVO, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D):void
        {

        }

        /**
         * Clears the render state for this method.
         * @param vo The MethodVO object linking this method with the pass currently being compiled.
         * @param stage The Stage object currently used for rendering.
         *
         * @internal
         */
        arcane function deactivate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
        {

        }

        /**
         * Marks the shader program as invalid, so it will be recompiled before the next render.
         *
         * @internal
         */
        arcane function invalidateShaderProgram():void
        {
            dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
        }

        /**
         * Copies the state from a ShadingMethodBase object into the current object.
         */
        public function copyFrom(method:ShadingMethodBase):void
        {
        }
    }
}
