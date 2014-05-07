package away3d.containers
{
	import away3d.Away3D;
	import away3d.arcane;
	import away3d.core.managers.Mouse3DManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.managers.Touch3DManager;
	import away3d.core.pick.IPicker;
	import away3d.core.pick.PickingCollisionVO;
	import away3d.core.pick.PickingCollisionVO;
	import away3d.core.render.IRenderer;
	import away3d.core.traverse.ICollector;
	import away3d.entities.Camera3D;
	import away3d.events.CameraEvent;
	import away3d.events.RendererEvent;
	import away3d.events.Scene3DEvent;
	import away3d.textures.Texture2DBase;

	import flash.display.Sprite;
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
		protected var _entityCollector:ICollector;
		
		protected var _aspectRatio:Number;
		private var _time:Number = 0;
		private var _deltaTime:uint;

		private var _backgroundColor:uint = 0x000000;
		private var _backgroundAlpha:Number = 1;
		
		protected var _mouse3DManager:Mouse3DManager;
		protected var _touch3DManager:Touch3DManager;
		
		protected var _renderer:IRenderer;

		private var _addedToStage:Boolean;

		private var _hitField:Sprite;
		protected var _parentIsStage:Boolean;
		
		private var _background:Texture2DBase;
		private var _antiAlias:uint;
		
		private var _rightClickMenuEnabled:Boolean = true;
		private var _sourceURL:String;
		private var _menu0:ContextMenuItem;
		private var _menu1:ContextMenuItem;
		private var _ViewContextMenu:ContextMenu;
		protected var _shareContext:Boolean = false;
		private var _scissorDirty:Boolean = true;
		private var _viewportDirty:Boolean = true;
		
		private var _layeredView:Boolean = false;
		public var forceMouseMove:Boolean;

		private function viewSource(e:ContextMenuEvent):void
		{
			var request:URLRequest = new URLRequest(_sourceURL);
			try {
				navigateToURL(request, "_blank");
			} catch (error:Error) {
				
			}
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
		
		public function View3D(renderer:IRenderer, scene:Scene3D = null, camera:Camera3D = null)
		{
			super();
			this.scene = scene || new Scene3D();
			this.camera = camera || new Camera3D();
			this.renderer = renderer;

			initHitField();
			
			_mouse3DManager = new Mouse3DManager();
			_mouse3DManager.enableMouseListeners(this);
			
			_touch3DManager = new Touch3DManager();
			_touch3DManager.view = this;
			_touch3DManager.enableTouchListeners(this);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addEventListener(Event.ADDED, onAdded, false, 0, true);
			
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
		 * The renderer used to draw the scene.
		 */
		public function get renderer():IRenderer
		{
			return _renderer;
		}
		
		public function set renderer(value:IRenderer):void
		{
			if(_renderer == value) return;

			if(_renderer) {
				_renderer.dispose();
				_renderer.removeEventListener(RendererEvent.VIEWPORT_UPDATED, onViewportUpdated);
				_renderer.removeEventListener(RendererEvent.SCISSOR_UPDATED, onScissorUpdated);
			}

			_renderer = value;

			_renderer.addEventListener(RendererEvent.VIEWPORT_UPDATED, onViewportUpdated);
			_renderer.addEventListener(RendererEvent.SCISSOR_UPDATED, onScissorUpdated);

			_entityCollector = _renderer.createEntityCollector();
			if(_camera) {
				_entityCollector.camera = _camera;
			}

			_renderer.antiAlias = _antiAlias;
			_renderer.backgroundR = ((_backgroundColor >> 16) & 0xff)/0xff;
			_renderer.backgroundG = ((_backgroundColor >> 8) & 0xff)/0xff;
			_renderer.backgroundB = (_backgroundColor & 0xff)/0xff;
			_renderer.backgroundAlpha = _backgroundAlpha;
			_renderer.width = _width;
			_renderer.height = _height;
			_renderer.shareContext = _shareContext;
		}

		private function onScissorUpdated(event:RendererEvent):void {
			_scissorDirty = true;
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
			if(_camera == camera) return;

			if(_camera) _camera.removeEventListener(CameraEvent.PROJECTION_CHANGED, onProjectionChanged);
			
			_camera = camera;

			if(_entityCollector) {
				_entityCollector.camera = _camera;
			}

			if (_scene)
				_camera.partition = _scene.partition;
			
			_camera.addEventListener(CameraEvent.PROJECTION_CHANGED, onProjectionChanged);
			
			_scissorDirty = true;
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
			if(_scene) _scene.removeEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
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
			if (_renderer && _renderer.stage3DProxy && _renderer.stage3DProxy.usesSoftwareRendering && value > 2048)
				value = 2048;
			
			if (_width == value)
				return;
			
			_hitField.width = value;
			_width = value;
			_aspectRatio = _width/_height;
			_camera.projection.aspectRatio = _aspectRatio;
			_renderer.width = value;
			_scissorDirty = true;
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
			if (_renderer && _renderer.stage3DProxy && _renderer.stage3DProxy.usesSoftwareRendering && value > 2048)
				value = 2048;
			
			if (_height == value)
				return;
			
			_hitField.height = value;
			_height = value;
			_aspectRatio = _width/_height;
			_camera.projection.aspectRatio = _aspectRatio;
			_renderer.height = value;
			_scissorDirty = true;
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
			
			if (stage3DProxy && !_shareContext)
				stage3DProxy.visible = value;
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
		}
		
		/**
		 * The amount of faces that were pushed through the render pipeline on the last frame render.
		 */
		public function get renderedFacesCount():uint
		{
			return 0; //TODO
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
			updateTime();
			_camera.projection.aspectRatio = _aspectRatio;

			if(_scissorDirty) {
				_scissorDirty = false;
				_camera.projection.updateScissorRect(_renderer.scissorRect.x, _renderer.scissorRect.y, _renderer.scissorRect.width, _renderer.scissorRect.height);
			}

			if (_viewportDirty) {
				_viewportDirty = false;
				_camera.projection.updateViewport(_renderer.viewPort.x, _renderer.viewPort.y, _renderer.viewPort.width, _renderer.viewPort.height);
			}

			if(!_shareContext) {
				if(forceMouseMove && _mouse3DManager.activeView == this && !_mouse3DManager.updateDirty) {
					_mouse3DManager.collidingObject = mousePicker.getViewCollision(mouseX, mouseY, this);
				}

				_mouse3DManager.fireMouseEvents(forceMouseMove);
				// update picking
//				_mouse3DManager.updateCollider(this);
//				_touch3DManager.updateCollider();
			}

			_entityCollector.clear();
			// collect stuff to render
			_scene.traversePartitions(_entityCollector);


			_renderer.render(_entityCollector);
//
//			if (!_shareContext) {
//				// fire collected mouse events
//				_mouse3DManager.fireMouseEvents();
//				_touch3DManager.fireTouchEvents();
//			}
		}

		protected function updateTime():void
		{
			var time:Number = getTimer();
			if (_time == 0)
				_time = time;
			_deltaTime = time - _time;
			_time = time;
		}

		/**
		 * Disposes all memory occupied by the view. This will also dispose the renderer.
		 */
		public function dispose():void
		{
			_renderer.dispose();
			
			_mouse3DManager.disableMouseListeners(this);
			_mouse3DManager.dispose();
			
			_touch3DManager.disableTouchListeners(this);
			_touch3DManager.dispose();

			_mouse3DManager = null;
			_touch3DManager = null;
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
		 * @param v the destination Vector3D object
		 * @return The scene position of the given screen coordinates.
		 */
		public function unproject(sX:Number, sY:Number, sZ:Number, v:Vector3D = null):Vector3D
		{
			return _camera.unproject((sX*2 - _width)/_renderer.viewPort.width, (sY*2 - _height)/_renderer.viewPort.height, sZ, v);
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

		private function onProjectionChanged(event:CameraEvent):void
		{
			_scissorDirty = true;
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

			_renderer.init(stage);

			if (_shareContext)
				_mouse3DManager.addViewLayer(this);
		}
		
		private function onAdded(event:Event):void
		{
			_parentIsStage = (parent == stage);
			
			_globalPos = parent.localToGlobal(_localPos);
			_globalPosDirty = true;
		}
		
		private function onViewportUpdated(event:RendererEvent):void
		{
			_viewportDirty = true;
		}

		public function get stage3DProxy():Stage3DProxy {
			return _renderer ? _renderer.stage3DProxy : null;
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

		public function get entityCollector():ICollector {
			return _entityCollector;
		}

		public function set entityCollector(value:ICollector):void {
			_entityCollector = value;
		}

		// ---------------------------------------------------------------------
		// Interface.
		// ---------------------------------------------------------------------

		public function updateCollider():void
		{
			if (!_shareContext) {
				if (this == _mouse3DManager.activeView && (forceMouseMove || _mouse3DManager.updateDirty)) { // If forceMouseMove is off, and no 2D mouse events dirtied the update, don't update either.
					_mouse3DManager.collidingObject = mousePicker.getViewCollision(mouseX, mouseY, this);
				}
			} else {
				var collidingObject:PickingCollisionVO = mousePicker.getViewCollision(mouseX, mouseY, this);
				if(_layeredView || !_mouse3DManager.collidingObject || collidingObject.rayEntryDistance<_mouse3DManager.collidingObject.rayEntryDistance) {
					_mouse3DManager.collidingObject = collidingObject;
				}
			}
		}
	}
}
