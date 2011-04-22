package away3d.core.render
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.traverse.EntityCollector;
	import away3d.lights.LightBase;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	/**
	 * The DefaultRenderer class provides the default rendering method. It renders the scene graph objects using the
	 * materials assigned to them.
	 */
	public class DefaultRenderer extends RendererBase
	{
		private var _activeMaterial : MaterialBase;
//		private var _depthPrePass : Boolean;
//		private var _depthRenderer : DepthRenderer;

		/**
		 * Creates a new DefaultRenderer object.
		 * @param antiAlias The amount of anti-aliasing to use.
		 * @param renderMode The render mode to use.
		 */
		public function DefaultRenderer(antiAlias : uint = 0, renderMode : String = "auto")
		{
			super(antiAlias, true, renderMode);
//			_depthRenderer = new DepthRenderer();
		}

		/**
		 * Indicates whether or not the depth buffer should be rendered first in a separate pass.
		 */
		/*public function get depthPrePass() : Boolean
		{
			return _depthPrePass;
		}

		public function set depthPrePass(value : Boolean) : void
		{
			if (value == _depthPrePass) return;

			_depthPrePass = value;

			if (value) {
				// don't call present
				_depthRenderer.swapBackBuffer = false;
				_depthRenderer.viewPortWidth = _viewPortWidth;
				_depthRenderer.viewPortHeight = _viewPortHeight;
				_depthRenderer.viewPortX = _viewPortX;
				_depthRenderer.viewPortY = _viewPortY;
			}
		}           */


		arcane override function set stage3DProxy(value : Stage3DProxy) : void
		{
			super.stage3DProxy = /*_depthRenderer.stage3DProxy = */value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(entityCollector : EntityCollector, target : TextureBase = null, surfaceSelector : int = 0, additionalClearMask : int = 7) : void
		{
			/*if (_depthPrePass) {
				_depthRenderer.render(entityCollector, target, surfaceSelector, Context3DClearMask.DEPTH);
				super.render(entityCollector, target, surfaceSelector, Context3DClearMask.COLOR | Context3DClearMask.STENCIL);
			}
			else*/
				super.render(entityCollector, target, surfaceSelector, additionalClearMask);
		}

		/**
		 * @inheritDoc
		 */
		/*protected override function executeRender(entityCollector : EntityCollector, target : TextureBase = null, surfaceSelector : int = 0, additionalClearMask : int = 7) : void
		{
			updateLights(entityCollector);
			super.executeRender(entityCollector, target, surfaceSelector, additionalClearMask);
		} */

		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector) : void
		{
			_context.setDepthTest(true, Context3DCompareMode.LESS);
//			_context.setDepthTest(true, _depthPrePass? Context3DCompareMode.LESS_EQUAL : Context3DCompareMode.LESS);

			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			drawRenderables(entityCollector.opaqueRenderables, entityCollector);

			_context.setDepthTest(false, Context3DCompareMode.LESS);

			if (entityCollector.skyBox) {
				if (_activeMaterial) _activeMaterial.deactivate(_context);
				_activeMaterial = null;
				drawSkyBox(entityCollector);
			}

			drawRenderables(entityCollector.blendedRenderables, entityCollector);

			if (_activeMaterial) _activeMaterial.deactivate(_context);
			_activeMaterial = null;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateViewPort() : void
		{
			super.updateViewPort();
			/*if (_depthPrePass) {
				_depthRenderer.viewPortWidth = _viewPortWidth;
				_depthRenderer.viewPortHeight = _viewPortHeight;
				_depthRenderer.viewPortX = _viewPortX;
				_depthRenderer.viewPortY = _viewPortY;
			}  */
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
		private function drawRenderables(renderables : Vector.<IRenderable>, entityCollector : EntityCollector) : void
		{
			var renderable : IRenderable;
			var i : uint, j : uint, k : uint;
			var numPasses : uint;
			var numRenderables : uint = renderables.length;
			var camera : Camera3D = entityCollector.camera;

			while (i < numRenderables) {
				_activeMaterial = renderables[i].material;
				_activeMaterial.updateMaterial(_context);

				numPasses = _activeMaterial.numPasses;
				j = 0;

				do {
					k = i;
					_activeMaterial.activatePass(j, _context, _contextIndex, camera);
					do {
						renderable = renderables[k];

						_activeMaterial.renderPass(j, renderable, _context, _contextIndex, camera);
					} while(++k < numRenderables && renderable.material != _activeMaterial);
					_activeMaterial.deactivatePass(j, _context);
				} while (++j < numPasses);

				i = k;
			}
		}
	}
}