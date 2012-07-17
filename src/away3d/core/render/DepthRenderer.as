package away3d.core.render
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.data.RenderableListItem;
	import away3d.core.traverse.EntityCollector;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	/**
	 * The DepthRenderer class renders 32-bit depth information encoded as RGBA
	 */
	public class DepthRenderer extends RendererBase
	{
		private var _activeMaterial : MaterialBase;
		private var _renderBlended : Boolean;
		private var _distanceBased : Boolean;

		/**
		 * Creates a new DepthRenderer object.
		 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
		 * @param antiAlias The amount of anti-aliasing to be used.
		 * @param renderMode The render mode to be used.
		 */
		public function DepthRenderer(renderBlended : Boolean = false, distanceBased : Boolean = false)
		{
			super();
			_renderBlended = renderBlended;
			_distanceBased = distanceBased;
			_backgroundR = 1;
			_backgroundG = 1;
			_backgroundB = 1;
		}


		arcane override function set backgroundR(value : Number) : void
		{
		}

		arcane override function set backgroundG(value : Number) : void
		{
		}

		arcane override function set backgroundB(value : Number) : void
		{
		}


		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector, target : TextureBase) : void
		{
			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			_context.setDepthTest(true, Context3DCompareMode.LESS);
			drawRenderables(entityCollector.opaqueRenderableHead, entityCollector);

			if (_renderBlended)
				drawRenderables(entityCollector.blendedRenderableHead, entityCollector);

			if (_activeMaterial)
				_activeMaterial.deactivateForDepth(_stage3DProxy);

			_activeMaterial = null;
		}

		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawRenderables(item : RenderableListItem, entityCollector : EntityCollector) : void
		{
			var camera : Camera3D = entityCollector.camera;
			var item2 : RenderableListItem;

			while (item) {
				_activeMaterial = item.renderable.material;

				_activeMaterial.activateForDepth(_stage3DProxy, camera, _distanceBased, _textureRatioX, _textureRatioY);
				item2 = item;
				do {
					_activeMaterial.renderDepth(item2.renderable, _stage3DProxy, camera);
					item2 = item2.next;
				} while(item2 && item2.renderable.material == _activeMaterial);
				_activeMaterial.deactivateForDepth(_stage3DProxy);
				item = item2;
			}
		}
	}
}