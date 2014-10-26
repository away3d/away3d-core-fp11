package away3d.filters.tasks {
    import away3d.arcane;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.textures.Texture2DBase;
    import away3d.textures.TextureProxyBase;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;

    use namespace arcane;

    public class Filter3DXFadeCompositeTask extends Filter3DTaskBase {
        private var _data:Vector.<Number>;
        private var _overlayTexture:TextureProxyBase;

        public function Filter3DXFadeCompositeTask(amount:Number)
        {
            super();
            if (amount < 0)
                amount = 0;
            else if (amount > 1)
                amount = 1;
            _data = Vector.<Number>([ amount, 0, 0, 0 ]);
        }

        public function get overlayTexture():TextureProxyBase
        {
            return _overlayTexture;
        }

        public function set overlayTexture(value:TextureProxyBase):void
        {
            _overlayTexture = value;
        }

        public function get amount():Number
        {
            return _data[0];
        }

        public function set amount(value:Number):void
        {
            _data[0] = value;
        }

        override protected function getFragmentCode():String
        {
            return "tex ft0, v0, fs0 <2d,nearest>	\n" +
                    "tex ft1, v0, fs1 <2d,nearest>	\n" +
                    "sub ft1, ft1, ft0				\n" +
                    "mul ft1, ft1, fc0.x			\n" +
                    "add oc, ft1, ft0				\n";
        }

        override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:TextureProxyBase):void
        {
            var context:Context3D = stage3DProxy._context3D;
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
            stage3DProxy.activateTexture(1, _overlayTexture);
        }

        override public function deactivate(stage3DProxy:Stage3DProxy):void
        {
            stage3DProxy._context3D.setTextureAt(1, null);
        }
    }
}
