package away3d.textures {
    import away3d.arcane;
    import away3d.core.library.AssetType;
    import away3d.core.library.IAsset;
    import away3d.core.library.NamedAssetBase;
    import away3d.core.pool.ITextureData;

    import flash.display3D.Context3DTextureFormat;

    use namespace arcane;

    public class TextureProxyBase extends NamedAssetBase implements IAsset {
        protected var _size:int;
        protected var _format:String = Context3DTextureFormat.BGRA;
        protected var _hasMipmaps:Boolean;

        private var _generateMipmaps:Boolean;
        private var _textureData:Vector.<ITextureData> = new Vector.<ITextureData>();

        public function TextureProxyBase(generateMipmaps:Boolean = false)
        {
            _generateMipmaps = _hasMipmaps = generateMipmaps;
        }

        override public function get assetType():String
        {
            return AssetType.TEXTURE;
        }


        public function invalidateContent():void
        {
            var len:int = _textureData.length;
            for (var i:int = 0; i < len; i++)
                _textureData[i].invalidate();
        }

        protected function invalidateSize():void
        {
            while (_textureData.length)
                _textureData[0].dispose();
        }

        /**
         * @inheritDoc
         */
        override public function dispose():void
        {
            while (_textureData.length)
                _textureData[0].dispose();
        }

        arcane function addTextureData(textureData:ITextureData):ITextureData
        {
            _textureData.push(textureData);
            return textureData;
        }

        arcane function removeTextureData(textureData:ITextureData):ITextureData
        {
            _textureData.splice(_textureData.indexOf(textureData), 1);
            return textureData;
        }

        public function get hasMipMaps():Boolean
        {
            return _hasMipmaps;
        }

        public function get format():String
        {
            return _format;
        }

        public function set format(value:String):void
        {
            if (_format == value) return;
            _format = value;
            invalidateContent();
        }

        public function get generateMipmaps():Boolean
        {
            return _generateMipmaps;
        }

        public function set generateMipmaps(value:Boolean):void
        {
            if (_generateMipmaps == value) return;
            _generateMipmaps = _hasMipmaps = value;
            invalidateContent();
        }

        public function get size():int
        {
            return _size;
        }
    }
}
