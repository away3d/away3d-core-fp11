package away3d.core.render
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.TriangleSubMesh;
	import away3d.core.base.LineSubMesh;
	import away3d.core.managers.RTTBufferManager;
	import away3d.core.managers.Stage3DManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.pool.BillboardRenderable;
	import away3d.core.pool.EntityListItem;
	import away3d.core.pool.LineSubMeshRenderable;
	import away3d.core.pool.RenderableBase;
	import away3d.core.pool.RenderablePool;
	import away3d.core.pool.SkyBoxRenderable;
	import away3d.core.pool.TriangleSubMeshRenderable;
	import away3d.core.sort.IEntitySorter;
	import away3d.core.sort.RenderableMergeSort;
	import away3d.core.traverse.EntityCollector;
	import away3d.core.traverse.ICollector;
	import away3d.entities.Billboard;
	import away3d.entities.Camera3D;
	import away3d.entities.IEntity;
	import away3d.entities.SkyBox;
	import away3d.errors.AbstractMethodError;
	import away3d.events.RendererEvent;
	import away3d.events.Stage3DEvent;
	import away3d.events.Stage3DEvent;
	import away3d.materials.IMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.projections.PerspectiveProjection;
	import away3d.textures.Texture2DBase;
	
	import flash.display.BitmapData;
	import flash.display.Stage;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	use namespace arcane;
	
	/**
	 * RendererBase forms an abstract base class for classes that are used in the rendering pipeline to render geometry
	 * to the back buffer or a texture.
	 */
	public class RendererBase extends EventDispatcher implements IRenderer
	{
		private var _billboardRenderablePool:RenderablePool;
		private var _skyboxRenderablePool:RenderablePool;
		private var _triangleSubMeshRenderablePool:RenderablePool;
		private var _lineSubMeshRenderablePool:RenderablePool;
		
		protected var _context3D:Context3D;
		protected var _stage3DProxy:Stage3DProxy;

		protected var camera:Camera3D;
		arcane var _entryPoint:Vector3D;
		protected var cameraForward:Vector3D;
	
		protected var _rttBufferManager:RTTBufferManager;
		private var _viewPort:Rectangle = new Rectangle();
		private var _viewportDirty:Boolean;
		private var _scissorDirty:Boolean;
	
		protected var _backBufferInvalid:Boolean = true;
		protected var _depthTextureInvalid:Boolean = true;
		public var _depthPrepass:Boolean = false;

		private var _backgroundImageRenderer:BackgroundImageRenderer;
		private var _background:Texture2DBase;
		protected var _backgroundR:Number = 0;
		protected var _backgroundG:Number = 0;
		protected var _backgroundB:Number = 0;
		protected var _backgroundAlpha:Number = 1;

		protected var _shareContext:Boolean = false;
		
		protected var _renderTarget:TextureBase;
		protected var _renderTargetSurface:int;
		
		// only used by renderers that need to render geometry to textures
		protected var _width:Number;
		protected var _height:Number;

		protected var _renderToTexture:Boolean;
		protected var _textureRatioX:Number = 1;
		protected var _textureRatioY:Number = 1;

		private var _snapshotBitmapData:BitmapData;
		private var _snapshotRequired:Boolean;


		protected var _rttViewProjectionMatrix:Matrix3D = new Matrix3D();

		private var _localPos:Point = new Point();
		private var _globalPos:Point = new Point();
		protected var _scissorRect:Rectangle = new Rectangle();

		protected var _numTriangles:Number = 0;

		protected var opaqueRenderableHead:RenderableBase;
		protected var blendedRenderableHead:RenderableBase;
		protected var _renderableSorter:IEntitySorter;
		protected var _antiAlias:Number;

		private var _entityCollector:ICollector;

		public function get antiAlias():Number
		{
			return _antiAlias;
		}

		public function set antiAlias(value:Number):void
		{
			if (_antiAlias == value)
				return;

			_antiAlias = value;

			_backBufferInvalid = true;
		}

		/**
		 *
		 */
		public function get numTriangles():Number
		{
			return _numTriangles;
		}

		/**
		 * A viewPort rectangle equivalent of the StageGL size and position.
		 */
		public function get viewPort():Rectangle
		{
			return _viewPort;
		}

		/**
		 * A scissor rectangle equivalent of the view size and position.
		 */
		public function get scissorRect():Rectangle
		{
			return _scissorRect;
		}

		/**
		 *
		 */
		public function get x():Number
		{
			return _localPos.x;
		}

		public function set x(value:Number):void
		{
			if (_localPos.x == value)
				return;

			_globalPos.x = _localPos.x = value;

			updateGlobalPos();
		}

		/**
		 *
		 */
		public function get y():Number
		{
			return _localPos.y;
		}

		public function set y(value:Number):void
		{
			if (y == value)
				return;

			_globalPos.y = _localPos.y = value;

			updateGlobalPos();
		}
		
		/**
		 *
		 */
		public function get width():Number
		{
			return _width;
		}

		public function set width(value:Number):void
		{
			if (_width == value)
				return;

			_width = value;
			_scissorRect.width = value;
			_viewPort.width = value;

			if (_rttBufferManager)
				_rttBufferManager.viewWidth = value;

			_backBufferInvalid = true;
			_depthTextureInvalid = true;

			notifyScissorUpdate();
		}

		/**
		 *
		 */
		public function get height():Number
		{
			return _height;
		}

		public function set height(value:Number):void
		{
			if (_height == value)
				return;

			_height = value;
			_scissorRect.height = value;
			_viewPort.height = value;

			if (_rttBufferManager)
				_rttBufferManager.viewHeight = value;

			_backBufferInvalid = true;
			_depthTextureInvalid = true;

			notifyScissorUpdate();
		}
		
		/**
		 * Creates a new RendererBase object.
		 */
		public function RendererBase(renderToTexture:Boolean = false)
		{
			super();

			_billboardRenderablePool = RenderablePool.getPool(BillboardRenderable);
			_skyboxRenderablePool = RenderablePool.getPool(SkyBoxRenderable);
			_triangleSubMeshRenderablePool = RenderablePool.getPool(TriangleSubMeshRenderable);
			_lineSubMeshRenderablePool = RenderablePool.getPool(LineSubMeshRenderable);

			_renderToTexture = renderToTexture;

			//default sorting algorithm
			_renderableSorter = new RenderableMergeSort();
		}

		public function init(stage:Stage):void {

		}
		
		public function createEntityCollector():ICollector
		{
			return new EntityCollector();
		}
		
		arcane function get renderToTexture():Boolean
		{
			return _renderToTexture;
		}

		/**
		 * The background color's red component, used when clearing.
		 *
		 * @private
		 */
		public function get backgroundR():Number
		{
			return _backgroundR;
		}

		public function set backgroundR(value:Number):void
		{
			if(_backgroundR == value) return;
			_backgroundR = value;
			_backBufferInvalid = true;
		}
		
		/**
		 * The background color's green component, used when clearing.
		 *
		 * @private
		 */
		public function get backgroundG():Number
		{
			return _backgroundG;
		}

		public function set backgroundG(value:Number):void
		{
			if(_backgroundG == value) return;
			_backgroundG = value;
			_backBufferInvalid = true;
		}
		
		/**
		 * The background color's blue component, used when clearing.
		 *
		 * @private
		 */
		public function get backgroundB():Number
		{
			return _backgroundB;
		}

		public function set backgroundB(value:Number):void
		{
			if(_backgroundB == value) return;
			_backgroundB = value;
			_backBufferInvalid = true;
		}
		
		/**
		 * The Stage3DProxy that will provide the Context3D used for rendering.
		 *
		 * @private
		 */
		public function get stage3DProxy():Stage3DProxy
		{
			return _stage3DProxy;
		}

		public function set stage3DProxy(value:Stage3DProxy):void
		{
			if (value == _stage3DProxy)
				return;
			
			if (!value) {
				if (_stage3DProxy) {
					_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
					_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
					_stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
				}
				_stage3DProxy = null;
				_context3D = null;
				return;
			}
			//else if (_stage3DProxy) throw new Error("A Stage3D instance was already assigned!");
			
			_stage3DProxy = value;
			_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
			_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
			_stage3DProxy.addEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);

			if (_backgroundImageRenderer)
				_backgroundImageRenderer.stage3DProxy = value;
			
			if (value.context3D)
				_context3D = value.context3D;
		}

		/**
		 * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
		 * to share the same Context3D object.
		 *
		 * @private
		 */
		public function get shareContext():Boolean
		{
			return _shareContext;
		}

		public function set shareContext(value:Boolean):void
		{
			if(_shareContext == value) return;
			_shareContext = value;
			updateGlobalPos();
		}

		/**
		 * Disposes the resources used by the RendererBase.
		 *
		 * @private
		 */
		public function dispose():void
		{
			if (_rttBufferManager)
				_rttBufferManager.dispose();

			_rttBufferManager = null;

			_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
			_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate)
			_stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);

			_stage3DProxy = null;
			
			if (_backgroundImageRenderer) {
				_backgroundImageRenderer.dispose();
				_backgroundImageRenderer = null;
			}
		}

		public function render(entityCollector:ICollector):void
		{
			_entityCollector = entityCollector;
			this._viewportDirty = false;
			this._scissorDirty = false;
		}

		/**
		 * Renders the potentially visible geometry to the back buffer or texture.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		arcane function renderScene(entityCollector:ICollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:Number = 0):void
		{
			if (!_stage3DProxy || !_context3D)
				return;

			_rttViewProjectionMatrix.copyFrom(entityCollector.camera.viewProjection);
			_rttViewProjectionMatrix.appendScale(_textureRatioX, _textureRatioY, 1);

			executeRender(entityCollector, target, scissorRect, surfaceSelector);

			// clear buffers
			for (var i:uint = 0; i < 8; ++i) {
				_context3D.setVertexBufferAt(i, null);
				_context3D.setTextureAt(i, null);
			}
		}

		protected function collectRenderables(entityCollector:ICollector):void
		{
			//reset head values
			blendedRenderableHead = null;
			opaqueRenderableHead = null;
			_numTriangles = 0;

			//grab entity head
			var item:EntityListItem = entityCollector.entityHead;

			//set temp values for entry point and camera forward vector
			camera = entityCollector.camera;
			_entryPoint = camera.scenePosition;
			cameraForward = camera.forwardVector;

			//iterate through all entities
			while (item) {
				item.entity.collectRenderables(this);
				item = item.next;
			}

			//sort the resulting renderables
			opaqueRenderableHead = renderableSorter.sortOpaqueRenderables(opaqueRenderableHead) as RenderableBase;
			blendedRenderableHead = renderableSorter.sortBlendedRenderables(blendedRenderableHead) as RenderableBase;
		}

		/**
		 * Renders the potentially visible geometry to the back buffer or texture. Only executed if everything is set up.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		protected function executeRender(entityCollector:ICollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:int = 0):void
		{
			_renderTarget = target;
			_renderTargetSurface = surfaceSelector;
			
			if (_renderToTexture)
				executeRenderToTexturePass(entityCollector);
			
			_stage3DProxy.setRenderTarget(target, true, surfaceSelector);
			
			if ((target || !_shareContext) && !_depthPrepass)
				_context3D.clear(_backgroundR, _backgroundG, _backgroundB, _backgroundAlpha, 1, 0);

			_context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

			_stage3DProxy.scissorRect = scissorRect;

			if (_backgroundImageRenderer)
				_backgroundImageRenderer.render();
			
			draw(entityCollector, target);
			
			//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
			_context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
			
			if (!_shareContext) {
				if (_snapshotRequired && _snapshotBitmapData) {
					_context3D.drawToBitmapData(_snapshotBitmapData);
					_snapshotRequired = false;
				}
			}
			_stage3DProxy.scissorRect = null;
		}

		/*
		 * Will draw the renderer's output on next render to the provided bitmap data.
		 * */
		public function queueSnapshot(bmd:BitmapData):void
		{
			_snapshotRequired = true;
			_snapshotBitmapData = bmd;
		}
		
		protected function executeRenderToTexturePass(entityCollector:ICollector):void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Performs the actual drawing of geometry to the target.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 */
		protected function draw(entityCollector:ICollector, target:TextureBase):void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Assign the context once retrieved
		 */
		private function onContextUpdate(event:Event):void
		{
			_context3D = _stage3DProxy.context3D;
		}
		
		public function get backgroundAlpha():Number
		{
			return _backgroundAlpha;
		}
		
		public function set backgroundAlpha(value:Number):void
		{
			_backgroundAlpha = value;
		}
		
		public function get background():Texture2DBase
		{
			return _background;
		}
		
		public function set background(value:Texture2DBase):void
		{
			if (_backgroundImageRenderer && !value) {
				_backgroundImageRenderer.dispose();
				_backgroundImageRenderer = null;
			}
			
			if (!_backgroundImageRenderer && value)
				_backgroundImageRenderer = new BackgroundImageRenderer(_stage3DProxy);
			
			_background = value;
			
			if (_backgroundImageRenderer)
				_backgroundImageRenderer.texture = value;
		}

		public function get backgroundImageRenderer():BackgroundImageRenderer
		{
			return _backgroundImageRenderer;
		}
		
		arcane function get textureRatioX():Number
		{
			return _textureRatioX;
		}
		
		arcane function set textureRatioX(value:Number):void
		{
			_textureRatioX = value;
		}
		
		arcane function get textureRatioY():Number
		{
			return _textureRatioY;
		}
		
		arcane function set textureRatioY(value:Number):void
		{
			_textureRatioY = value;
		}

		/**
		 * @private
		 */
		private function notifyScissorUpdate():void
		{
			if (_scissorDirty)
				return;

			_scissorDirty = true;

			dispatchEvent(new RendererEvent(RendererEvent.SCISSOR_UPDATED));
		}


		/**
		 * @private
		 */
		private function notifyViewportUpdate():void
		{
			if (_viewportDirty)
				return;

			_viewportDirty = true;

			dispatchEvent(new RendererEvent(RendererEvent.VIEWPORT_UPDATED));
		}

		/**
		 *
		 */
		public function onViewportUpdated(event:Stage3DEvent):void
		{
			_viewPort = _stage3DProxy.viewPort;
			//TODO stop firing viewport updated for every stagegl viewport change

			if (_shareContext) {
				_scissorRect.x = _globalPos.x - _stage3DProxy.x;
				_scissorRect.y = _globalPos.y - _stage3DProxy.y;
				notifyScissorUpdate();
			}

			notifyViewportUpdate();
		}

		/**
		 *
		 */
		public function updateGlobalPos():void
		{
			if (_shareContext) {
				_scissorRect.x = _globalPos.x - _viewPort.x;
				_scissorRect.y = _globalPos.y - _viewPort.y;
			} else {
				_scissorRect.x = 0;
				_scissorRect.y = 0;
				_viewPort.x = _globalPos.x;
				_viewPort.y = _globalPos.y;
			}

			notifyScissorUpdate();
		}


		/**
		 *
		 * @param billboard
		 * @protected
		 */
		public function applyBillboard(billboard:Billboard):void
		{
			applyRenderable(_billboardRenderablePool.getItem(billboard) as RenderableBase);
		}

		/**
		 *
		 * @param triangleSubMesh
		 */
		public function applyTriangleSubMesh(triangleSubMesh:TriangleSubMesh):void
		{
			applyRenderable(_triangleSubMeshRenderablePool.getItem(triangleSubMesh) as RenderableBase);
		}

		/**
		 *
		 * @param lineSubMesh
		 */
		public function applyLineSubMesh(lineSubMesh:LineSubMesh):void
		{
			applyRenderable(_lineSubMeshRenderablePool.getItem(lineSubMesh) as RenderableBase);
		}

		/**
		 *
		 * @param skybox
		 */
		public function applySkybox(skybox:SkyBox):void
		{
			applyRenderable(_skyboxRenderablePool.getItem(skybox) as RenderableBase);
		}

		/**
		 *
		 * @param renderable
		 * @protected
		 */
		private function applyRenderable(renderable:RenderableBase):void
		{
			var material:IMaterial = renderable.materialOwner.material;
			var entity:IEntity = renderable.sourceEntity;
			var position:Vector3D = entity.scenePosition;

			if (!material)
				material = DefaultMaterialManager.getDefaultMaterial(renderable.materialOwner);

			//set ids for faster referencing
			renderable.material = material as MaterialBase;
			renderable.materialId = material.materialId;
			renderable.renderOrderId = material.renderOrderId;
			renderable.cascaded = false;

			// project onto camera's z-axis
			position = _entryPoint.subtract(position);
			renderable.zIndex = entity.zOffset + position.dotProduct(cameraForward);

			//store reference to scene transform
			renderable.renderSceneTransform = renderable.sourceEntity.getRenderSceneTransform(camera);

			if (material.requiresBlending) {
				renderable.next = blendedRenderableHead;
				blendedRenderableHead = renderable;
			} else {
				renderable.next = opaqueRenderableHead;
				opaqueRenderableHead = renderable;
			}

			_numTriangles += renderable.numTriangles;

			//handle any overflow for renderables with data that exceeds GPU limitations
			if (renderable.overflow)
				applyRenderable(renderable.overflow);
			}

		public function get renderableSorter():IEntitySorter {
			return _renderableSorter;
		}

		public function get depthPrepass():Boolean
		{
			return _depthPrepass;
		}

		public function set depthPrepass(value:Boolean):void
		{
			_depthPrepass = value;
		}

		private var _cameras:Vector.<Camera3D>;
		private var _lenses:Vector.<PerspectiveProjection>;
		private var _container:ObjectContainer3D;
		protected var _cubeRenderer:RendererBase;

		private function initCameras():void
		{
			_cameras = new Vector.<Camera3D>();
			_lenses = new Vector.<PerspectiveProjection>();
			_container = new ObjectContainer3D();
			_entityCollector.scene.addChild(_container);
			// posX, negX, posY, negY, posZ, negZ
			addCamera(0, 90, 0);
			addCamera(0, -90, 0);
			addCamera(-90, 0, 0);
			addCamera(90, 0, 0);
			addCamera(0, 0, 0);
			addCamera(0, 180, 0);

			_cubeRenderer = new DefaultRenderer();
			_cubeRenderer.stage3DProxy = stage3DProxy;
			_cubeRenderer.shareContext = shareContext;
			_cubeRenderer.backgroundAlpha = 0;
		}

		private function addCamera(rotationX:Number, rotationY:Number, rotationZ:Number):void
		{
			var cam:Camera3D = new Camera3D();
			cam.position = new Vector3D(0,0,0);
			_container.addChild(cam);
			cam.rotationX = rotationX;
			cam.rotationY = rotationY;
			cam.rotationZ = rotationZ;
			cam.projection.near = .01;
			PerspectiveProjection(cam.projection).fieldOfView = 90;
			_lenses.push(PerspectiveProjection(cam.projection));
			cam.projection.aspectRatio = 1;
			_cameras.push(cam);
		}

	}
}
