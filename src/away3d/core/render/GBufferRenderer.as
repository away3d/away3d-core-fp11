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

	public class GBufferRenderer extends RendererBase {
		private var _activeMaterial:MaterialBase;
		private var _drawDepth:Boolean = true;
		private var _drawWorldNormal:Boolean = true;
		private var _drawAlbedo:Boolean = false;
		private var _drawSpecular:Boolean = false;

		public function GBufferRenderer() {
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
				_activeMaterial.deactivateGBuffer(_stage3DProxy);

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
				_activeMaterial.activateForGBuffer(_stage3DProxy, camera, _drawDepth, _drawWorldNormal, _drawAlbedo, _drawSpecular);
				renderable2 = renderable;
				do {
					_activeMaterial.renderGBuffer(renderable2, _stage3DProxy, camera, _rttViewProjectionMatrix);
					renderable2 = renderable2.next as RenderableBase;
				} while (renderable2 && renderable2.material == _activeMaterial);
				_activeMaterial.deactivateGBuffer(_stage3DProxy);
				renderable = renderable2;
			}
		}

		public function get drawSpecular():Boolean {
			return _drawSpecular;
		}

		public function set drawSpecular(value:Boolean):void {
			_drawSpecular = value;
		}

		public function get drawAlbedo():Boolean {
			return _drawAlbedo;
		}

		public function set drawAlbedo(value:Boolean):void {
			_drawAlbedo = value;
		}

		public function get drawWorldNormal():Boolean {
			return _drawWorldNormal;
		}

		public function set drawWorldNormal(value:Boolean):void {
			_drawWorldNormal = value;
		}

		public function get drawDepth():Boolean {
			return _drawDepth;
		}

		public function set drawDepth(value:Boolean):void {
			_drawDepth = value;
		}
	}
}
