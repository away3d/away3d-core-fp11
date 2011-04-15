package away3d.containers
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Mouse3DManager;
	import away3d.core.managers.Stage3DManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.render.DefaultRenderer;
	import away3d.core.render.HitTestRenderer;
	import away3d.core.render.RendererBase;
	import away3d.core.traverse.EntityCollector;
	import away3d.filters.Filter3DBase;
	import away3d.filters.Filter3DBase;
	import away3d.filters.Filter3DBase;
	import away3d.materials.MaterialBase;
	
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	use namespace arcane;

	public class View3D extends Sprite
	{
		private var _width : Number = 0;
		private var _height : Number = 0;
		private var _scaleX : Number = 1;
		private var _scaleY : Number = 1;
		private var _x : Number = 0;
		private var _y : Number = 0;
		private var _scene : Scene3D;
		private var _camera : Camera3D;
		private var _entityCollector : EntityCollector;

		private var _aspectRatio : Number;
		private var _time : Number = 0;
		private var _deltaTime : uint;
		private var _backgroundColor : uint = 0x000000;

		private var _hitManager : Mouse3DManager;
		private var _stage3DManager : Stage3DManager;

		private var _renderer : RendererBase;
		private var _hitTestRenderer : HitTestRenderer;
		public var _addedToStage:Boolean;

		private var _filters3d : Array;
		
		public function View3D(scene : Scene3D = null, camera : Camera3D = null, renderer : DefaultRenderer = null)
		{
			super();

			_scene = scene || new Scene3D();
			_camera = camera || new Camera3D();
			_renderer = renderer || new DefaultRenderer(0);
			_hitTestRenderer = new HitTestRenderer();
			_entityCollector = new EntityCollector();

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0, true);
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
			return _filters3d;
		}

		public function set filters3d(value : Array) : void
		{
			_filters3d = value;
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
			var stage3DProxy : Stage3DProxy = _renderer.stage3DProxy;
			_renderer.dispose();
			_renderer = value;
			_renderer.stage3DProxy = stage3DProxy;
			_renderer.viewPortX = _x;
			_renderer.viewPortY = _y;
			_renderer.backBufferWidth = _width;
			_renderer.backBufferHeight = _height;
			_renderer.viewPortWidth = _width*_scaleX;
			_renderer.viewPortHeight = _height*_scaleY;
			_renderer.backgroundR = ((_backgroundColor >> 16) & 0xff) / 0xff;
			_renderer.backgroundG = ((_backgroundColor >> 8) & 0xff) / 0xff;
			_renderer.backgroundB = (_backgroundColor & 0xff) / 0xff;
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
			_hitTestRenderer.viewPortWidth = value;
			_renderer.viewPortWidth = value*_scaleX;
			_renderer.backBufferWidth = value;
			_width = value;
			_aspectRatio = _width/_height;
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
			_hitTestRenderer.viewPortHeight = value;
			_renderer.viewPortHeight = value*_scaleY;
			_renderer.backBufferHeight = value;
			_height = value;
			_aspectRatio = _width/_height;
		}

		override public function get scaleX() : Number
		{
			return _scaleX;
		}

		override public function set scaleX(value : Number) : void
		{
			_scaleX = value;
			_renderer.viewPortWidth = _width*_scaleX;
		}

		override public function get scaleY() : Number
		{
			return _scaleY;
		}

		override public function set scaleY(value : Number) : void
		{
			_scaleY = value;
			_renderer.viewPortHeight = _height*_scaleY;
		}

		/**
		 * The horizontal coordinate of the top-left position of the viewport.
		 */
		override public function get x() : Number
		{
			return _x;
		}

		override public function set x(value : Number) : void
		{
			_hitTestRenderer.viewPortX = value;
			_renderer.viewPortX = value;
			_x = value;
		}

		/**
		 * The vertical coordinate of the top-left position of the viewport.
		 */
		override public function get y() : Number
		{
			return _y;
		}

		override public function set y(value : Number) : void
		{
			_hitTestRenderer.viewPortY = value;
			_renderer.viewPortY = value;
			_y = value;
		}

		/**
		 * The amount of anti-aliasing to be used.
		 */
		public function get antiAlias() : uint
		{
			return _renderer.antiAlias;
		}

		public function set antiAlias(value : uint) : void
		{
			_renderer.antiAlias = value;
		}

		/**
		 * The amount of faces that were pushed through the render pipeline on the last frame render.
		 */
		public function get renderedFacesCount() : uint
		{
			return _entityCollector.numTriangles;
		}

		/**
		 * Renders the view.
		 */
		public function render() : void
		{
			var time : Number = getTimer();
			var targetTexture : Texture;
			var numFilters : uint = _filters3d? _filters3d.length : 0;
			var context : Context3D = _renderer.context;

			if (_time == 0) _time = time;
			_deltaTime = time - _time;
			_time = time;

//			if (update) AnimationManager.getInstance().updateAnimations(_deltaTime);
			_entityCollector.clear();

			_camera.lens.aspectRatio = _aspectRatio;
			_entityCollector.camera = _camera;
			_scene.traversePartitions(_entityCollector);

			if (numFilters > 0 && context) {
				var nextFilter : Filter3DBase;
				var filter : Filter3DBase = Filter3DBase(_filters3d[0]);
				targetTexture = filter.getInputTexture(context, this);
				_renderer.render(_entityCollector, targetTexture);

				for (var i : uint = 1; i <= numFilters; ++i) {
					nextFilter = i < numFilters? Filter3DBase(_filters3d[i]) : null;
					filter.render(context, nextFilter? nextFilter.getInputTexture(context, this) : null);
					filter = nextFilter;
				}
				context.present();
			}
			else
				_renderer.render(_entityCollector);

			_entityCollector.cleanUp();
		}

		/**
		 * Disposes all memory occupied by the view. This will also dispose the renderer.
		 */
		public function dispose() : void
		{
			_renderer.dispose();
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

			// TO DO: have a stage3D manager?
			if (_width == 0) width = stage.stageWidth;
			if (_height == 0) height = stage.stageHeight;

			_hitTestRenderer.stage3DProxy = _stage3DManager.getStage3DProxy(0);
			_renderer.stage3DProxy = _stage3DManager.getFreeStage3DProxy();

			_hitManager = new Mouse3DManager(this, _hitTestRenderer);
		}

		/**
		 * When removed from the stage, detach from the Stage3D and dispose renderers.
		 */
		private function onRemovedFromStage(event : Event) : void
		{
			if (!_addedToStage)
				return;
			
			_addedToStage = false;
			
			_renderer.stage3DProxy.dispose();
			_hitTestRenderer.dispose();
			_hitManager.dispose();
		}
	}
}