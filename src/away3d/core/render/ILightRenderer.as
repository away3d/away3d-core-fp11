package away3d.core.render {
    import away3d.core.managers.Stage3DProxy;
    import away3d.core.traverse.EntityCollector;
    import away3d.textures.RenderTexture;
    import away3d.textures.Texture2DBase;

    public interface ILightRenderer {
        function render(stage3DProxy:Stage3DProxy, deferredData:DeferredData, entityCollector:EntityCollector, frustumCorners:Vector.<Number>):void;

        function set textureRatioY(textureRatioY:Number):void;

        function set textureRatioX(textureRatioX:Number):void;
    }
}
