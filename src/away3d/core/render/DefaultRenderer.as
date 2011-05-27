package away3d.core.render
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.traverse.EntityCollector;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;

	use namespace arcane;

	/**
	 * The DefaultRenderer class provides the default rendering method. It renders the scene graph objects using the
	 * materials assigned to them.
	 */
	public class DefaultRenderer extends RendererBase
	{
		private var _activeMaterial : MaterialBase;

		/**
		 * Creates a new DefaultRenderer object.
		 * @param antiAlias The amount of anti-aliasing to use.
		 * @param renderMode The render mode to use.
		 */
		public function DefaultRenderer(antiAlias : uint = 0, renderMode : String = "auto")
		{
			super(antiAlias, true, renderMode);
		}


		arcane override function set stage3DProxy(value : Stage3DProxy) : void
		{
			super.stage3DProxy = value;
		}

		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector) : void
		{
			_context.setDepthTest(true, Context3DCompareMode.LESS);

			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			drawRenderables(entityCollector.opaqueRenderableHead, entityCollector);

			_context.setDepthTest(false, Context3DCompareMode.LESS);

			if (entityCollector.skyBox) {
				if (_activeMaterial) _activeMaterial.deactivate(_context);
				_activeMaterial = null;
				drawSkyBox(entityCollector);
			}

			drawRenderables(entityCollector.blendedRenderableHead, entityCollector);

			if (_activeMaterial) _activeMaterial.deactivate(_context);
			_activeMaterial = null;
		}

		/**
		 * Draw the skybox if present.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawSkyBox(entityCollector : EntityCollector) : void
		{
			var skyBox : IRenderable = entityCollector.skyBox;
			var material : MaterialBase = skyBox.material;
			var camera : Camera3D = entityCollector.camera;

			material.activatePass(0, _context, _contextIndex, camera);
			material.renderPass(0, skyBox, _context, _contextIndex, camera);
			material.deactivatePass(0, _context);
		}

		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawRenderables(item : RenderableListItem, entityCollector : EntityCollector) : void
		{
			var renderable : IRenderable;
			var numPasses : uint;
			var j : uint;
			var camera : Camera3D = entityCollector.camera;
			var item2 : RenderableListItem;

			while (item) {
				_activeMaterial = item.renderable.material;
				_activeMaterial.updateMaterial(_context);

				numPasses = _activeMaterial.numPasses;
				j = 0;

				do {
					item2 = item;
					_activeMaterial.activatePass(j, _context, _contextIndex, camera);
					do {
						_activeMaterial.renderPass(j, item2.renderable, _context, _contextIndex, camera);
						item2 = item2.next;
					} while (item2 && item2.renderable.material == _activeMaterial);
					_activeMaterial.deactivatePass(j, _context);
				} while (++j < numPasses);

				item = item2;
			}
		}
	}
}