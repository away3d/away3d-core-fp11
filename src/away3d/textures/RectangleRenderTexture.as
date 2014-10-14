package away3d.textures {
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.TextureBase;

    public class RectangleRenderTexture extends RenderTexture {

        public function RectangleRenderTexture(width:Number = 1, height:Number = 1, format:String = Context3DTextureFormat.BGRA)
        {
            super(width, height);
            _format = format;
        }

        override public function set width(value:int):void
        {
            if (value == _width)
                return;

            invalidateContent();
            setSize(value, _height);
        }

        override public function set height(value:int):void
        {
            if (value == _height)
                return;

            invalidateContent();
            setSize(_width, value);
        }
    }
}