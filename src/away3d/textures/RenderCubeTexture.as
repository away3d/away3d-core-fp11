package away3d.textures {
    import away3d.arcane;
    import away3d.tools.utils.TextureUtils;

    use namespace arcane;

    public class RenderCubeTexture extends CubeTextureBase {
        public function RenderCubeTexture(size:Number)
        {
            super();
            setSize(size);
        }

        public function set size(value:int):void
        {
            if (value == _size)
                return;

            if (!TextureUtils.isDimensionValid(value))
                throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");

            invalidateContent();
            setSize(value);
        }
    }
}
