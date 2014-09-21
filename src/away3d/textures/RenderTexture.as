package away3d.textures {
    import away3d.arcane;
    import away3d.materials.utils.MipmapGenerator;
    import away3d.tools.utils.TextureUtils;

    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.TextureBase;

    use namespace arcane;

    public class RenderTexture extends Texture2DBase {
        public function RenderTexture(width:Number, height:Number)
        {
            super();
            setSize(width, height);
        }

        public function set width(value:int):void
        {
            if (value == _width)
                return;

            if (!TextureUtils.isDimensionValid(value))
                throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");

            invalidateContent();
            setSize(value, _height);
        }

        public function set height(value:int):void
        {
            if (value == _height)
                return;

            if (!TextureUtils.isDimensionValid(value))
                throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");

            invalidateContent();
            setSize(_width, value);
        }
    }
}
