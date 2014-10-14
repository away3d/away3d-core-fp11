package away3d.materials {
    import away3d.arcane;
    import away3d.materials.passes.TriangleBasicPass;
    import away3d.textures.Texture2DBase;

    import flash.display.BlendMode;
    import flash.display3D.Context3DCompareMode;

    use namespace arcane;

    public class TriangleBasicMaterial extends TriangleMaterialBase {
        private var _screenPass:TriangleBasicPass;

        private var _alphaBlending:Boolean = false;
        private var _alpha:Number = 1;

        private var _depthCompareMode:String = Context3DCompareMode.LESS_EQUAL;

        /**
         * Creates a new TriangleMaterial object.
         *
         * @param texture The texture used for the material's albedo color.
         * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
         * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to false.
         * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to false.
         */
        public function TriangleBasicMaterial(texture:Texture2DBase = null, smooth:Boolean = true, repeat:Boolean = false, mipmap:Boolean = true)
        {
            super();

            _screenPass = new TriangleBasicPass();

            this.texture = texture;
            this.smooth = smooth;
            this.repeat = repeat;
            this.mipmap = mipmap;
        }

        /**
         * The depth compare mode used to render the renderables using this material.
         */
        public function get depthCompareMode():String
        {
            return _depthCompareMode;
        }

        public function set depthCompareMode(value:String)
        {
            if (_depthCompareMode == value)
                return;

            _depthCompareMode = value;

            invalidatePasses();
        }

        /**
         * The alpha of the surface.
         */
        public function get alpha():Number
        {
            return _alpha;
        }

        public function set alpha(value:Number)
        {
            if (value > 1)
                value = 1;
            else if (value < 0)
                value = 0;

            if (_alpha == value)
                return;

            _alpha = value;

            invalidatePasses();
        }

        /**
         * Indicates whether or not the material has transparency. If binary transparency is sufficient, for
         * example when using textures of foliage, consider using alphaThreshold instead.
         */
        public function get alphaBlending():Boolean
        {
            return this._alphaBlending;
        }

        public function set alphaBlending(value:Boolean):void
        {
            if (this._alphaBlending == value)
                return;

            this._alphaBlending = value;

            invalidatePasses();
        }

        /**
         * @inheritDoc
         */
        override arcane function updateMaterial():void
        {
            var passesInvalid:Boolean;

            if (_screenPassesInvalid) {
                updateScreenPasses();
                passesInvalid = true;
            }

            if (passesInvalid) {
                clearScreenPasses();

                addScreenPass(_screenPass);
            }
        }

        /**
         * Updates screen passes when they were found to be invalid.
         */
        public function updateScreenPasses():void
        {
            initPasses();

            setBlendAndCompareModes();

            _screenPassesInvalid = false;
        }

        /**
         * Initializes all the passes and their dependent passes.
         */
        private function initPasses():void
        {
        }

        /**
         * Sets up the various blending modes for all screen passes, based on whether or not there are previous passes.
         */
        private function setBlendAndCompareModes():void
        {
            _requiresBlending = (_blendMode != BlendMode.NORMAL || _alphaBlending || _alpha < 1);
            _screenPass.depthCompareMode = _depthCompareMode;
            _screenPass.preserveAlpha = _requiresBlending;
            _screenPass.setBlendMode((_blendMode == BlendMode.NORMAL && _requiresBlending) ? BlendMode.LAYER : _blendMode);
            _screenPass.forceSeparateMVP = false;
        }
    }
}
