package away3d.textures {
    import away3d.arcane;
    import away3d.materials.utils.MipmapGenerator;
    import away3d.tools.utils.TextureUtils;

    import flash.display.BitmapData;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;

    use namespace arcane;

    public class BitmapTexture extends Texture2DBase {
        protected var _bitmapData:BitmapData;

        public function BitmapTexture(bitmapData:BitmapData, generateMipmaps:Boolean = true)
        {
            super();
            this.generateMipmaps = generateMipmaps;
            this.bitmapData = bitmapData;
        }

        public function get bitmapData():BitmapData
        {
            return _bitmapData;
        }

        public function set bitmapData(value:BitmapData):void
        {
            if (value == _bitmapData)
                return;

            if (!TextureUtils.isBitmapDataValid(value))
                throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");

            _bitmapData = value;

            invalidateContent();
            setSize(value.width, value.height);
        }

        override public function dispose():void
        {
            super.dispose();

            _bitmapData.dispose();
            _bitmapData = null;
        }


        override arcane function getTextureData():BitmapData
        {
            return _bitmapData;
        }
    }
}
