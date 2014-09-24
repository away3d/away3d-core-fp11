package away3d.core.pool {
    /**
     * ITextureData is an interface for classes that are used in the rendering pipeline to render the
     * contents of a texture
     *
     * @class away3d.core.pool.ITextureData
     */
    public interface ITextureData {
        function dispose():void;

        function invalidate():void;
    }
}
