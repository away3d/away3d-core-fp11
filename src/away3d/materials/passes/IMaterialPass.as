package away3d.materials.passes {
    import away3d.arcane;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.lightpickers.LightPickerBase;

    import flash.events.IEventDispatcher;
    import flash.geom.Matrix3D;

    use namespace arcane;

    /**
     * IMaterialPass provides an interface for material shader passes. A material pass constitutes at least
     * a render call per required renderable.
     */
    public interface IMaterialPass extends IEventDispatcher {
        /**
         * Cleans up any resources used by the current object.
         * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
         */
        function dispose():void;

        /**
         * Renders an object to the current render target.
         *
         * @private
         */
        function render(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void;

        /**
         * Sets the render state for the pass that is independent of the rendered object. This needs to be called before
         * calling renderPass. Before activating a pass, the previously used pass needs to be deactivated.
         * @param stage The Stage object which is currently used for rendering.
         * @param camera The camera from which the scene is viewed.
         * @private
         */
        function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void;

        /**
         * Clears the render state for the pass. This needs to be called before activating another pass.
         * @param stage The Stage used for rendering
         *
         * @private
         */
        function deactivate(pass:MaterialPassData, stage:Stage3DProxy):void;

        /**
         * The light picker used by the material to provide lights to the material if it supports lighting.
         *
         * @see away.materials.LightPickerBase
         * @see away.materials.StaticLightPicker
         */
        function get lightPicker():LightPickerBase;

        function set lightPicker(value:LightPickerBase):void;

        function getPreLightingVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getPreLightingFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getNormalVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function getNormalFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String;

        function get forceSeparateMVP():Boolean;

        function get passMode():Number;

        function initConstantData(shaderObject:ShaderObjectBase):void;

        function includeDependencies(shaderObject:ShaderObjectBase):void;

        /**
         * Factory method to create a concrete shader object for this pass.
         *
         * @param profile The compatibility profile used by the renderer.
         */
        function createShaderObject(profile:String):ShaderObjectBase;
    }
}
