package away3d.core.render {
    import away3d.managers.Stage3DProxy;
    import away3d.core.traverse.EntityCollector;
    import away3d.textures.RenderTexture;
    import away3d.textures.Texture2DBase;

    public interface ILightRenderer {
        function render(stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, hasMRTSupport:Boolean, frustumCorners:Vector.<Number>, normalTexture:Texture2DBase, depthTexture:Texture2DBase = null):void;

        function set coloredSpecularOutput(coloredSpecularOutput:Boolean):void;

        function set specularEnabled(specularEnabled:Boolean):void;

        function set diffuseEnabled(diffuseEnabled:Boolean):void;

        function set textureRatioY(textureRatioY:Number):void;

        function set textureRatioX(textureRatioX:Number):void;
    }
}
