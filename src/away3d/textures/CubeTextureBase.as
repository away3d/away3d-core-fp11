package away3d.textures {
    import away3d.arcane;
    import away3d.errors.AbstractMethodError;
    import away3d.materials.utils.MipmapGenerator;

    import flash.display.BitmapData;

    use namespace arcane;

    public class CubeTextureBase extends TextureProxyBase {

        private var _mipmapDataArray:Vector.<Vector.<BitmapData>> = new Vector.<Vector.<BitmapData>>(6);
        private var _mipmapDataDirtyArray:Vector.<Boolean> = new Vector.<Boolean>(6);

        public function CubeTextureBase(generateMipMaps:Boolean = false)
        {
            super(generateMipMaps);
        }

        /**
         *
         * @param size
         * @private
         */
        protected function setSize(size:int):void
        {
            if (_size != size)
                invalidateSize();

            for (var i:Number = 0; i < 6; i++)
                _mipmapDataDirtyArray[i] = true;

            _size = size;
        }

        /**
         * @inheritDoc
         */
        override public function dispose():void
        {
            super.dispose();

            for (var i:Number = 0; i < 6; i++) {
                var mipmapData:Vector.<BitmapData> = _mipmapDataArray[i];
                var len:Number = mipmapData.length;
                for (var j:Number = 0; j < len; j++)
                    MipmapGenerator.freeMipMapHolder(mipmapData[j]);
            }
        }

        override public function invalidateContent():void
        {
            super.invalidateContent();

            for (var i:Number = 0; i < 6; i++)
                this._mipmapDataDirtyArray[i] = true;
        }

        arcane function getMipmapData(side:Number):Vector.<BitmapData>
        {
            if (_mipmapDataDirtyArray[side]) {
                _mipmapDataDirtyArray[side] = false;

                var mipmapData:Vector.<BitmapData> = _mipmapDataArray[side] || (_mipmapDataArray[side] = new Vector.<BitmapData>());
                MipmapGenerator.generateMipMaps(getTextureData(side), mipmapData, true);
            }

            return _mipmapDataArray[side];
        }

        arcane function getTextureData(side:Number):BitmapData
        {
            throw new AbstractMethodError();
        }
    }
}
