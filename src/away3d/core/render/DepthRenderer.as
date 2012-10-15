package away3d.core.render
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.math.Plane3D;
	import away3d.core.math.PlaneClassification;
	import away3d.core.traverse.EntityCollector;
	import away3d.entities.Entity;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;

	use namespace arcane;

	/**
	 * The DepthRenderer class renders 32-bit depth information encoded as RGBA
	 */
	public class DepthRenderer extends RendererBase
	{
		private var _activeMaterial : MaterialBase;
		private var _renderBlended : Boolean;
		private var _distanceBased : Boolean;
		private var _disableColor : Boolean;

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

		public function get disableColor() : Boolean
		{
			return _disableColor;
		}

		public function set disableColor(value : Boolean) : void
		{
			_disableColor = value;
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

		arcane function renderCascades(entityCollector : EntityCollector, target : TextureBase, numCascades : uint, scissorRects : Vector.<Rectangle>, splitPlanes : Vector.<Plane3D>, cameras : Vector.<Camera3D>) : void
		{
			_renderTarget = target;
			_renderTargetSurface = 0;
			_renderableSorter.sort(entityCollector);
			_stage3DProxy.setRenderTarget(target, true, 0);
			_context.clear(1, 1, 1, 1, 1, 0);
			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			_context.setDepthTest(true, Context3DCompareMode.LESS);

			var head : RenderableListItem = entityCollector.opaqueRenderableHead;
			for (var i : uint = 0; i < numCascades; ++i) {
				_stage3DProxy.scissorRect = scissorRects[i];
				drawCascadeRenderables(head, cameras[i]);
			}

			if (_activeMaterial)
				_activeMaterial.deactivateForDepth(_stage3DProxy);

			_activeMaterial = null;

			//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
			_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);

			_stage3DProxy.scissorRect = null;
		}

		private function drawCascadeRenderables(item : RenderableListItem, camera : Camera3D) : void
		{
			var material : MaterialBase;

			while (item) {
				var renderable : IRenderable = item.renderable;
				var entity : Entity = renderable.sourceEntity;

				entity.pushModelViewProjection(camera, false);

				if (entity.bounds.isInFrustum(entity.getModelViewProjectionUnsafe())) {
					material = renderable.material;
					if (_activeMaterial != material) {
						if (_activeMaterial) _activeMaterial.deactivateForDepth(_stage3DProxy);
						_activeMaterial = material;
						_activeMaterial.activateForDepth(_stage3DProxy, camera, false, 1, 1);
					}
					_activeMaterial.renderDepth(renderable, _stage3DProxy, camera);
				}

				entity.popModelViewProjection();

				item = item.next;
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector, target : TextureBase) : void
		{
			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			_context.setDepthTest(true, Context3DCompareMode.LESS);
			drawRenderables(entityCollector.opaqueRenderableHead, entityCollector);

			if (_disableColor) _context.setColorMask(false, false, false, false);

			if (_renderBlended)
				drawRenderables(entityCollector.blendedRenderableHead, entityCollector);

			if (_activeMaterial)
				_activeMaterial.deactivateForDepth(_stage3DProxy);

			if (_disableColor) _context.setColorMask(true, true, true, true);

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

				// otherwise this would result in depth rendered anyway because fragment shader kil is ignored
				if (_disableColor && _activeMaterial.hasDepthAlphaThreshold()) {
					item2 = item;
					// fast forward
					do {
						item2 = item2.next;
					} while(item2 && item2.renderable.material == _activeMaterial);
				}
				else {
					_activeMaterial.activateForDepth(_stage3DProxy, camera, _distanceBased, _textureRatioX, _textureRatioY);
					item2 = item;
					do {
						_activeMaterial.renderDepth(item2.renderable, _stage3DProxy, camera);
						item2 = item2.next;
					} while(item2 && item2.renderable.material == _activeMaterial);
					_activeMaterial.deactivateForDepth(_stage3DProxy);
				}
				item = item2;
			}
		}
	}
}