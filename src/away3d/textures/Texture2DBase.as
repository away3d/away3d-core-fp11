package away3d.textures {
    import away3d.arcane;
    import away3d.errors.AbstractMethodError;
    import away3d.materials.utils.MipmapGenerator;

    import flash.display.BitmapData;

    use namespace arcane;

    public class Texture2DBase extends TextureProxyBase {
        private var _mipmapData:Vector.<BitmapData>;
        private var _mipmapDataDirty:Boolean;
        protected var _width:int;
        protected var _height:int;

        public function Texture2DBase(generateMipmaps:Boolean = false)
        {
            super(generateMipmaps);
        }

        public function get width():int
        {
            return _width;
        }

        public function get height():int
        {
            return _height;
        }

        protected function setSize(width:int, height:int):void
        {
            if (_width != width || _height != height)
                invalidateSize();

            _mipmapDataDirty = true;

            _width = width;
            _height = height;
        }


        override public function dispose():void
        {
            super.dispose();
            if (_mipmapData) {
                var len:int = _mipmapData.length;
                for (var i:int = 0; i < len; i++) {
                    MipmapGenerator.freeMipMapHolder(_mipmapData[i]);
                }
            }
        }

        override public function invalidateContent():void
        {
            super.invalidateContent();

            _mipmapDataDirty = true;
        }

        arcane function getMipmapData():Vector.<BitmapData>
        {
            if (_mipmapDataDirty) {
                _mipmapDataDirty = false;

                if (!_mipmapData)
                    _mipmapData = new Vector.<BitmapData>();

                MipmapGenerator.generateMipMaps(getTextureData(), _mipmapData, true);
            }
            return _mipmapData;
        }

        arcane function getTextureData():BitmapData
        {
            throw new AbstractMethodError();
        }
    }
}
