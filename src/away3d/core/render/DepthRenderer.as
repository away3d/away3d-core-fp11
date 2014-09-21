package away3d.core.render
{
	import away3d.arcane;
	import away3d.core.geom.Plane3D;
	import away3d.core.pool.IRenderable;
	import away3d.core.pool.RenderableBase;
	import away3d.core.traverse.EntityCollector;
	import away3d.core.traverse.ICollector;
	import away3d.entities.Camera3D;
	import away3d.entities.IEntity;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Rectangle;

	use namespace arcane;
	
	/**
	 * The DepthRenderer class renders 32-bit depth information encoded as RGBA
	 */
	public class DepthRenderer extends RendererBase
	{
		private var _activeMaterial:MaterialBase;
		private var _renderBlended:Boolean;
		private var _distanceBased:Boolean;
		private var _disableColor:Boolean;
		
		/**
		 * Creates a new DepthRenderer object.
		 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
		 * @param distanceBased Indicates whether the written depth value is distance-based or projected depth-based
		 */
		public function DepthRenderer(renderBlended:Boolean = false, distanceBased:Boolean = false)
		{
			super();
			_renderBlended = renderBlended;
			_distanceBased = distanceBased;
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

		public function renderCascades(entityCollector:ICollector, target:TextureBase, numCascades:uint, scissorRects:Vector.<Rectangle>, cameras:Vector.<Camera3D>):void
		{
			collectRenderables(entityCollector);

//			_renderTarget = target;
//			_renderTargetSurface = 0;
//			_renderableSorter.sort(entityCollector);

			_stage3DProxy.setRenderTarget(target, true, 0);
			_context3D.clear(1, 1, 1, 1, 1, 0);
			_context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			_context3D.setDepthTest(true, Context3DCompareMode.LESS);
			
			var head:RenderableBase = opaqueRenderableHead;
			var first:Boolean = true;
			for (var i:int = numCascades - 1; i >= 0; --i) {
				_stage3DProxy.scissorRect = scissorRects[i];
				drawCascadeRenderables(head, cameras[i], first? null : cameras[i].frustumPlanes);
				first = false;
			}
			
			if (_activeMaterial)
				_activeMaterial.deactivateForDepth(_stage3DProxy);
			
			_activeMaterial = null;
			
			//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
			_context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
			
			_stage3DProxy.scissorRect = null;
		}
		
		private function drawCascadeRenderables(renderable:RenderableBase, camera:Camera3D, cullPlanes:Vector.<Plane3D>):void
		{
			var material:MaterialBase;
			
			while (renderable) {
				if (renderable.cascaded) {
					renderable = renderable.next as RenderableBase;
					continue;
				}
				
				var entity:IEntity = renderable.sourceEntity;
				
				// if completely in front, it will fall in a different cascade
				// do not use near and far planes
				if (!cullPlanes || entity.worldBounds.isInFrustum(cullPlanes, 4)) {
					material = renderable.material;
					if (_activeMaterial != material) {
						if (_activeMaterial)
							_activeMaterial.deactivateForDepth(_stage3DProxy);
						_activeMaterial = material;
						_activeMaterial.activateForDepth(_stage3DProxy, camera, false);
					}
					
					_activeMaterial.renderDepth(renderable, _stage3DProxy, camera, camera.viewProjection);
				} else
					renderable.cascaded = true;
				
				renderable = renderable.next as RenderableBase;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function draw(collector:ICollector, target:TextureBase):void
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
			
			if (_activeMaterial)
				_activeMaterial.deactivateForDepth(_stage3DProxy);
			
			if (_disableColor)
				_context3D.setColorMask(true, true, true, true);
			
			_activeMaterial = null;
		}
		
		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawRenderables(renderable:RenderableBase, entityCollector:EntityCollector):void
		{
			var camera:Camera3D = entityCollector.camera;
			var renderable2:RenderableBase;
			
			while (renderable) {
				_activeMaterial = renderable.material;
				
				// otherwise this would result in depth rendered anyway because fragment shader kil is ignored
				if (_disableColor && _activeMaterial.hasDepthAlphaThreshold()) {
					renderable2 = renderable;
					// fast forward
					do
						renderable2 = renderable2.next as RenderableBase;
					while (renderable2 && renderable2.material == _activeMaterial);
				} else {
					_activeMaterial.activateForDepth(_stage3DProxy, camera, _distanceBased);
					renderable2 = renderable;
					do {
						_activeMaterial.renderDepth(renderable2, _stage3DProxy, camera, _rttViewProjectionMatrix);
						renderable2 = renderable2.next as RenderableBase;
					} while (renderable2 && renderable2.material == _activeMaterial);
					_activeMaterial.deactivateForDepth(_stage3DProxy);
				}
				renderable = renderable2;
			}
		}
	}
}
