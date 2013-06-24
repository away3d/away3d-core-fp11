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
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.MaterialBase;
	
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * The DefaultRenderer class provides the default rendering method. It renders the scene graph objects using the
	 * materials assigned to them.
	 */
	public class DefaultRenderer extends RendererBase
	{
		private static var RTT_PASSES:int = 1;
		private static var SCREEN_PASSES:int = 2;
		private static var ALL_PASSES:int = 3;
		private var _activeMaterial:MaterialBase;
		private var _distanceRenderer:DepthRenderer;
		private var _depthRenderer:DepthRenderer;
		private var _skyboxProjection:Matrix3D = new Matrix3D();
		
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
		
		arcane override function set stage3DProxy(value:Stage3DProxy):void
		{
			super.stage3DProxy = value;
			_distanceRenderer.stage3DProxy = _depthRenderer.stage3DProxy = value;
		}
		
		protected override function executeRender(entityCollector:EntityCollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:int = 0):void
		{
			updateLights(entityCollector);
			
			// otherwise RTT will interfere with other RTTs
			if (target) {
				drawRenderables(entityCollector.opaqueRenderableHead, entityCollector, RTT_PASSES);
				drawRenderables(entityCollector.blendedRenderableHead, entityCollector, RTT_PASSES);
			}
			
			super.executeRender(entityCollector, target, scissorRect, surfaceSelector);
		}
		
		private function updateLights(entityCollector:EntityCollector):void
		{
			var dirLights:Vector.<DirectionalLight> = entityCollector.directionalLights;
			var pointLights:Vector.<PointLight> = entityCollector.pointLights;
			var len:uint, i:uint;
			var light:LightBase;
			var shadowMapper:ShadowMapperBase;
			
			len = dirLights.length;
			for (i = 0; i < len; ++i) {
				light = dirLights[i];
				shadowMapper = light.shadowMapper;
				if (light.castsShadows && (shadowMapper.autoUpdateShadows || shadowMapper._shadowsInvalid))
					shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _depthRenderer);
			}
			
			len = pointLights.length;
			for (i = 0; i < len; ++i) {
				light = pointLights[i];
				shadowMapper = light.shadowMapper;
				if (light.castsShadows && (shadowMapper.autoUpdateShadows || shadowMapper._shadowsInvalid))
					shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _distanceRenderer);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector:EntityCollector, target:TextureBase):void
		{
			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			
			if (entityCollector.skyBox) {
				if (_activeMaterial)
					_activeMaterial.deactivate(_stage3DProxy);
				_activeMaterial = null;
				
				_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
				drawSkyBox(entityCollector);
			}
			
			_context.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
			
			var which:int = target? SCREEN_PASSES : ALL_PASSES;
			drawRenderables(entityCollector.opaqueRenderableHead, entityCollector, which);
			drawRenderables(entityCollector.blendedRenderableHead, entityCollector, which);
			
			_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
			
			if (_activeMaterial)
				_activeMaterial.deactivate(_stage3DProxy);
			
			_activeMaterial = null;
		}
		
		/**
		 * Draw the skybox if present.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawSkyBox(entityCollector:EntityCollector):void
		{
			var skyBox:IRenderable = entityCollector.skyBox;
			var material:MaterialBase = skyBox.material;
			var camera:Camera3D = entityCollector.camera;
			
			updateSkyBoxProjection(camera);
			
			material.activatePass(0, _stage3DProxy, camera);
			material.renderPass(0, skyBox, _stage3DProxy, entityCollector, _skyboxProjection);
			material.deactivatePass(0, _stage3DProxy);
		}
		
		private function updateSkyBoxProjection(camera:Camera3D):void
		{
			var near:Vector3D = new Vector3D();
			_skyboxProjection.copyFrom(_rttViewProjectionMatrix);
			_skyboxProjection.copyRowTo(2, near);
			var camPos:Vector3D = camera.scenePosition;
			
			var cx:Number = near.x;
			var cy:Number = near.y;
			var cz:Number = near.z;
			var cw:Number = -(near.x*camPos.x + near.y*camPos.y + near.z*camPos.z + Math.sqrt(cx*cx + cy*cy + cz*cz));
			var signX:Number = cx >= 0? 1 : -1;
			var signY:Number = cy >= 0? 1 : -1;
			var p:Vector3D = new Vector3D(signX, signY, 1, 1);
			var inverse:Matrix3D = _skyboxProjection.clone();
			inverse.invert();
			var q:Vector3D = inverse.transformVector(p);
			_skyboxProjection.copyRowTo(3, p);
			var a:Number = (q.x*p.x + q.y*p.y + q.z*p.z + q.w*p.w)/(cx*q.x + cy*q.y + cz*q.z + cw*q.w);
			_skyboxProjection.copyRowFrom(2, new Vector3D(cx*a, cy*a, cz*a, cw*a));
		
		}
		
		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawRenderables(item:RenderableListItem, entityCollector:EntityCollector, which:int):void
		{
			var numPasses:uint;
			var j:uint;
			var camera:Camera3D = entityCollector.camera;
			var item2:RenderableListItem;
			
			while (item) {
				_activeMaterial = item.renderable.material;
				_activeMaterial.updateMaterial(_context);
				
				numPasses = _activeMaterial.numPasses;
				j = 0;
				
				do {
					item2 = item;
					
					var rttMask:int = _activeMaterial.passRendersToTexture(j)? 1 : 2;
					
					if ((rttMask & which) != 0) {
						_activeMaterial.activatePass(j, _stage3DProxy, camera);
						do {
							_activeMaterial.renderPass(j, item2.renderable, _stage3DProxy, entityCollector, _rttViewProjectionMatrix);
							item2 = item2.next;
						} while (item2 && item2.renderable.material == _activeMaterial);
						_activeMaterial.deactivatePass(j, _stage3DProxy);
					} else {
						do
							item2 = item2.next;
						while (item2 && item2.renderable.material == _activeMaterial);
					}
					
				} while (++j < numPasses);
				
				item = item2;
			}
		}
		
		arcane override function dispose():void
		{
			super.dispose();
			_depthRenderer.dispose();
			_distanceRenderer.dispose();
			_depthRenderer = null;
			_distanceRenderer = null;
		}
	}
}
