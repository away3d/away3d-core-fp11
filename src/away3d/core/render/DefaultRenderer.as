package away3d.core.render
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.traverse.EntityCollector;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Rectangle;

	use namespace arcane;

	/**
	 * The DefaultRenderer class provides the default rendering method. It renders the scene graph objects using the
	 * materials assigned to them.
	 */
	public class DefaultRenderer extends RendererBase
	{
		private var _activeMaterial : MaterialBase;
		private var _distanceRenderer : DepthRenderer;
		private var _depthRenderer : DepthRenderer;

		/**
		 * Creates a new DefaultRenderer object.
		 * @param antiAlias The amount of anti-aliasing to use.
		 * @param renderMode The render mode to use.
		 */
		public function DefaultRenderer()
		{
			super();
			_depthRenderer = new DepthRenderer();
			_distanceRenderer = new DepthRenderer(false, true);
		}

		arcane override function set stage3DProxy(value : Stage3DProxy) : void
		{
			super.stage3DProxy = value;
			_distanceRenderer.stage3DProxy = _depthRenderer.stage3DProxy = value;
		}

		protected override function executeRender(entityCollector : EntityCollector, target : TextureBase = null, scissorRect : Rectangle = null, surfaceSelector : int = 0, additionalClearMask : int = 7) : void
		{
			updateLights(entityCollector);
			
			super.executeRender(entityCollector, target, scissorRect, surfaceSelector, additionalClearMask);
		}

		private function updateLights(entityCollector : EntityCollector) : void
		{
			var dirLights : Vector.<DirectionalLight> = entityCollector.directionalLights;
			var pointLights : Vector.<PointLight> = entityCollector.pointLights;
			var len : uint, i : uint;
			var light : LightBase;

			len = dirLights.length;
			for (i = 0; i < len; ++i) {
				light = dirLights[i];
				if (light.castsShadows)
					light.shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _depthRenderer);
			}

			len = pointLights.length;
			for (i = 0; i < len; ++i) {
				light = pointLights[i];
				if (light.castsShadows)
					light.shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _distanceRenderer);
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector, target : TextureBase) : void
		{
			// TODO: not used
			target = target;
					
			_context.setDepthTest(true, Context3DCompareMode.LESS);

			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			drawRenderables(entityCollector.opaqueRenderableHead, entityCollector);

			_context.setDepthTest(false, Context3DCompareMode.LESS);

			if (entityCollector.skyBox) {
				if (_activeMaterial) _activeMaterial.deactivate(_stage3DProxy);
				_activeMaterial = null;
				drawSkyBox(entityCollector);
			}

			drawRenderables(entityCollector.blendedRenderableHead, entityCollector);

			if (_activeMaterial) _activeMaterial.deactivate(_stage3DProxy);

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

			material.activatePass(0, _stage3DProxy, camera, _textureRatioX, _textureRatioY);
			material.renderPass(0, skyBox, _stage3DProxy, entityCollector);
			material.deactivatePass(0, _stage3DProxy);
		}

		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawRenderables(item : RenderableListItem, entityCollector : EntityCollector) : void
		{
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

					_activeMaterial.activatePass(j, _stage3DProxy, camera, _textureRatioX, _textureRatioY);
					do {
						_activeMaterial.renderPass(j, item2.renderable, _stage3DProxy, entityCollector);
						item2 = item2.next;
					} while (item2 && item2.renderable.material == _activeMaterial);
					_activeMaterial.deactivatePass(j, _stage3DProxy);

				} while (++j < numPasses);

				item = item2;
			}
		}


		arcane override function dispose() : void
		{
			super.dispose();
			_depthRenderer.dispose();
			_distanceRenderer.dispose();
			_depthRenderer = null;
			_distanceRenderer = null;
		}
	}
}