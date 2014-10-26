package away3d.filters.tasks {
    import away3d.debug.Debug;
    import away3d.entities.Camera3D;
    import away3d.errors.AbstractMethodError;
    import away3d.managers.Stage3DProxy;
    import away3d.textures.RenderTexture;
    import away3d.textures.Texture2DBase;
    import away3d.textures.TextureProxyBase;

    import com.adobe.utils.AGALMiniAssembler;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;

    public class Filter3DTaskBase {
        protected var _mainInputTexture:TextureProxyBase;
        protected var _scaledTextureWidth:int = -1;
        protected var _scaledTextureHeight:int = -1;
        protected var _textureWidth:int = -1;
        protected var _textureHeight:int = -1;
        protected var _textureDimensionsInvalid:Boolean = true;
        private var _program3DInvalid:Boolean = true;
        private var _program3D:Program3D;
        private var _program3DContext:Context3D;
        private var _target:TextureProxyBase;
        private var _requireDepthRender:Boolean;
        protected var _textureScale:int = 0;

        public function Filter3DTaskBase(requireDepthRender:Boolean = false)
        {
            _requireDepthRender = requireDepthRender;
        }

        /**
         * The texture scale for the input of this texture. This will define the output of the previous entry in the chain
         */
        public function get textureScale():int
        {
            return _textureScale;
        }

        public function set textureScale(value:int):void
        {
            if (_textureScale == value)
                return;
            _textureScale = value;
            _scaledTextureWidth = _textureWidth >> _textureScale;
            _scaledTextureHeight = _textureHeight >> _textureScale;
            _textureDimensionsInvalid = true;
        }

        public function get target():TextureProxyBase
        {
            return _target;
        }

        public function set target(value:TextureProxyBase):void
        {
            _target = value;
        }

        public function get textureWidth():int
        {
            return _textureWidth;
        }

        public function set textureWidth(value:int):void
        {
            if (_textureWidth == value)
                return;
            _textureWidth = value;
            _scaledTextureWidth = _textureWidth >> _textureScale;
            if (_scaledTextureWidth < 1) _scaledTextureWidth = 1;
            _textureDimensionsInvalid = true;
        }

        public function get textureHeight():int
        {
            return _textureHeight;
        }

        public function set textureHeight(value:int):void
        {
            if (_textureHeight == value)
                return;
            _textureHeight = value;
            _scaledTextureHeight = _textureHeight >> _textureScale;
            if (_scaledTextureHeight < 1) _scaledTextureHeight = 1;
            _textureDimensionsInvalid = true;
        }

        public function getMainInputTexture():TextureProxyBase
        {
            if (_textureDimensionsInvalid)
                updateTextures();

            return _mainInputTexture;
        }

        public function dispose():void
        {
            if (_mainInputTexture)
                _mainInputTexture.dispose();
            if (_program3D)
                _program3D.dispose();
            _program3DContext = null;
        }

        protected function invalidateProgram3D():void
        {
            _program3DInvalid = true;
        }

        protected function updateProgram3D(stage:Stage3DProxy):void
        {
            if (_program3D)
                _program3D.dispose();
            _program3DContext = stage.context3D;
            _program3D = _program3DContext.createProgram();
            _program3D.upload(new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
                    new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode()));
            _program3DInvalid = false;
        }

        protected function getVertexCode():String
        {
            return "mov op, va0\n" +
                    "mov v0, va1\n";
        }

        protected function getFragmentCode():String
        {
            throw new AbstractMethodError();
            return null;
        }

        protected function updateTextures():void
        {
            if (_mainInputTexture)
                _mainInputTexture.dispose();
            _mainInputTexture = new RenderTexture(_scaledTextureWidth, _scaledTextureHeight);
            _textureDimensionsInvalid = false;
        }

        public function getProgram3D(stage3DProxy:Stage3DProxy):Program3D
        {
            if (_program3DContext != stage3DProxy.context3D) {
                _program3DInvalid = true;
            }

            if (_program3DInvalid)
                updateProgram3D(stage3DProxy);
            return _program3D;
        }

        public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:TextureProxyBase):void
        {
        }

        public function deactivate(stage3DProxy:Stage3DProxy):void
        {
        }

        public function get requireDepthRender():Boolean
        {
            return _requireDepthRender;
        }
    }
}
