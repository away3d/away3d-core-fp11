package away3d.filters {
    import away3d.entities.Camera3D;
    import away3d.filters.tasks.Filter3DTaskBase;
    import away3d.managers.Stage3DProxy;
    import away3d.textures.TextureProxyBase;

    public class Filter3DBase {
        private var _tasks:Vector.<Filter3DTaskBase>;
        private var _requireDepthRender:Boolean;
        private var _textureWidth:int;
        private var _textureHeight:int;

        public function Filter3DBase()
        {
            _tasks = new Vector.<Filter3DTaskBase>();
        }

        public function get requireDepthRender():Boolean
        {
            return _requireDepthRender;
        }

        protected function addTask(filter:Filter3DTaskBase):void
        {
            _tasks.push(filter);
            _requireDepthRender ||= filter.requireDepthRender;
        }

        public function get tasks():Vector.<Filter3DTaskBase>
        {
            return _tasks;
        }

        public function getMainInputTexture():TextureProxyBase
        {
            return _tasks[0].getMainInputTexture();
        }

        public function get textureWidth():int
        {
            return _textureWidth;
        }

        public function set textureWidth(value:int):void
        {
            _textureWidth = value;

            for (var i:int = 0; i < _tasks.length; ++i)
                _tasks[i].textureWidth = value;
        }

        public function get textureHeight():int
        {
            return _textureHeight;
        }

        public function set textureHeight(value:int):void
        {
            _textureHeight = value;
            for (var i:int = 0; i < _tasks.length; ++i)
                _tasks[i].textureHeight = value;
        }

        // link up the filters correctly with the next filter
        public function setRenderTargets(mainTarget:TextureProxyBase):void
        {
            _tasks[_tasks.length - 1].target = mainTarget;
        }

        public function dispose():void
        {
            for (var i:int = 0; i < _tasks.length; ++i)
                _tasks[i].dispose();
        }

        public function update(stage:Stage3DProxy, camera:Camera3D):void
        {

        }
    }
}
