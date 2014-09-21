package away3d.textures {
    import away3d.arcane;
    import away3d.tools.utils.TextureUtils;

    import flash.display.BitmapData;

    use namespace arcane;

    public class BitmapCubeTexture extends CubeTextureBase {
        private var _bitmapDatas:Vector.<BitmapData>;

        //private var _useAlpha : Boolean;

        public function BitmapCubeTexture(posX:BitmapData, negX:BitmapData, posY:BitmapData, negY:BitmapData, posZ:BitmapData, negZ:BitmapData)
        {
            super();

            _bitmapDatas = new Vector.<BitmapData>(6, true);
            testSize(_bitmapDatas[0] = posX);
            testSize(_bitmapDatas[1] = negX);
            testSize(_bitmapDatas[2] = posY);
            testSize(_bitmapDatas[3] = negY);
            testSize(_bitmapDatas[4] = posZ);
            testSize(_bitmapDatas[5] = negZ);

            invalidateContent();

            setSize(posX.width);
        }

        /**
         * The texture on the cube's right face.
         */
        public function get positiveX():BitmapData
        {
            return _bitmapDatas[0];
        }

        public function set positiveX(value:BitmapData):void
        {
            testSize(value);
            invalidateContent();
            setSize(value.width);
            _bitmapDatas[0] = value;
        }

        /**
         * The texture on the cube's left face.
         */
        public function get negativeX():BitmapData
        {
            return _bitmapDatas[1];
        }

        public function set negativeX(value:BitmapData):void
        {
            testSize(value);
            invalidateContent();
            setSize(value.width);
            _bitmapDatas[1] = value;
        }

        /**
         * The texture on the cube's top face.
         */
        public function get positiveY():BitmapData
        {
            return _bitmapDatas[2];
        }

        public function set positiveY(value:BitmapData):void
        {
            testSize(value);
            invalidateContent();
            setSize(value.width);
            _bitmapDatas[2] = value;
        }

        /**
         * The texture on the cube's bottom face.
         */
        public function get negativeY():BitmapData
        {
            return _bitmapDatas[3];
        }

        public function set negativeY(value:BitmapData):void
        {
            testSize(value);
            invalidateContent();
            setSize(value.width);
            _bitmapDatas[3] = value;
        }

        /**
         * The texture on the cube's far face.
         */
        public function get positiveZ():BitmapData
        {
            return _bitmapDatas[4];
        }

        public function set positiveZ(value:BitmapData):void
        {
            testSize(value);
            invalidateContent();
            setSize(value.width);
            _bitmapDatas[4] = value;
        }

        /**
         * The texture on the cube's near face.
         */
        public function get negativeZ():BitmapData
        {
            return _bitmapDatas[5];
        }

        public function set negativeZ(value:BitmapData):void
        {
            testSize(value);
            invalidateContent();
            setSize(value.width);
            _bitmapDatas[5] = value;
        }

        private function testSize(value:BitmapData):void
        {
            if (value.width != value.height)
                throw new Error("BitmapData should have equal width and height!");
            if (!TextureUtils.isBitmapDataValid(value))
                throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");
        }


        override public function dispose():void
        {
            super.dispose();

            var len:int = _bitmapDatas.length;
            for (var i:int = 0; i < len; i++) {
                _bitmapDatas[i].dispose();
                _bitmapDatas[i] = null;
            }
        }


        override arcane function getTextureData(side:Number):BitmapData
        {
            return _bitmapDatas[side];
        }
    }
}
