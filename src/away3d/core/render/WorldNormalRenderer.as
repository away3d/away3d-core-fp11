package away3d.core.render {
	import away3d.arcane;
	import away3d.core.pool.RenderableBase;
	import away3d.core.traverse.EntityCollector;
	import away3d.core.traverse.ICollector;
	import away3d.entities.Camera3D;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	public class WorldNormalRenderer extends RendererBase {
		private var _activeMaterial:MaterialBase;

		public function WorldNormalRenderer() {
			super();
			_backgroundR = 1;
			_backgroundG = 1;
			_backgroundB = 1;
		}

		public override function set backgroundR(value:Number):void {
		}

		public override function set backgroundG(value:Number):void {
		}

		public override function set backgroundB(value:Number):void {
		}

		/**
		 * @inheritDoc
		 */
		override protected function draw(collector:ICollector, target:TextureBase):void {
			var entityCollector:EntityCollector = collector as EntityCollector;
			collectRenderables(entityCollector);

			_context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			_context3D.setDepthTest(true, Context3DCompareMode.LESS);

			drawRenderables(opaqueRenderableHead, entityCollector);

			if (_activeMaterial)
				_activeMaterial.deactivateForWorldNormal(_stage3DProxy);

			_activeMaterial = null;
		}

		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawRenderables(renderable:RenderableBase, entityCollector:EntityCollector):void {
			var camera:Camera3D = entityCollector.camera;
			var renderable2:RenderableBase;

			while (renderable) {
				_activeMaterial = renderable.material;
				// otherwise this would result in depth rendered anyway because fragment shader kil is ignored
				_activeMaterial.activateForWorldNormal(_stage3DProxy, camera);
				renderable2 = renderable;
				do {
					_activeMaterial.renderWorldNormal(renderable2, _stage3DProxy, camera, _rttViewProjectionMatrix);
					renderable2 = renderable2.next as RenderableBase;
				} while (renderable2 && renderable2.material == _activeMaterial);
				_activeMaterial.deactivateForWorldNormal(_stage3DProxy);
				renderable = renderable2;
			}
		}
	}
}
