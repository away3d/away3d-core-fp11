package away3d.core.render
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.sort.DepthSorter;
	import away3d.core.traverse.EntityCollector;
	import away3d.materials.MaterialBase;
	import away3d.materials.utils.AGAL;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;

	use namespace arcane;

	/**
	 * The DepthRenderer class renders 32-bit depth information encoded as RGBA
	 */
	public class DepthRenderer extends RendererBase
	{
		private var _activeMaterial : MaterialBase;
		private var _renderBlended : Boolean;

		/**
		 * Creates a new DepthRenderer object.
		 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
		 * @param antiAlias The amount of anti-aliasing to be used.
		 * @param renderMode The render mode to be used.
		 */
		public function DepthRenderer(renderBlended : Boolean = false, antiAlias : uint = 0, renderMode : String = "auto")
		{
			super(antiAlias, true, renderMode);
			_renderBlended = renderBlended;
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
		override protected function draw(entityCollector : EntityCollector) : void
		{
			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

			_context.setDepthTest(false, Context3DCompareMode.LESS);

			if (entityCollector.skyBox)
				drawSkyBox(entityCollector);

			_context.setDepthTest(true, Context3DCompareMode.LESS);
			drawRenderables(entityCollector.opaqueRenderables, entityCollector);

			if (_renderBlended)
				drawRenderables(entityCollector.blendedRenderables, entityCollector);

			if (_activeMaterial) _activeMaterial.deactivate(_context);
			_activeMaterial = null;
		}

		private function drawSkyBox(entityCollector : EntityCollector) : void
		{
			var skyBox : IRenderable = entityCollector.skyBox;
			var material : MaterialBase = skyBox.material;
			var camera : Camera3D = entityCollector.camera;

			material.activateForDepth(_context, _contextIndex, camera);
			material.renderDepth(skyBox, _context, _contextIndex, camera);
			material.deactivateForDepth(_context);
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
			var numRenderables : uint = renderables.length;
			var camera : Camera3D = entityCollector.camera;

			while (i < numRenderables) {
				_activeMaterial = renderables[i].material;

				k = i;
				_activeMaterial.activateForDepth(_context, _contextIndex, camera);
				do {
					renderable = renderables[k];
					_activeMaterial.renderDepth(renderable, _context, _contextIndex, camera);
				} while(++k < numRenderables && renderable.material != _activeMaterial);
				_activeMaterial.deactivateForDepth(_context);

				i = k;
			}
		}
	}
}