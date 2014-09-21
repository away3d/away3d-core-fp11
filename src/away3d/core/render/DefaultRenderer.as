package away3d.core.render
{
	import away3d.arcane;
	import away3d.core.pool.MaterialData;
	import away3d.core.pool.MaterialPassData;
	import away3d.managers.RTTBufferManager;
	import away3d.managers.Stage3DManager;
	import away3d.managers.Stage3DProxy;
	import away3d.core.geom.Matrix3DUtils;
	import away3d.core.pool.RenderableBase;
	import away3d.core.traverse.EntityCollector;
	import away3d.core.traverse.ICollector;
	import away3d.debug.Debug;
	import away3d.entities.Camera3D;
	import away3d.filters.Filter3DBase;
	import away3d.entities.DirectionalLight;
	import away3d.core.base.LightBase;
	import away3d.entities.PointLight;
	import away3d.materials.passes.IMaterialPass;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.shadowmappers.ShadowMapperBase;
	import away3d.materials.MaterialBase;
	import away3d.textures.RectangleRenderTexture;
	import away3d.textures.RenderTexture;
	import away3d.textures.Texture2DBase;

	import flash.display.Stage;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DTextureFilter;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * The DefaultRenderer class provides the default rendering method. It renders the scene graph objects using the
	 * materials assigned to them.
	 */
	public class DefaultRenderer extends RendererBase implements IRenderer
	{
		private static const _frustumCorners:Vector.<Number> = new Vector.<Number>();

		protected var _requireDepthRender:Boolean;

		private var _activeMaterial:MaterialBase;

		private var _distanceRenderer:DepthRenderer;
		private var _depthRenderer:DepthRenderer;
		private var _skyboxProjection:Matrix3D = new Matrix3D();

		private var _tempSkyboxMatrix:Matrix3D = new Matrix3D();
		private var _skyboxTempVector:Vector3D = new Vector3D();

		private var _forceSoftware:Boolean;
		private var _profile:String;

		protected var filter3DRenderer:Filter3DRenderer;
		protected var sceneDepthTexture:RenderTexture;
		//deferred lighting
		protected var sceneNormalTexture:RenderTexture;
		protected var lightAccumulation:RenderTexture;
		protected var lightAccumulationSpecular:RenderTexture;

		private var _renderTargetToScreenCopy:RenderTargetCopy;
		private var _worldNormalRenderer:WorldNormalRenderer;
		private var _gbufferRenderer:GBufferRenderer;
		private var _lightRenderer:ILightRenderer;

		//todo: thinking about the creation of DeferredLightingConfig class to accumulate these properties
		//but it should be immutable, because passes can't change these values
		//or move it to EntityCollector
		private var _useDeferredLighting:Boolean = false;
		private var _useDeferredSpecularLighting:Boolean = false;
		private var _useDeferredDiffuseLighting:Boolean = false;
		private var _useDeferredColoredSpecular:Boolean = false;

		/**
		 *
		 * @returns {*}
		 */
		public function get filters3d():Vector.<Filter3DBase>
		{
			return filter3DRenderer ? filter3DRenderer.filters : null;
		}

		public function set filters3d(value:Vector.<Filter3DBase>):void
		{
			if (value && value.length == 0)
				value = null;

			if (filter3DRenderer && !value) {
				filter3DRenderer.dispose();
				filter3DRenderer = null;
			} else
				if (!filter3DRenderer && value) {
					filter3DRenderer = new Filter3DRenderer(_stage3DProxy);
					filter3DRenderer.filters = value;
				}

			if (filter3DRenderer) {
				filter3DRenderer.filters = value;
				_requireDepthRender = filter3DRenderer.requireDepthRender;
			} else {
				_requireDepthRender = false;

				if (!_useDeferredLighting && sceneDepthTexture) {
					sceneDepthTexture.dispose();
					sceneDepthTexture = null;
				}
			}
		}

		/**
		 * Creates a new DefaultRenderer object.
		 * @param antiAlias The amount of anti-aliasing to use.
		 * @param renderMode The render mode to use.
		 */
		public function DefaultRenderer(forceSoftware:Boolean = false, profile:String = "baseline")
		{
			super();
			_depthRenderer = new DepthRenderer();
			_worldNormalRenderer = new WorldNormalRenderer();
			_gbufferRenderer = new GBufferRenderer();
			_distanceRenderer = new DepthRenderer(false, true);
			_forceSoftware = forceSoftware;
			_profile = profile;
		}

		override public function init(stage:Stage):void
		{
			if (!stage3DProxy)
				stage3DProxy = Stage3DManager.getInstance(stage).getFreeStage3DProxy(_forceSoftware, _profile);

			_rttBufferManager = RTTBufferManager.getInstance(_stage3DProxy);

			if (_width == 0)
				width = stage.stageWidth; else
				_rttBufferManager.viewWidth = _width;

			if (_height == 0)
				height = stage.stageHeight; else
				_rttBufferManager.viewHeight = _height;
		}

		override public function set stage3DProxy(value:Stage3DProxy):void
		{
			super.stage3DProxy = value;
			_distanceRenderer.stage3DProxy = _depthRenderer.stage3DProxy = value;
		}


		override public function render(collector:ICollector):void
		{
			var entityCollector:EntityCollector = collector as EntityCollector;
			super.render(entityCollector);

			if (!_stage3DProxy || !_stage3DProxy.recoverFromDisposal()) {
				_backBufferInvalid = true;
				return;
			}

			if (_backBufferInvalid) {
				updateBackBuffer();
			}

			if (_shareContext && layeredView) {
				_stage3DProxy.clearDepthBuffer();
			}

			collectRenderables(entityCollector);
			//setup camera for rendering required scene data
			_rttViewProjectionMatrix.copyFrom(entityCollector.camera.viewProjection);

			//update deferred rendering properties
			_useDeferredLighting = entityCollector.numDeferredDirectionalLights > 0 || entityCollector.numDeferredPointLights > 0;
			if (!_useDeferredLighting) {
				if (lightAccumulation) {
					lightAccumulation.dispose();
					lightAccumulation = null;
				}
				if (lightAccumulationSpecular) {
					lightAccumulationSpecular.dispose();
					lightAccumulationSpecular = null;
				}
			}

			_useDeferredColoredSpecular = entityCollector.coloredSpecularDeferredLights;
			if (!_useDeferredColoredSpecular && lightAccumulationSpecular) {
				lightAccumulationSpecular.dispose();
			}

			_useDeferredSpecularLighting = entityCollector.hasSpecularDeferredLights;
			_useDeferredDiffuseLighting = entityCollector.hasDiffuseDeferredLights;

			_textureRatioX = 1;
			_textureRatioY = 1;
			//if RectangleRenderTextures are not avaliable
			if ((filter3DRenderer || _useDeferredLighting) && !hasRectangleRenderTargetSupport) {
				_textureRatioX = _rttBufferManager.textureRatioX;
				_textureRatioY = _rttBufferManager.textureRatioY;
				_rttViewProjectionMatrix.appendScale(_textureRatioX, _textureRatioY, 1);
			}

			sceneDepthTexture = updateScreenRenderTargetTexture(sceneDepthTexture);
			if (_useDeferredLighting) {
				sceneNormalTexture = updateScreenRenderTargetTexture(sceneNormalTexture);
			}

			if (_useDeferredLighting && hasMRTSupport) {
				_context3D.setRenderToTexture(sceneDepthTexture.getTextureForStage3D(_stage3DProxy), true, _antiAlias, 0, 0);
				_context3D.setRenderToTexture(sceneNormalTexture.getTextureForStage3D(_stage3DProxy), true, _antiAlias, 0, 1);
				_context3D.clear();

				_gbufferRenderer.render(_stage3DProxy, opaqueRenderableHead, camera, _rttViewProjectionMatrix);

				_context3D.setRenderToTexture(null, true, _antiAlias, 0, 0);
				_context3D.setRenderToTexture(null, true, _antiAlias, 0, 1);
				_context3D.setRenderToBackBuffer();
			} else {
				if (_useDeferredLighting || _requireDepthRender) {
					_depthRenderer.textureRatioX = _textureRatioX;
					_depthRenderer.textureRatioY = _textureRatioY;
					_depthRenderer.renderScene(entityCollector, sceneDepthTexture.getTextureForStage3D(_stage3DProxy), _rttBufferManager.renderToTextureRect);
				}

				if (_useDeferredLighting) {
					_context3D.setRenderToTexture(sceneNormalTexture.getTextureForStage3D(_stage3DProxy), true, _antiAlias);
					_context3D.clear();
					_context3D.setScissorRectangle(_rttBufferManager.renderToTextureRect);
					_worldNormalRenderer.render(stage3DProxy, opaqueRenderableHead, entityCollector.camera, _rttViewProjectionMatrix);
					_context3D.setScissorRectangle(null);
					_context3D.setRenderToTexture(null, true, _antiAlias);
					_context3D.setRenderToBackBuffer();
				}
			}

			if (_depthPrepass) {
				renderDepthPrepass(entityCollector as EntityCollector);
			}

			//calculate deferred lighting buffers
			//TODO: downsampled lightbuffer support
			if (_useDeferredLighting) {
				lightAccumulation = updateScreenRenderTargetTexture(lightAccumulation);
				_context3D.setRenderToTexture(lightAccumulation.getTextureForStage3D(_stage3DProxy), true, 0, 0, 0);
				updateFrustumCorners(camera);

				if (_useDeferredColoredSpecular) {
					lightAccumulationSpecular = updateScreenRenderTargetTexture(lightAccumulationSpecular);
					_context3D.setRenderToTexture(lightAccumulationSpecular.getTextureForStage3D(_stage3DProxy), true, 0, 0, 1);
				}

				stage3DProxy.clearBuffers();
				_context3D.clear();

				if (!_lightRenderer) _lightRenderer = new PointLightRenderer();
				_lightRenderer.textureRatioX = _textureRatioX;
				_lightRenderer.textureRatioY = _textureRatioY;
				_lightRenderer.diffuseEnabled = _useDeferredDiffuseLighting;
				_lightRenderer.specularEnabled = _useDeferredSpecularLighting;
				_lightRenderer.coloredSpecularOutput = _useDeferredColoredSpecular;
				_lightRenderer.render(_stage3DProxy, entityCollector as EntityCollector, hasMRTSupport, _frustumCorners, sceneNormalTexture, sceneDepthTexture);

				_context3D.setRenderToTexture(null, true, 0, 0, 0);
				_context3D.setRenderToTexture(null, true, 0, 0, 1);
				_context3D.setRenderToBackBuffer();
			}
			_stage3DProxy.clearBuffers();

			if (filter3DRenderer && _stage3DProxy.context3D) {
				renderScene(entityCollector, filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
				if (filter3DRenderer.requireDepthRender) {
					filter3DRenderer.render(_stage3DProxy, entityCollector.camera, sceneDepthTexture.getTextureForStage3D(_stage3DProxy) as Texture, _shareContext);
				} else {
					filter3DRenderer.render(_stage3DProxy, entityCollector.camera, null, _shareContext);
				}
			} else
				if (_shareContext) {
					renderScene(entityCollector, null, _scissorRect);
				} else {
					renderScene(entityCollector);
				}

			super.render(entityCollector);

			if (Debug.showGBuffer) {
				if (!_renderTargetToScreenCopy) _renderTargetToScreenCopy = new RenderTargetCopy();
				_context3D.setRenderToBackBuffer();
				var numTextures:int = 0;

				if (_useDeferredLighting || _requireDepthRender) {
					_context3D.setTextureAt(0, sceneDepthTexture.getTextureForStage3D(_stage3DProxy));
					numTextures++;
				}

				if (_useDeferredLighting) {
					numTextures++;
					_context3D.setTextureAt(1, sceneNormalTexture.getTextureForStage3D(_stage3DProxy));

					numTextures++;
					_context3D.setTextureAt(2, lightAccumulation.getTextureForStage3D(_stage3DProxy));

					if (_useDeferredColoredSpecular && lightAccumulationSpecular) {
						numTextures++;
						_context3D.setTextureAt(3, lightAccumulationSpecular.getTextureForStage3D(_stage3DProxy));
					}
				}

				if (numTextures > 0) {
					_renderTargetToScreenCopy.draw(_stage3DProxy, numTextures, _textureRatioX, _textureRatioY);
				}
			}

			if (!_shareContext) {
				_stage3DProxy.present();
			}

			_stage3DProxy.clearBuffers();
			_stage3DProxy.bufferClear = false;
		}

		private static function updateFrustumCorners(camera:Camera3D):Vector.<Number>
		{
			var j:uint;
			var k:uint;
			var frustumCorners:Vector.<Number> = camera.projection.frustumCorners;
			while (j < 12) {
				_frustumCorners[k++] = frustumCorners[j++];
				_frustumCorners[k++] = frustumCorners[j++];
				_frustumCorners[k++] = frustumCorners[j++];
				_frustumCorners[k++] = 1;
			}
			return _frustumCorners;
		}

		override protected function executeRender(entityCollector:ICollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:int = 0):void
		{
			updateShadows(entityCollector);

			// otherwise RTT will interfere with other RTTs
			if (target) {
				drawRenderables(opaqueRenderableHead, entityCollector);
				drawRenderables(blendedRenderableHead, entityCollector);
			}
			super.executeRender(entityCollector, target, scissorRect, surfaceSelector);
		}

		private function updateShadows(collector:ICollector):void
		{
			_depthRenderer.textureRatioX = 1;
			_depthRenderer.textureRatioY = 1;
			var entityCollector:EntityCollector = collector as EntityCollector;
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
		override protected function draw(collector:ICollector, target:TextureBase):void
		{
			var entityCollector:EntityCollector = collector as EntityCollector;
			if (!target) {
				collectRenderables(entityCollector);
			}
			_context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

			if (entityCollector.skyBox) {
				if (_activeMaterial)
					_activeMaterial.deactivate(_stage3DProxy);
				_activeMaterial = null;

				_context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
				drawSkyBox(entityCollector);
			}

			_context3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);

			var which:int = target ? SCREEN_PASSES : ALL_PASSES;
			drawRenderables(opaqueRenderableHead, entityCollector, which, _useDeferredLighting);
			drawRenderables(blendedRenderableHead, entityCollector, which);

			_context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);

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
			var skyBox:RenderableBase = entityCollector.skyBox;
			var material:MaterialBase = skyBox.material;
			var camera:Camera3D = entityCollector.camera;

			updateSkyBoxProjection(camera);

			material.activatePass(0, _stage3DProxy, camera);
			material.renderPass(0, skyBox, _stage3DProxy, entityCollector, _skyboxProjection);
			material.deactivatePass(0, _stage3DProxy);
		}

		private function updateSkyBoxProjection(camera:Camera3D):void
		{
			_skyboxProjection.copyFrom(_rttViewProjectionMatrix);
			_skyboxProjection.copyRowTo(2, _skyboxTempVector);
			var camPos:Vector3D = camera.scenePosition;
			var cx:Number = _skyboxTempVector.x;
			var cy:Number = _skyboxTempVector.y;
			var cz:Number = _skyboxTempVector.z;
			var length:Number = Math.sqrt(cx * cx + cy * cy + cz * cz);

			_skyboxTempVector.x = 0;
			_skyboxTempVector.y = 0;
			_skyboxTempVector.z = 0;
			_skyboxTempVector.w = 1;
			_tempSkyboxMatrix.copyFrom(camera.sceneTransform);
			_tempSkyboxMatrix.copyColumnFrom(3, _skyboxTempVector);

			_skyboxTempVector.x = 0;
			_skyboxTempVector.y = 0;
			_skyboxTempVector.z = 1;
			_skyboxTempVector.w = 0;

			Matrix3DUtils.transformVector(_tempSkyboxMatrix, _skyboxTempVector, _skyboxTempVector);
			_skyboxTempVector.normalize();

			var angle:Number = Math.acos(_skyboxTempVector.x * (cx / length) + _skyboxTempVector.y * (cy / length) + _skyboxTempVector.z * (cz / length));
			if (Math.abs(angle) > 0.000001) {
				return;
			}

			var cw:Number = -(cx * camPos.x + cy * camPos.y + cz * camPos.z + length);
			var signX:Number = cx >= 0 ? 1 : -1;
			var signY:Number = cy >= 0 ? 1 : -1;

			var p:Vector3D = _skyboxTempVector;
			p.x = signX;
			p.y = signY;
			p.z = 1;
			p.w = 1;
			_tempSkyboxMatrix.copyFrom(_skyboxProjection);
			_tempSkyboxMatrix.invert();
			var q:Vector3D = Matrix3DUtils.transformVector(_tempSkyboxMatrix, p, Matrix3DUtils.CALCULATION_VECTOR3D);
			_skyboxProjection.copyRowTo(3, p);
			var a:Number = (q.x * p.x + q.y * p.y + q.z * p.z + q.w * p.w) / (cx * q.x + cy * q.y + cz * q.z + cw * q.w);
			_skyboxTempVector.x = cx * a;
			_skyboxTempVector.y = cy * a;
			_skyboxTempVector.z = cz * a;
			_skyboxTempVector.w = cw * a;
			//copy changed near far
			_skyboxProjection.copyRowFrom(2, _skyboxTempVector);
		}

		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param entityCollector The EntityCollector containing all potentially visible information.
		 */
		private function drawRenderables(renderable:RenderableBase, collector:ICollector):void
		{
			var entityCollector:EntityCollector = collector as EntityCollector;
			var i:int;
			var len:int;
			var passes:Vector.<IMaterialPass>;
			var activePass:MaterialPassData;
			var activeMaterial:MaterialData;

			var context:Context3D = _stage3DProxy.context3D;
			var camera:Camera3D = entityCollector.camera;
			var renderable2:RenderableBase;

			while (renderable) {
				activeMaterial = context.getMaterial(renderable.material, _stage3DProxy.profile);

				//iterate through each screen pass
				passes = renderable.material.screenPasses;
				len = renderable.material.numScreenPasses();
				for (i = 0; i < len; i++) {
					renderable2 = renderable;

					activePass = activeMaterial.getMaterialPass(passes[i] as MaterialPassBase, _stage3DProxy.profile);

					renderable.material.activatePass(activePass, _stage3DProxy, camera);

					do {
						renderable.material.renderPass(activePass, renderable2, _stage3DProxy, camera, _rttViewProjectionMatrix);

						renderable2 = renderable2.next as RenderableBase;

					} while (renderable2 && renderable2.material == renderable.material);

					activeMaterial.material.deactivatePass(activePass, _stage3DProxy);
				}

				renderable = renderable2;
			}
		}

		override public function dispose():void
		{
			super.dispose();
			_depthRenderer.dispose();
			_distanceRenderer.dispose();
			_depthRenderer = null;
			_distanceRenderer = null;
			_worldNormalRenderer = null;
			_gbufferRenderer = null;
		}

		protected function renderDepthPrepass(entityCollector:EntityCollector):void
		{
			_depthRenderer.disableColor = true;

			if (filter3DRenderer) {
				_depthRenderer.textureRatioX = _rttBufferManager.textureRatioX;
				_depthRenderer.textureRatioY = _rttBufferManager.textureRatioY;
				_depthRenderer.renderScene(entityCollector, filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
			} else {
				_depthRenderer.textureRatioX = 1;
				_depthRenderer.textureRatioY = 1;
				_depthRenderer.renderScene(entityCollector);
			}

			_depthRenderer.disableColor = false;
		}

		/**
		 * Updates the backbuffer dimensions.
		 */
		protected function updateBackBuffer():void
		{
			if (!_stage3DProxy.context3D) return;
			// No reason trying to configure back buffer if there is no context available.
			// Doing this anyway (and relying on _stageGL to cache width/height for
			// context does get available) means usesSoftwareRendering won't be reliable.
			if (!_shareContext) {
				if (_width && _height) {
					_stage3DProxy.configureBackBuffer(_width, _height, _antiAlias);
					_backBufferInvalid = false;
				}
			}
		}

		/**
		 * Updates rendertarget. It depends on profile type usage. if we have rectangle textures support
		 */
		private function updateScreenRenderTargetTexture(renderTarget:RenderTexture, format:String = Context3DTextureFormat.BGRA):RenderTexture
		{
			var targetWidth:Number = _rttBufferManager.textureWidth;
			var targetHeight:Number = _rttBufferManager.textureHeight;

			if (hasRectangleRenderTargetSupport) {
				targetWidth = _width;
				targetHeight = _height;
			}

			var result:RenderTexture = renderTarget;
			if ((!result && hasRectangleRenderTargetSupport) || (hasRectangleRenderTargetSupport && !(result is RectangleRenderTexture))) {
				if (result) result.dispose();
				result = new RectangleRenderTexture(targetWidth, targetHeight, format);
			} else
				if ((!result && !hasRectangleRenderTargetSupport) || (!hasRectangleRenderTargetSupport && !(result is RenderTexture))) {
					if (result) result.dispose();
					result = new RenderTexture(targetWidth, targetHeight);
				}

			result.width = targetWidth;
			result.height = targetHeight;
			return result;
		}

		public function get hasRectangleRenderTargetSupport():Boolean
		{
			return _profile == Context3DProfile.STANDARD;
		}

		public function get hasMRTSupport():Boolean
		{
			return _profile == Context3DProfile.STANDARD;
		}
	}
}