package away3d.containers
{
	
	import away3d.core.managers.Touch3DManager;
	import away3d.events.Scene3DEvent;
	
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Transform;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.getTimer;
	
	import away3d.Away3D;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Mouse3DManager;
	import away3d.core.managers.RTTBufferManager;
	import away3d.core.managers.Stage3DManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.pick.IPicker;
	import away3d.core.render.DefaultRenderer;
	import away3d.core.render.DepthRenderer;
	import away3d.core.render.Filter3DRenderer;
	import away3d.core.render.RendererBase;
	import away3d.core.traverse.EntityCollector;
	import away3d.events.CameraEvent;
	import away3d.events.Stage3DEvent;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	public class View3D extends Sprite
	{
		private var _width:Number = 0;
		private var _height:Number = 0;
		private var _localPos:Point = new Point();
		private var _globalPos:Point = new Point();
		private var _globalPosDirty:Boolean;
		protected var _scene:Scene3D;
		protected var _camera:Camera3D;
		protected var _entityCollector:EntityCollector;
		
		protected var _aspectRatio:Number;
		private var _time:Number = 0;
		private var _deltaTime:uint;
		private var _backgroundColor:uint = 0x000000;
		private var _backgroundAlpha:Number = 1;
		
		protected var _mouse3DManager:Mouse3DManager;
		
		protected var _touch3DManager:Touch3DManager;
		
		protected var _renderer:RendererBase;
		private var _depthRenderer:DepthRenderer;
		private var _addedToStage:Boolean;
		
		private var _forceSoftware:Boolean;
		
		protected var _filter3DRenderer:Filter3DRenderer;
		protected var _requireDepthRender:Boolean;
		protected var _depthRender:Texture;
		private var _depthTextureInvalid:Boolean = true;
		
		private var _hitField:Sprite;
		protected var _parentIsStage:Boolean;
		
		private var _background:Texture2DBase;
		protected var _stage3DProxy:Stage3DProxy;
		protected var _backBufferInvalid:Boolean = true;
		private var _antiAlias:uint;
		
		protected var _rttBufferManager:RTTBufferManager;
		
		private var _rightClickMenuEnabled:Boolean = true;
		private var _sourceURL:String;
		private var _menu0:ContextMenuItem;
		private var _menu1:ContextMenuItem;
		private var _ViewContextMenu:ContextMenu;
		protected var _shareContext:Boolean = false;
		protected var _scissorRect:Rectangle;
		private var _scissorRectDirty:Boolean = true;
		private var _viewportDirty:Boolean = true;
		
		private var _depthPrepass:Boolean;
		private var _profile:String;
		private var _layeredView:Boolean = false;
		
		private function viewSource(e:ContextMenuEvent):void
		{
			var request:URLRequest = new URLRequest(_sourceURL);
			try {
				navigateToURL(request, "_blank");
			} catch (error:Error) {
				
			}
		}
		
		public function get depthPrepass():Boolean
		{
			return _depthPrepass;
		}
		
		public function set depthPrepass(value:Boolean):void
		{
			_depthPrepass = value;
		}
		
		private function visitWebsite(e:ContextMenuEvent):void
		{
			var url:String = Away3D.WEBSITE_URL;
			var request:URLRequest = new URLRequest(url);
			try {
				navigateToURL(request);
			} catch (error:Error) {
				
			}
		}
		
		private function initRightClickMenu():void
		{
			_menu0 = new ContextMenuItem("Away3D.com\tv" + Away3D.MAJOR_VERSION + "." + Away3D.MINOR_VERSION + "." + Away3D.REVISION, true, true, true);
			_menu1 = new ContextMenuItem("View Source", true, true, true);
			_menu0.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, visitWebsite);
			_menu1.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, viewSource);
			_ViewContextMenu = new ContextMenu();
			
			updateRightClickMenu();
		}
		
		private function updateRightClickMenu():void
		{
			if (_rightClickMenuEnabled)
				_ViewContextMenu.customItems = _sourceURL? [_menu0, _menu1] : [_menu0];
			else
				_ViewContextMenu.customItems = [];
			
			contextMenu = _ViewContextMenu;
		}
		
		public function View3D(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, forceSoftware:Boolean = false, profile:String = "baseline")
		{
			super();
			_profile = profile;
			_scene = scene || new Scene3D();
			_scene.addEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
			_camera = camera || new Camera3D();
			_renderer = renderer || new DefaultRenderer();
			_depthRenderer = new DepthRenderer();
			_forceSoftware = forceSoftware;
			
			// todo: entity collector should be defined by renderer
			_entityCollector = _renderer.createEntityCollector();
			_entityCollector.camera = _camera;
			
			_scissorRect = new Rectangle();
			
			initHitField();
			
			_mouse3DManager = new Mouse3DManager();
			_mouse3DManager.enableMouseListeners(this);
			
			_touch3DManager = new Touch3DManager();
			_touch3DManager.view = this;
			_touch3DManager.enableTouchListeners(this);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addEventListener(Event.ADDED, onAdded, false, 0, true);
			
			_camera.addEventListener(CameraEvent.LENS_CHANGED, onLensChanged);
			
			_camera.partition = _scene.partition;
			
			initRightClickMenu();
		}
		
		private function onScenePartitionChanged(event:Scene3DEvent):void
		{
			if (_camera)
				_camera.partition = scene.partition;
		}
		
		public function get rightClickMenuEnabled():Boolean
		{
			return _rightClickMenuEnabled;
		}
		
		public function set rightClickMenuEnabled(val:Boolean):void
		{
			_rightClickMenuEnabled = val;
			
			updateRightClickMenu();
		}
		
		public function get stage3DProxy():Stage3DProxy
		{
			return _stage3DProxy;
		}
		
		public function set stage3DProxy(stage3DProxy:Stage3DProxy):void
		{
			if (_stage3DProxy)
				_stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
			
			_stage3DProxy = stage3DProxy;
			
			_stage3DProxy.addEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
			
			_renderer.stage3DProxy = _depthRenderer.stage3DProxy = _stage3DProxy;
			
			_globalPosDirty = true;
			_backBufferInvalid = true;
		}
		
		/**
		 * Forces mouse-move related events even when the mouse hasn't moved. This allows mouseOver and mouseOut events
		 * etc to be triggered due to changes in the scene graph. Defaults to false.
		 */
		public function get forceMouseMove():Boolean
		{
			return _mouse3DManager.forceMouseMove;
		}
		
		public function set forceMouseMove(value:Boolean):void
		{
			_mouse3DManager.forceMouseMove = value;
			_touch3DManager.forceTouchMove = value;
		}
		
		public function get background():Texture2DBase
		{
			return _background;
		}
		
		public function set background(value:Texture2DBase):void
		{
			_background = value;
			_renderer.background = _background;
		}
		
		/**
		 * Used in a sharedContext. When true, clears the depth buffer prior to rendering this particular
		 * view to avoid depth sorting with lower layers. When false, the depth buffer is not cleared
		 * from the previous (lower) view's render so objects in this view may be occluded by the lower
		 * layer. Defaults to false.
		 */
		public function get layeredView():Boolean
		{
			return _layeredView;
		}
		
		public function set layeredView(value:Boolean):void
		{
			_layeredView = value;
		}
		
		private function initHitField():void
		{
			_hitField = new Sprite();
			_hitField.alpha = 0;
			_hitField.doubleClickEnabled = true;
			_hitField.graphics.beginFill(0x000000);
			_hitField.graphics.drawRect(0, 0, 100, 100);
			addChild(_hitField);
		}
		
		/**
		 * Not supported. Use filters3d instead.
		 */
		override public function get filters():Array
		{
			throw new Error("filters is not supported in View3D. Use filters3d instead.");
			return super.filters;
		}
		
		/**
		 * Not supported. Use filters3d instead.
		 */
		override public function set filters(value:Array):void
		{
			throw new Error("filters is not supported in View3D. Use filters3d instead.");
		}
		
		public function get filters3d():Array
		{
			return _filter3DRenderer? _filter3DRenderer.filters : null;
		}
		
		public function set filters3d(value:Array):void
		{
			if (value && value.length == 0)
				value = null;
			
			if (_filter3DRenderer && !value) {
				_filter3DRenderer.dispose();
				_filter3DRenderer = null;
			} else if (!_filter3DRenderer && value) {
				_filter3DRenderer = new Filter3DRenderer(stage3DProxy);
				_filter3DRenderer.filters = value;
			}
			
			if (_filter3DRenderer) {
				_filter3DRenderer.filters = value;
				_requireDepthRender = _filter3DRenderer.requireDepthRender;
			} else {
				_requireDepthRender = false;
				if (_depthRender) {
					_depthRender.dispose();
					_depthRender = null;
				}
			}
		}
		
		/**
		 * The renderer used to draw the scene.
		 */
		public function get renderer():RendererBase
		{
			return _renderer;
		}
		
		public function set renderer(value:RendererBase):void
		{
			_renderer.dispose();
			_renderer = value;
			_entityCollector = _renderer.createEntityCollector();
			_entityCollector.camera = _camera;
			_renderer.stage3DProxy = _stage3DProxy;
			_renderer.antiAlias = _antiAlias;
			_renderer.backgroundR = ((_backgroundColor >> 16) & 0xff)/0xff;
			_renderer.backgroundG = ((_backgroundColor >> 8) & 0xff)/0xff;
			_renderer.backgroundB = (_backgroundColor & 0xff)/0xff;
			_renderer.backgroundAlpha = _backgroundAlpha;
			_renderer.viewWidth = _width;
			_renderer.viewHeight = _height;
			
			_backBufferInvalid = true;
		}
		
		/**
		 * The background color of the screen. This value is only used when clearAll is set to true.
		 */
		public function get backgroundColor():uint
		{
			return _backgroundColor;
		}
		
		public function set backgroundColor(value:uint):void
		{
			_backgroundColor = value;
			_renderer.backgroundR = ((value >> 16) & 0xff)/0xff;
			_renderer.backgroundG = ((value >> 8) & 0xff)/0xff;
			_renderer.backgroundB = (value & 0xff)/0xff;
		}
		
		public function get backgroundAlpha():Number
		{
			return _backgroundAlpha;
		}
		
		public function set backgroundAlpha(value:Number):void
		{
			if (value > 1)
				value = 1;
			else if (value < 0)
				value = 0;
			
			_renderer.backgroundAlpha = value;
			_backgroundAlpha = value;
		}
		
		/**
		 * The camera that's used to render the scene for this viewport
		 */
		public function get camera():Camera3D
		{
			return _camera;
		}
		
		/**
		 * Set camera that's used to render the scene for this viewport
		 */
		public function set camera(camera:Camera3D):void
		{
			_camera.removeEventListener(CameraEvent.LENS_CHANGED, onLensChanged);
			
			_camera = camera;
			_entityCollector.camera = _camera;
			
			if (_scene)
				_camera.partition = _scene.partition;
			
			_camera.addEventListener(CameraEvent.LENS_CHANGED, onLensChanged);
			
			_scissorRectDirty = true;
			_viewportDirty = true;
		}
		
		/**
		 * The scene that's used to render for this viewport
		 */
		public function get scene():Scene3D
		{
			return _scene;
		}
		
		/**
		 * Set the scene that's used to render for this viewport
		 */
		public function set scene(scene:Scene3D):void
		{
			_scene.removeEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
			_scene = scene;
			_scene.addEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
			
			if (_camera)
				_camera.partition = _scene.partition;
		}
		
		// todo: probably temporary:
		/**
		 * The amount of milliseconds the last render call took
		 */
		public function get deltaTime():uint
		{
			return _deltaTime;
		}
		
		/**
		 * The width of the viewport. When software rendering is used, this is limited by the
		 * platform to 2048 pixels.
		 */
		override public function get width():Number
		{
			return _width;
		}
		
		override public function set width(value:Number):void
		{
			// Backbuffer limitation in software mode. See comment in updateBackBuffer()
			if (_stage3DProxy && _stage3DProxy.usesSoftwareRendering && value > 2048)
				value = 2048;
			
			if (_width == value)
				return;
			
			if (_rttBufferManager)
				_rttBufferManager.viewWidth = value;
			
			_hitField.width = value;
			_width = value;
			_aspectRatio = _width/_height;
			_camera.lens.aspectRatio = _aspectRatio;
			_depthTextureInvalid = true;
			
			_renderer.viewWidth = value;
			
			_scissorRect.width = value;
			
			_backBufferInvalid = true;
			_scissorRectDirty = true;
		}
		
		/**
		 * The height of the viewport. When software rendering is used, this is limited by the
		 * platform to 2048 pixels.
		 */
		override public function get height():Number
		{
			return _height;
		}
		
		override public function set height(value:Number):void
		{
			// Backbuffer limitation in software mode. See comment in updateBackBuffer()
			if (_stage3DProxy && _stage3DProxy.usesSoftwareRendering && value > 2048)
				value = 2048;
			
			if (_height == value)
				return;
			
			if (_rttBufferManager)
				_rttBufferManager.viewHeight = value;
			
			_hitField.height = value;
			_height = value;
			_aspectRatio = _width/_height;
			_camera.lens.aspectRatio = _aspectRatio;
			_depthTextureInvalid = true;
			
			_renderer.viewHeight = value;
			
			_scissorRect.height = value;
			
			_backBufferInvalid = true;
			_scissorRectDirty = true;
		}
		
		override public function set x(value:Number):void
		{
			if (x == value)
				return;
			
			_localPos.x = super.x = value;
			
			_globalPos.x = parent? parent.localToGlobal(_localPos).x : value;
			_globalPosDirty = true;
		}
		
		override public function set y(value:Number):void
		{
			if (y == value)
				return;
			
			_localPos.y = super.y = value;
			
			_globalPos.y = parent? parent.localToGlobal(_localPos).y : value;
			_globalPosDirty = true;
		}
		
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
			
			if (_stage3DProxy && !_shareContext)
				_stage3DProxy.visible = value;
		}
		
		/**
		 * The amount of anti-aliasing to be used.
		 */
		public function get antiAlias():uint
		{
			return _antiAlias;
		}
		
		public function set antiAlias(value:uint):void
		{
			_antiAlias = value;
			_renderer.antiAlias = value;
			
			_backBufferInvalid = true;
		}
		
		/**
		 * The amount of faces that were pushed through the render pipeline on the last frame render.
		 */
		public function get renderedFacesCount():uint
		{
			return _entityCollector.numTriangles;
		}
		
		/**
		 * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
		 * to share the same Context3D object.
		 */
		public function get shareContext():Boolean
		{
			return _shareContext;
		}
		
		public function set shareContext(value:Boolean):void
		{
			if (_shareContext == value)
				return;
			
			_shareContext = value;
			_globalPosDirty = true;
		}
		
		/**
		 * Updates the backbuffer dimensions.
		 */
		protected function updateBackBuffer():void
		{
			// No reason trying to configure back buffer if there is no context available.
			// Doing this anyway (and relying on _stage3DProxy to cache width/height for 
			// context does get available) means usesSoftwareRendering won't be reliable.
			if (_stage3DProxy.context3D && !_shareContext) {
				if (_width && _height) {
					// Backbuffers are limited to 2048x2048 in software mode and
					// trying to configure the backbuffer to be bigger than that
					// will throw an error. Capping the value is a graceful way of
					// avoiding runtime exceptions for developers who are unable
					// to test their Away3D implementation on screens that are 
					// large enough for this error to ever occur.
					if (_stage3DProxy.usesSoftwareRendering) {
						// Even though these checks where already made in the width
						// and height setters, at that point we couldn't be sure that
						// the context had even been retrieved and the software flag
						// thus be reliable. Make checks again.
						if (_width > 2048)
							_width = 2048;
						if (_height > 2048)
							_height = 2048;
					}
					
					_stage3DProxy.configureBackBuffer(_width, _height, _antiAlias, true);
					_backBufferInvalid = false;
				} else {
					width = stage.stageWidth;
					height = stage.stageHeight;
				}
			}
		}
		
		/**
		 * Defines a source url string that can be accessed though a View Source option in the right-click menu.
		 *
		 * Requires the stats panel to be enabled.
		 *
		 * @param    url        The url to the source files.
		 */
		public function addSourceURL(url:String):void
		{
			_sourceURL = url;
			
			updateRightClickMenu();
		}
		
		/**
		 * Renders the view.
		 */
		public function render():void
		{
			//if context3D has Disposed by the OS,don't render at this frame
			if (!stage3DProxy.recoverFromDisposal()) {
				_backBufferInvalid = true;
				return;
			}
			
			// reset or update render settings
			if (_backBufferInvalid)
				updateBackBuffer();
			
			if (_shareContext && _layeredView)
				stage3DProxy.clearDepthBuffer();
			
			if (!_parentIsStage) {
				var globalPos:Point = parent.localToGlobal(_localPos);
				if (_globalPos.x != globalPos.x || _globalPos.y != globalPos.y) {
					_globalPos = globalPos;
					_globalPosDirty = true;
				}
			}
			
			if (_globalPosDirty)
				updateGlobalPos();
			
			updateTime();
			
			updateViewSizeData();
			
			_entityCollector.clear();
			
			// collect stuff to render
			_scene.traversePartitions(_entityCollector);
			
			// update picking
			_mouse3DManager.updateCollider(this);
			_touch3DManager.updateCollider();
			
			if (_requireDepthRender)
				renderSceneDepthToTexture(_entityCollector);
			
			// todo: perform depth prepass after light update and before final render
			if (_depthPrepass)
				renderDepthPrepass(_entityCollector);
			
			_renderer.clearOnRender = !_depthPrepass;
			
			if (_filter3DRenderer && _stage3DProxy._context3D) {
				_renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
				_filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
			} else {
				_renderer.shareContext = _shareContext;
				if (_shareContext)
					_renderer.render(_entityCollector, null, _scissorRect);
				else
					_renderer.render(_entityCollector);
				
			}
			
			if (!_shareContext) {
				stage3DProxy.present();
				
				// fire collected mouse events
				_mouse3DManager.fireMouseEvents();
				_touch3DManager.fireTouchEvents();
			}
			
			// clean up data for this render
			_entityCollector.cleanUp();
			
			// register that a view has been rendered
			stage3DProxy.bufferClear = false;
		}
		
		protected function updateGlobalPos():void
		{
			_globalPosDirty = false;
			
			if (!_stage3DProxy)
				return;
			
			if (_shareContext) {
				_scissorRect.x = _globalPos.x - _stage3DProxy.x;
				_scissorRect.y = _globalPos.y - _stage3DProxy.y;
			} else {
				_scissorRect.x = 0;
				_scissorRect.y = 0;
				_stage3DProxy.x = _globalPos.x;
				_stage3DProxy.y = _globalPos.y;
			}
			
			_scissorRectDirty = true;
		}
		
		protected function updateTime():void
		{
			var time:Number = getTimer();
			if (_time == 0)
				_time = time;
			_deltaTime = time - _time;
			_time = time;
		}
		
		protected function updateViewSizeData():void
		{
			_camera.lens.aspectRatio = _aspectRatio;
			
			if (_scissorRectDirty) {
				_scissorRectDirty = false;
				_camera.lens.updateScissorRect(_scissorRect.x, _scissorRect.y, _scissorRect.width, _scissorRect.height);
			}
			
			if (_viewportDirty) {
				_viewportDirty = false;
				_camera.lens.updateViewport(_stage3DProxy.viewPort.x, _stage3DProxy.viewPort.y, _stage3DProxy.viewPort.width, _stage3DProxy.viewPort.height);
			}
			
			if (_filter3DRenderer || _renderer.renderToTexture) {
				_renderer.textureRatioX = _rttBufferManager.textureRatioX;
				_renderer.textureRatioY = _rttBufferManager.textureRatioY;
			} else {
				_renderer.textureRatioX = 1;
				_renderer.textureRatioY = 1;
			}
		}
		
		protected function renderDepthPrepass(entityCollector:EntityCollector):void
		{
			_depthRenderer.disableColor = true;
			if (_filter3DRenderer || _renderer.renderToTexture) {
				_depthRenderer.textureRatioX = _rttBufferManager.textureRatioX;
				_depthRenderer.textureRatioY = _rttBufferManager.textureRatioY;
				_depthRenderer.render(entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
			} else {
				_depthRenderer.textureRatioX = 1;
				_depthRenderer.textureRatioY = 1;
				_depthRenderer.render(entityCollector);
			}
			_depthRenderer.disableColor = false;
		}
		
		protected function renderSceneDepthToTexture(entityCollector:EntityCollector):void
		{
			if (_depthTextureInvalid || !_depthRender)
				initDepthTexture(_stage3DProxy._context3D);
			_depthRenderer.textureRatioX = _rttBufferManager.textureRatioX;
			_depthRenderer.textureRatioY = _rttBufferManager.textureRatioY;
			_depthRenderer.render(entityCollector, _depthRender);
		}
		
		private function initDepthTexture(context:Context3D):void
		{
			_depthTextureInvalid = false;
			
			if (_depthRender)
				_depthRender.dispose();
			
			_depthRender = context.createTexture(_rttBufferManager.textureWidth, _rttBufferManager.textureHeight, Context3DTextureFormat.BGRA, true);
		}
		
		/**
		 * Disposes all memory occupied by the view. This will also dispose the renderer.
		 */
		public function dispose():void
		{
			_stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
			if (!shareContext)
				_stage3DProxy.dispose();
			_renderer.dispose();
			
			if (_depthRender)
				_depthRender.dispose();
			
			if (_rttBufferManager)
				_rttBufferManager.dispose();
			
			_mouse3DManager.disableMouseListeners(this);
			_mouse3DManager.dispose();
			
			_touch3DManager.disableTouchListeners(this);
			_touch3DManager.dispose();
			
			_rttBufferManager = null;
			_depthRender = null;
			_mouse3DManager = null;
			_touch3DManager = null;
			_depthRenderer = null;
			_stage3DProxy = null;
			_renderer = null;
			_entityCollector = null;
		}
		
		/**
		 * Calculates the projected position in screen space of the given scene position.
		 *
		 * @param point3d the position vector of the point to be projected.
		 * @return The absolute screen position of the given scene coordinates.
		 */
		public function project(point3d:Vector3D):Vector3D
		{
			var v:Vector3D = _camera.project(point3d);
			
			v.x = (v.x + 1.0)*_width/2.0;
			v.y = (v.y + 1.0)*_height/2.0;
			
			return v;
		}
		
		/**
		 * Calculates the scene position of the given screen coordinates.
		 *
		 * eg. unproject(view.mouseX, view.mouseY, 500) returns the scene position of the mouse 500 units into the screen.
		 *
		 * @param sX The absolute x coordinate in 2D relative to View3D, representing the screenX coordinate.
		 * @param sY The absolute y coordinate in 2D relative to View3D, representing the screenY coordinate.
		 * @param sZ The distance into the screen, representing the screenZ coordinate.
		 * @return The scene position of the given screen coordinates.
		 */
		public function unproject(sX:Number, sY:Number, sZ:Number):Vector3D
		{
			return _camera.unproject((sX*2 - _width)/_stage3DProxy.width, (sY*2 - _height)/_stage3DProxy.height, sZ);
		}
		
		/**
		 * Calculates the ray in scene space from the camera to the given screen coordinates.
		 *
		 * eg. getRay(view.mouseX, view.mouseY, 500) returns the ray from the camera to a position under the mouse, 500 units into the screen.
		 *
		 * @param sX The absolute x coordinate in 2D relative to View3D, representing the screenX coordinate.
		 * @param sY The absolute y coordinate in 2D relative to View3D, representing the screenY coordinate.
		 * @param sZ The distance into the screen, representing the screenZ coordinate.
		 * @return The ray from the camera to the scene space position of the given screen coordinates.
		 */
		public function getRay(sX:Number, sY:Number, sZ:Number):Vector3D
		{
			return _camera.getRay((sX*2 - _width)/_width, (sY*2 - _height)/_height, sZ);
		}
		
		public function get mousePicker():IPicker
		{
			return _mouse3DManager.mousePicker;
		}
		
		public function set mousePicker(value:IPicker):void
		{
			_mouse3DManager.mousePicker = value;
		}
		
		public function get touchPicker():IPicker
		{
			return _touch3DManager.touchPicker;
		}
		
		public function set touchPicker(value:IPicker):void
		{
			_touch3DManager.touchPicker = value;
		}
		
		/**
		 * The EntityCollector object that will collect all potentially visible entities in the partition tree.
		 *
		 * @see away3d.core.traverse.EntityCollector
		 * @private
		 */
		arcane function get entityCollector():EntityCollector
		{
			return _entityCollector;
		}
		
		private function onLensChanged(event:CameraEvent):void
		{
			_scissorRectDirty = true;
			_viewportDirty = true;
		}
		
		/**
		 * When added to the stage, retrieve a Stage3D instance
		 */
		private function onAddedToStage(event:Event):void
		{
			if (_addedToStage)
				return;
			
			_addedToStage = true;
			
			if (!_stage3DProxy) {
				_stage3DProxy = Stage3DManager.getInstance(stage).getFreeStage3DProxy(_forceSoftware, _profile);
				_stage3DProxy.addEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
				
			}
			
			_globalPosDirty = true;
			
			_rttBufferManager = RTTBufferManager.getInstance(_stage3DProxy);
			
			_renderer.stage3DProxy = _depthRenderer.stage3DProxy = _stage3DProxy;
			
			//default wiidth/height to stageWidth/stageHeight
			if (_width == 0)
				width = stage.stageWidth;
			else
				_rttBufferManager.viewWidth = _width;
			if (_height == 0)
				height = stage.stageHeight;
			else
				_rttBufferManager.viewHeight = _height;
			
			if (_shareContext)
				_mouse3DManager.addViewLayer(this);
		}
		
		private function onAdded(event:Event):void
		{
			_parentIsStage = (parent == stage);
			
			_globalPos = parent.localToGlobal(_localPos);
			_globalPosDirty = true;
		}
		
		private function onViewportUpdated(event:Stage3DEvent):void
		{
			if (_shareContext) {
				_scissorRect.x = _globalPos.x - _stage3DProxy.x;
				_scissorRect.y = _globalPos.y - _stage3DProxy.y;
				_scissorRectDirty = true;
			}
			
			_viewportDirty = true;
		}
		
		// dead ends:
		override public function set z(value:Number):void
		{
		}
		
		override public function set scaleZ(value:Number):void
		{
		}
		
		override public function set rotation(value:Number):void
		{
		}
		
		override public function set rotationX(value:Number):void
		{
		}
		
		override public function set rotationY(value:Number):void
		{
		}
		
		override public function set rotationZ(value:Number):void
		{
		}
		
		override public function set transform(value:Transform):void
		{
		}
		
		override public function set scaleX(value:Number):void
		{
		}
		
		override public function set scaleY(value:Number):void
		{
		}
	}
}
