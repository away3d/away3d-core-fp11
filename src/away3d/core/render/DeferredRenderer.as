package away3d.core.render {
	import away3d.arcane;
	import away3d.core.managers.Stage3DManager;
	import away3d.core.pool.RenderableBase;
	import away3d.core.render.IRenderer;
	import away3d.core.render.RenderTargetCopy;
	import away3d.core.render.RendererBase;
	import away3d.core.traverse.ICollector;
	import away3d.materials.DeferredMaterial;
	import away3d.materials.MaterialBase;
	import away3d.textures.RectangleRenderTexture;

	import flash.display.Stage;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DTextureFormat;

	use namespace arcane;

	public class DeferredRenderer extends RendererBase implements IRenderer {
		//GBuffer
		private var renderTarget0:RectangleRenderTexture = new RectangleRenderTexture(1, 1, Context3DTextureFormat.BGRA);
		private var renderTarget1:RectangleRenderTexture = new RectangleRenderTexture(1, 1, Context3DTextureFormat.BGRA);
		private var renderTarget2:RectangleRenderTexture = new RectangleRenderTexture(1, 1, Context3DTextureFormat.BGRA);
		private var renderTarget3:RectangleRenderTexture = new RectangleRenderTexture(1, 1, Context3DTextureFormat.BGRA);

		//debug
		private var renderTargetCopy:RenderTargetCopy = new RenderTargetCopy();

		public function DeferredRenderer() {
		}

		override public function init(stage:Stage):void {
			if (!stage3DProxy) {
				stage3DProxy = Stage3DManager.getInstance(stage).getFreeStage3DProxy(false, Context3DProfile.STANDARD);
			}
			if (_width == 0)
				width = stage.stageWidth;

			if (_height == 0)
				height = stage.stageHeight;
		}

		override public function set height(value:Number):void {
			super.height = value;
			renderTarget0.height = value;
			renderTarget1.height = value;
			renderTarget2.height = value;
			renderTarget3.height = value;
		}

		override public function set width(value:Number):void {
			super.width = value;
			renderTarget0.width = value;
			renderTarget1.width = value;
			renderTarget2.width = value;
			renderTarget3.width = value;
		}

		override public function render(entityCollector:ICollector):void {
			super.render(entityCollector);

			if (!_stage3DProxy || !_context3D || !_stage3DProxy.recoverFromDisposal()) {
				_backBufferInvalid = true;
				return;
			}

			//config buffer if changed
			if (_backBufferInvalid) {
				_context3D.configureBackBuffer(_width, _height, _antiAlias, true, wantsBestResolution);
				_backBufferInvalid = false;
			}
			_context3D.clear(0, 0, 0, 1, 1, 0);

			//collect data to gbuffer
			_context3D.setRenderToTexture(renderTarget0.getTextureForStage3D(_stage3DProxy), true, _antiAlias, 0, 0);
			_context3D.setRenderToTexture(renderTarget1.getTextureForStage3D(_stage3DProxy), true, _antiAlias, 0, 1);
			_context3D.setRenderToTexture(renderTarget2.getTextureForStage3D(_stage3DProxy), true, _antiAlias, 0, 2);
			//TODO specular optional
			_context3D.setRenderToTexture(renderTarget3.getTextureForStage3D(_stage3DProxy), true, _antiAlias, 0, 3);

			//clear render targets
			_context3D.clear(0, 0, 0, 1, 1);

			//projection matrix
			_rttViewProjectionMatrix.copyFrom(entityCollector.camera.viewProjection);
			_rttViewProjectionMatrix.appendScale(_textureRatioX, _textureRatioY, 1);

			//fill opaque and transparent objects
			collectRenderables(entityCollector);
			//
			var renderable:RenderableBase = opaqueRenderableHead;
			var drawCalls:uint = 0;
			//TODO: transparent objects
			while (renderable) {
				var currentMaterial:MaterialBase = renderable.material;
				var deferred:DeferredMaterial = currentMaterial as DeferredMaterial;
				deferred.deferredPass.activate(stage3DProxy, camera);
				while (renderable && renderable.material == currentMaterial) {
					drawCalls++;
					deferred.deferredPass.render(renderable, stage3DProxy, camera, _rttViewProjectionMatrix);
					renderable = renderable.next as RenderableBase;
				}
				deferred.deferredPass.deactivate(stage3DProxy);
			}

			// clear buffers
			var i:uint = 0;
			for (i = 0; i < 8; ++i) {
				_context3D.setVertexBufferAt(i, null);
				_context3D.setTextureAt(i, null);
			}

			_context3D.setRenderToTexture(null, true, _antiAlias, 0, 0);
			_context3D.setRenderToTexture(null, true, _antiAlias, 0, 1);
			_context3D.setRenderToTexture(null, true, _antiAlias, 0, 2);
			_context3D.setRenderToTexture(null, true, _antiAlias, 0, 3);
			_context3D.setRenderToBackBuffer();

			_context3D.setTextureAt(0, renderTarget0.getTextureForStage3D(_stage3DProxy));
			_context3D.setTextureAt(1, renderTarget1.getTextureForStage3D(_stage3DProxy));
			_context3D.setTextureAt(2, renderTarget2.getTextureForStage3D(_stage3DProxy));
			_context3D.setTextureAt(3, renderTarget3.getTextureForStage3D(_stage3DProxy));
			renderTargetCopy.draw(stage3DProxy);

			// clear buffers
			for (i = 0; i < 8; ++i) {
				_context3D.setVertexBufferAt(i, null);
				_context3D.setTextureAt(i, null);
			}

			if (!_shareContext) {
				_context3D.present();
			}
		}
	}
}
