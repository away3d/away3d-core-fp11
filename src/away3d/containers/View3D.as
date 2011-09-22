package away3d.containers
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Mouse3DManager;
	import away3d.core.managers.Stage3DManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.render.DefaultRenderer;
	import away3d.core.render.DepthRenderer;
	import away3d.core.render.Filter3DRenderer;
	import away3d.core.render.RendererBase;
	import away3d.core.traverse.EntityCollector;
	import away3d.lights.LightBase;

	import flash.display.BitmapData;

	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Transform;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	use namespace arcane;

	public class View3D extends Sprite
	{
		private var _width : Number = 0;
		private var _height : Number = 0;
		private var _localPos : Point = new Point();
		private var _globalPos : Point = new Point();
		private var _scene : Scene3D;
		private var _camera : Camera3D;
		private var _entityCollector : EntityCollector;

		private var _aspectRatio : Number;
		private var _time : Number = 0;
		private var _deltaTime : uint;
		private var _backgroundColor : uint = 0x000000;
		private var _backgroundAlpha : Number = 1;

		private var _mouse3DManager : Mouse3DManager;
		private var _stage3DManager : Stage3DManager;

		private var _renderer : RendererBase;
		private var _depthRenderer : DepthRenderer;
		private var _addedToStage:Boolean;

		private var _filter3DRenderer : Filter3DRenderer;
		private var _requireDepthRender : Boolean;
		private var _depthRender : Texture;
		private var _depthTextureWidth : int = -1;
		private var _depthTextureHeight : int = -1;
		private var _depthTextureInvalid : Boolean = true;

		private var _hitField : Sprite;
		private var _parentIsStage : Boolean;

		private var _backgroundImage : BitmapData;
		private var _bgImageFitToViewPort:Boolean = true;
		private var _stage3DProxy : Stage3DProxy;
		private var _backBufferInvalid : Boolean = true;
		private var _antiAlias : uint;

		public function View3D(scene : Scene3D = null, camera : Camera3D = null, renderer : DefaultRenderer = null)
		{
			super();

			_scene = scene || new Scene3D();
			_camera = camera || new Camera3D();
			_renderer = renderer || new DefaultRenderer();
			_mouse3DManager = new Mouse3DManager(this);
			_depthRenderer = new DepthRenderer();
			_entityCollector = new EntityCollector();
			initHitField();
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addEventListener(Event.ADDED, onAdded, false, 0, true);
		}

		public function get stage3DProxy() : Stage3DProxy
		{
			return _stage3DProxy;
		}

		/**
		 * Forces mouse-move related events even when the mouse hasn't moved. This allows mouseOver and mouseOut events
		 * etc to be triggered due to changes in the scene graph.
		 */
		public function get forceMouseMove() : Boolean
		{
			return _mouse3DManager.forceMouseMove;
		}

		public function set forceMouseMove(value : Boolean) : void
		{
			_mouse3DManager.forceMouseMove = value;
		}

		public function get backgroundImage() : BitmapData
		{
			return _backgroundImage;
		}

		public function set backgroundImageFitToViewPort(value:Boolean):void
		{
			_bgImageFitToViewPort = value;

			if(_renderer.backgroundImageRenderer == null)
				return;

			_renderer.backgroundImageRenderer.fitToViewPort = value;
		}

		public function set backgroundImage(value : BitmapData) : void
		{
			_backgroundImage = value;
			_renderer.backgroundImage = _backgroundImage;
			_renderer.backgroundImageRenderer.viewWidth = _width;
			_renderer.backgroundImageRenderer.viewHeight = _height;
			_renderer.backgroundImageRenderer.fitToViewPort = _bgImageFitToViewPort;
		}

		private function initHitField() : void
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
		override public function get filters() : Array
		{
			throw new Error("filters is not supported in View3D. Use filters3d instead.");
			return super.filters;
		}

		/**
		 * Not supported. Use filters3d instead.
		 */
		override public function set filters(value : Array) : void
		{
			throw new Error("filters is not supported in View3D. Use filters3d instead.");
		}


		public function get filters3d() : Array
		{
			return _filter3DRenderer? _filter3DRenderer.filters : null;
		}

		public function set filters3d(value : Array) : void
		{
			if (value && value.length == 0) value = null;

			if (_filter3DRenderer && !value) {
				_filter3DRenderer.dispose();
				_filter3DRenderer = null;
			}
			else if (!_filter3DRenderer && value) {
				_filter3DRenderer = new Filter3DRenderer(_width, _height);
				_filter3DRenderer.filters = value;
			}

			if (_filter3DRenderer) {
				_filter3DRenderer.filters = value;
				_requireDepthRender = _filter3DRenderer.requireDepthRender;
			}
			else {
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
		public function get renderer() : RendererBase
		{
			return _renderer;
		}

		public function set renderer(value : RendererBase) : void
		{
			_renderer.dispose();
			_renderer = value;
			_renderer.stage3DProxy = _stage3DProxy;
			_renderer.backgroundR = ((_backgroundColor >> 16) & 0xff) / 0xff;
			_renderer.backgroundG = ((_backgroundColor >> 8) & 0xff) / 0xff;
			_renderer.backgroundB = (_backgroundColor & 0xff) / 0xff;
			_renderer.backgroundAlpha = _backgroundAlpha;
			_renderer.backgroundImage = _backgroundImage;
			invalidateBackBuffer();
		}

		private function invalidateBackBuffer() : void
		{
			_backBufferInvalid = true;
		}

		/**
		 * The background color of the screen. This value is only used when clearAll is set to true.
		 */
		public function get backgroundColor() : uint
		{
			return _backgroundColor;
		}

		public function set backgroundColor(value : uint) : void
		{
			_backgroundColor = value;
			_renderer.backgroundR = ((value >> 16) & 0xff) / 0xff;
			_renderer.backgroundG = ((value >> 8) & 0xff) / 0xff;
			_renderer.backgroundB = (value & 0xff) / 0xff;
		}

		public function get backgroundAlpha() : Number
		{
			return _backgroundAlpha;
		}

		public function set backgroundAlpha(value : Number) : void
		{
			if (value > 1) value = 1;
			else if (value < 0) value = 0;
			_renderer.backgroundAlpha = value;
			_backgroundAlpha = value;
		}

		/**
		 * The camera that's used to render the scene for this viewport
		 */
		public function get camera() : Camera3D
		{
			return _camera;
		}

		/**
		 * Set camera that's used to render the scene for this viewport
		 */
		public function set camera(camera:Camera3D) : void
		{
			_camera = camera;
		}
		
		/**
		 * The scene that's used to render for this viewport
		 */
		public function get scene() : Scene3D
		{
			return _scene;
		}

		/**
		 * Set the scene that's used to render for this viewport
		 */
		public function set scene(scene:Scene3D) : void
		{
			_scene = scene;
		}

		// todo: probably temporary:
		/**
		 * The amount of milliseconds the last render call took
		 */
		public function get deltaTime() : uint
		{
			return _deltaTime;
		}

		/**
		 * The width of the viewport
		 */
		override public function get width() : Number
		{
			return _width;
		}

		override public function set width(value : Number) : void
		{
			if (_width == value) return;
			_hitField.width = value;
			_width = value;
			_aspectRatio = _width/_height;
			_depthTextureInvalid = true;
			if (_filter3DRenderer) _filter3DRenderer.viewWidth = value;
			if (_renderer.backgroundImageRenderer != null)
			{
				_renderer.backgroundImageRenderer.viewWidth = _width;
				_renderer.backgroundImageRenderer.viewHeight = _height;
			}
			invalidateBackBuffer();
		}

		/**
		 * The height of the viewport
		 */
		override public function get height() : Number
		{
			return _height;
		}

		override public function set height(value : Number) : void
		{
			if (_height == value) return;
			_hitField.height = value;
			_height = value;
			_aspectRatio = _width/_height;
			_depthTextureInvalid = true;
			if (_filter3DRenderer) _filter3DRenderer.viewHeight = value;
			invalidateBackBuffer();
		}


		override public function set x(value : Number) : void
		{
			super.x = value;
			_localPos.x = value;
			_globalPos.x = parent? parent.localToGlobal(_localPos).x : value;
			if (_stage3DProxy)
				_stage3DProxy.x = _globalPos.x;
		}

		override public function set y(value : Number) : void
		{
			super.y = value;
			_localPos.y = value;
			_globalPos.y = parent? parent.localToGlobal(_localPos).y : value;
			if (_stage3DProxy)
				_stage3DProxy.y = _globalPos.y;
		}

		/**
		 * The amount of anti-aliasing to be used.
		 */
		public function get antiAlias() : uint
		{
			return _antiAlias;
		}

		public function set antiAlias(value : uint) : void
		{
			_antiAlias = value;
			invalidateBackBuffer();
		}
		
		/**
		 * The amount of faces that were pushed through the render pipeline on the last frame render.
		 */
		public function get renderedFacesCount() : uint
		{
			return _entityCollector.numTriangles;
		}

		/**
		 * Updates the backbuffer dimensions.
		 */
		private function updateBackBuffer() : void
		{
			_stage3DProxy.configureBackBuffer(_width, _height, _antiAlias, true);
			_backBufferInvalid = false;
		}
		
		/**
		 * Renders the view.
		 */
		public function render() : void
		{
			// reset or update render settings
			if (_backBufferInvalid) updateBackBuffer();
			if (!_parentIsStage) updateGlobalPos();
			updateTime();
			_entityCollector.clear();
			updateCamera();

			// collect stuff to render
			_scene.traversePartitions(_entityCollector);

			// render things
			if (_entityCollector.numMouseEnableds > 0) _mouse3DManager.updateHitData();

			updateLights(_entityCollector);

			if (_requireDepthRender)
				renderSceneDepth(_entityCollector);

			if (_filter3DRenderer && _stage3DProxy._context3D) {
				_renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _filter3DRenderer.renderRect);
				_filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
				_stage3DProxy._context3D.present();
			}
			else
				_renderer.render(_entityCollector);

			// clean up data for this render
			_entityCollector.cleanUp();

			// fire collected mouse events
			_mouse3DManager.fireMouseEvents();
		}

		private function updateGlobalPos() : void
		{
			var globalPos : Point = parent.localToGlobal(_localPos);
			if (_globalPos.x != globalPos.x) _stage3DProxy.x = globalPos.x;
			if (_globalPos.y != globalPos.y) _stage3DProxy.y = globalPos.y;
			_globalPos = globalPos;
		}

		private function updateTime() : void
		{
			var time : Number = getTimer();
			if (_time == 0) _time = time;
			_deltaTime = time - _time;
			_time = time;
		}

		private function updateCamera() : void
		{
			_camera.lens.aspectRatio = _aspectRatio;
			_entityCollector.camera = _camera;

			if (_filter3DRenderer) {
				_camera.textureRatioX = _width/_filter3DRenderer.textureWidth;
				_camera.textureRatioY = _height/_filter3DRenderer.textureHeight;
			}
			else {
				_camera.textureRatioX = 1;
				_camera.textureRatioY = 1;
			}
		}
		
		private function renderSceneDepth(entityCollector : EntityCollector) : void
		{
			if (_depthTextureInvalid || !_depthRender) initDepthTexture(_stage3DProxy._context3D);
			_depthRenderer.render(entityCollector, _depthRender);
		}

		private function initDepthTexture(context : Context3D) : void
		{
			var w : int = getPowerOf2Exceeding(_width);
			var h : int = getPowerOf2Exceeding(_height);

			_depthTextureInvalid = false;

			if (w == _depthTextureWidth && h == _depthTextureHeight) return;

			_depthTextureWidth = w;
			_depthTextureHeight = h;

			if (_depthRender) _depthRender.dispose();

			_depthRender = context.createTexture(w, h, Context3DTextureFormat.BGRA, true);
		}

		private function getPowerOf2Exceeding(value : int) : Number
		{
			var p : int = 1;

			while (p < value && p < 2048)
				p <<= 1;

			if (p > 2048) p = 2048;

			return p;
		}

		private function updateLights(entityCollector : EntityCollector) : void
		{
			var lights : Vector.<LightBase> = entityCollector.lights;
			var len : uint = lights.length;
			var light : LightBase;

			for (var i : int = 0; i < len; ++i) {
				light = lights[i];
				if (light.castsShadows)
					light.shadowMapper.renderDepthMap(_renderer.stage3DProxy, entityCollector, _depthRenderer);
			}
		}

		/**
		 * Disposes all memory occupied by the view. This will also dispose the renderer.
		 */
		public function dispose() : void
		{
			_stage3DProxy.dispose();
			_renderer.dispose();
			_mouse3DManager.dispose();
			if (_depthRenderer) _depthRenderer.dispose();
			_mouse3DManager.dispose();
			if (_depthRender) _depthRender.dispose();
		}

		public function project(point3d : Vector3D) : Point
		{
			var p : Point = _camera.project(point3d);

			p.x = (p.x + 1.0)*_width/2.0;
			p.y = (p.y + 1.0)*_height/2.0;

			return p;
		}

		public function unproject(mX : Number, mY : Number) : Vector3D
		{
			return _camera.unproject((mX * 2 - _width)/_width, (mY * 2 - _height)/_height );
		}

		/**
		 * The EntityCollector object that will collect all potentially visible entities in the partition tree.
		 *
		 * @see away3d.core.traverse.EntityCollector
		 * @private
		 */
		arcane function get entityCollector() : EntityCollector
		{
			return _entityCollector;
		}

		/**
		 * When added to the stage, retrieve a Stage3D instance
		 */
		private function onAddedToStage(event : Event) : void
		{
			if (_addedToStage)
				return;
			
			_addedToStage = true;

			_stage3DManager = Stage3DManager.getInstance(stage);

			if (_width == 0) width = stage.stageWidth;
			if (_height == 0) height = stage.stageHeight;

			_stage3DProxy = _stage3DManager.getFreeStage3DProxy();
			_stage3DProxy.x = _globalPos.x;
			_stage3DProxy.y = _globalPos.y;
			_renderer.stage3DProxy = _depthRenderer.stage3DProxy = _mouse3DManager.stage3DProxy = _stage3DProxy;
		}

		private function onAdded(event : Event) : void
		{
			_parentIsStage = (parent == stage);
			_globalPos = parent.localToGlobal(new Point(x, y));
			if (_stage3DProxy) {
				_stage3DProxy.x = _globalPos.x;
				_stage3DProxy.y = _globalPos.y;
			}
		}

		// dead ends:
		override public function set z(value : Number) : void {}
		override public function set scaleZ(value : Number) : void {}
		override public function set rotation(value : Number) : void {}
		override public function set rotationX(value : Number) : void {}
		override public function set rotationY(value : Number) : void {}
		override public function set rotationZ(value : Number) : void {}
		override public function set transform(value : Transform) : void {}
		override public function set scaleX(value : Number) : void {}
		override public function set scaleY(value : Number) : void {}
	}
}