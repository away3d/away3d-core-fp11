package away3d.core.render {
    import away3d.arcane;
    import away3d.core.geom.Plane3D;
    import away3d.core.pool.MaterialData;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
    import away3d.core.traverse.EntityCollector;
    import away3d.core.traverse.ICollector;
    import away3d.entities.Camera3D;
    import away3d.materials.passes.MaterialPassBase;
    import away3d.textures.TextureProxyBase;

    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DCompareMode;
    import flash.geom.Rectangle;

    use namespace arcane;

    /**
     * The DepthRenderer class renders 32-bit depth information encoded as RGBA
     */
    public class DepthRenderer extends RendererBase {
        private var _pass:MaterialPassBase;
        private var _renderBlended:Boolean;
        private var _disableColor:Boolean;

        /**
         * Creates a new DepthRenderer object.
         * @param renderBlended Indicates whether semi-transparent objects should be rendered.
         * @param distanceBased Indicates whether the written depth value is distance-based or projected depth-based
         */
        public function DepthRenderer(pass:MaterialPassBase, renderBlended:Boolean = false, distanceBased:Boolean = false)
        {
            super();

            _pass = pass;

            _renderBlended = renderBlended;
            _backgroundR = 1;
            _backgroundG = 1;
            _backgroundB = 1;
        }

        public function get disableColor():Boolean
        {
            return _disableColor;
        }

        public function set disableColor(value:Boolean):void
        {
            _disableColor = value;
        }

        public override function set backgroundR(value:Number):void
        {
        }

        public override function set backgroundG(value:Number):void
        {
        }

        public override function set backgroundB(value:Number):void
        {
        }

        public function renderCascades(entityCollector:ICollector, target:TextureProxyBase, numCascades:uint, scissorRects:Vector.<Rectangle>, cameras:Vector.<Camera3D>):void
        {
            collectRenderables(entityCollector);

            _stage3DProxy.setRenderTarget(target, true, 0);
            _context3D.clear(1, 1, 1, 1, 1, 0);

            _context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
            _context3D.setDepthTest(true, Context3DCompareMode.LESS);

            var head:RenderableBase = opaqueRenderableHead;
            var first:Boolean = true;
            for (var i:int = numCascades - 1; i >= 0; --i) {
                _stage3DProxy.scissorRect = scissorRects[i];
                drawCascadeRenderables(head, cameras[i], first ? null : cameras[i].frustumPlanes);
                first = false;
            }
            //line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
            _context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);

            _stage3DProxy.scissorRect = null;
        }

        private function drawCascadeRenderables(renderable:RenderableBase, camera:Camera3D, cullPlanes:Vector.<Plane3D>):void
        {
            var activePass:MaterialPassData;
            var activeMaterial:MaterialData;

            var renderable2:RenderableBase;

            while (renderable) {
                activeMaterial = _stage3DProxy.getMaterial(renderable.material, _stage3DProxy.profile);
                renderable2 = renderable;
                activePass = activeMaterial.getMaterialPass(_pass, _stage3DProxy.profile);
                //TODO: generalise this test
                if (activePass.key == "")
                    _stage3DProxy.calcAnimationCode(renderable.material, activePass);

                renderable.material.activatePass(activePass, _stage3DProxy, camera);

                do {
                    // if completely in front, it will fall in a different cascade
                    // do not use near and far planes
                    if (!cullPlanes || renderable2.sourceEntity.worldBounds.isInFrustum(cullPlanes, 4)) {
                        renderable2.material.renderPass(activePass, renderable2, _stage3DProxy, camera, _rttViewProjectionMatrix);
                    } else {
                        renderable2.cascaded = true;
                    }
                    renderable2 = renderable2.next as RenderableBase;

                } while (renderable2 && renderable2.material == renderable.material && !renderable2.cascaded);
                renderable.material.deactivatePass(activePass, _stage3DProxy);
                renderable = renderable2;
            }
        }

        /**
         * @inheritDoc
         */
        override protected function draw(collector:ICollector, target:TextureProxyBase):void
        {
            var entityCollector:EntityCollector = collector as EntityCollector;
            collectRenderables(entityCollector);

            _context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
            _context3D.setDepthTest(true, Context3DCompareMode.LESS);
            drawRenderables(opaqueRenderableHead, entityCollector);

            if (_disableColor)
                _context3D.setColorMask(false, false, false, false);

            if (_renderBlended)
                drawRenderables(blendedRenderableHead, entityCollector);

            if (_disableColor)
                _context3D.setColorMask(true, true, true, true);
        }

        /**
         * Draw a list of renderables.
         * @param renderables The renderables to draw.
         * @param entityCollector The EntityCollector containing all potentially visible information.
         */
        private function drawRenderables(renderable:RenderableBase, entityCollector:EntityCollector):void
        {
            var activePass:MaterialPassData;
            var activeMaterial:MaterialData;
            var camera:Camera3D = entityCollector.camera;
            var renderable2:RenderableBase;

            while (renderable) {
                activeMaterial = _stage3DProxy.getMaterial(renderable.material, _stage3DProxy.profile);
                // otherwise this would result in depth rendered anyway because fragment shader kil is ignored
                if (this._disableColor && renderable.material.alphaThreshold != 0) {
                    renderable2 = renderable;
                    // fast forward
                    do {
                        renderable2 = renderable2.next as RenderableBase;
                    } while (renderable2 && renderable2.material == renderable.material);
                } else {
                    renderable2 = renderable;
                    activePass = activeMaterial.getMaterialPass(this._pass, _stage3DProxy.profile);
                    //TODO: generalise this test
                    if (activePass.key == "")
                        _stage3DProxy.calcAnimationCode(renderable.material, activePass);

                    renderable.material.activatePass(activePass, _stage3DProxy, camera);

                    do {
                        renderable2.material.renderPass(activePass, renderable2, _stage3DProxy, camera, _rttViewProjectionMatrix);
                        renderable2 = renderable2.next as RenderableBase;
                    } while (renderable2 && renderable2.material == renderable.material);
                    renderable.material.deactivatePass(activePass, _stage3DProxy);
                }

                renderable = renderable2;
            }
        }
    }
}