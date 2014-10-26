package away3d.filters.tasks {
    import away3d.arcane;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.textures.RenderTexture;
    import away3d.textures.Texture2DBase;
    import away3d.textures.TextureProxyBase;

    import flash.display.BitmapData;
    import flash.display3D.textures.Texture;

    use namespace arcane;

    public class Filter3DDoubleBufferCopyTask extends Filter3DTaskBase {
        private var _secondaryInputTexture:TextureProxyBase;

        public function Filter3DDoubleBufferCopyTask()
        {
            super();
        }

        public function get secondaryInputTexture():TextureProxyBase
        {
            return _secondaryInputTexture;
        }

        override protected function getFragmentCode():String
        {
            return "tex oc, v0, fs0 <2d,nearest,clamp>\n";
        }

        override protected function updateTextures():void
        {
            if (_secondaryInputTexture)
                _secondaryInputTexture.dispose();

            _secondaryInputTexture = new RenderTexture(_textureWidth >> _textureScale, _textureHeight >> _textureScale);

            var dummy:BitmapData = new BitmapData(_textureWidth >> _textureScale, _textureHeight >> _textureScale, false, 0);
            (_mainInputTexture as Texture).uploadFromBitmapData(dummy);
            (_secondaryInputTexture as Texture).uploadFromBitmapData(dummy);
            dummy.dispose();
        }

        override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:TextureProxyBase):void
        {
            swap();
            super.activate(stage3DProxy, camera, depthTexture);
        }

        private function swap():void
        {
            var tmp:TextureProxyBase = _secondaryInputTexture;
            _secondaryInputTexture = _mainInputTexture;
            _mainInputTexture = tmp;
        }
    }
}
