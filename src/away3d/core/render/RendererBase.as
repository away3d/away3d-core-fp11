package away3d.core.render
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.sort.EntitySorterBase;
	import away3d.core.sort.RenderableSorter;
	import away3d.core.traverse.EntityCollector;
	import away3d.errors.AbstractMethodError;

	import flash.display3D.Context3D;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.geom.Rectangle;

	use namespace arcane;

	/**
	 * RendererBase forms an abstract base class for classes that are used in the rendering pipeline to render geometry
	 * to the back buffer or a texture.
	 */
	public class RendererBase
	{
		protected var _context : Context3D;
		protected var _stage3DProxy : Stage3DProxy;
		protected var _contextIndex : int = -1;

		private var _backBufferWidth : int;
		private var _backBufferHeight : int;
		protected var _backBufferInvalid : Boolean;
		private var _antiAlias : uint;
		private var _renderMode : String;

		protected var _backgroundR : Number = 0;
		protected var _backgroundG : Number = 0;
		protected var _backgroundB : Number = 0;

		protected var _viewPortWidth : Number = 1;
		protected var _viewPortHeight : Number = 1;
		protected var _viewPortX : Number = 0;
		protected var _viewPortY : Number = 0;

		private var _viewPortInvalid : Boolean;
		private var _enableDepthAndStencil : Boolean;
		private var _swapBackBuffer : Boolean = true;

		protected var _renderableSorter : EntitySorterBase;

		/**
		 * Creates a new RendererBase object.
		 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
		 * @param antiAlias The amount of anti-aliasing to be used.
		 * @param renderMode The render mode to be used.
		 */
		public function RendererBase(antiAlias : uint = 0, enableDepthAndStencil : Boolean = true, renderMode : String = "auto")
		{
			_antiAlias = antiAlias;
			_renderMode = renderMode;
			_enableDepthAndStencil = enableDepthAndStencil;
			_renderableSorter = new RenderableSorter();
		}

		/**
		 * Indicates whether or not the back buffer should be swapped when rendering is complete.
		 */
		public function get swapBackBuffer() : Boolean
		{
			return _swapBackBuffer;
		}

		public function set swapBackBuffer(value : Boolean) : void
		{
			_swapBackBuffer = value;
		}

		/**
		 * The amount of anti-aliasing to use.
		 */
		public function get antiAlias() : uint
		{
			return _antiAlias;
		}

		public function set antiAlias(value : uint) : void
		{
			_backBufferInvalid = true;
			_antiAlias = value;
		}

		/**
		 * The background color's red component, used when clearing.
		 *
		 * @private
		 */
		arcane function get backgroundR() : Number
		{
			return _backgroundR;
		}

		arcane function set backgroundR(value : Number) : void
		{
			_backgroundR = value;
		}

		/**
		 * The background color's green component, used when clearing.
		 *
		 * @private
		 */
		arcane function get backgroundG() : Number
		{
			return _backgroundG;
		}

		arcane function set backgroundG(value : Number) : void
		{
			_backgroundG = value;
		}

		/**
		 * The background color's blue component, used when clearing.
		 *
		 * @private
		 */
		arcane function get backgroundB() : Number
		{
			return _backgroundB;
		}

		arcane function set backgroundB(value : Number) : void
		{
			_backgroundB = value;
		}

		/**
		 * The Stage3DProxy that will provide the Context3D used for rendering.
		 *
		 * @private
		 */
		arcane function get stage3DProxy() : Stage3DProxy
		{
			return _stage3DProxy;
		}

		arcane function set stage3DProxy(value : Stage3DProxy) : void
		{
			if (value == _stage3DProxy)
				return;
			
			if (!value) {
				if (_stage3DProxy) _stage3DProxy.removeEventListener(Event.CONTEXT3D_CREATE, onContextUpdate);
				_stage3DProxy = null;
				_context = null;
				_contextIndex = -1;
				return;
			}
			else if (_stage3DProxy) throw new Error("A Stage3D instance was already assigned!");

			_stage3DProxy = value;
			updateViewPort();

			if (value.context3D) {
				_context = value.context3D;
				_contextIndex = value.stage3DIndex;
			}
			else
				value.addEventListener(Event.CONTEXT3D_CREATE, onContextUpdate);
		}

		/**
		 * The width of the back buffer.
		 *
		 * @private
		 */
		arcane function get backBufferWidth() : int
		{
			return _backBufferWidth;
		}

		arcane function set backBufferWidth(value : int) : void
		{
			_backBufferWidth = value;
			_backBufferInvalid = true;
		}

		/**
		 * The height of the back buffer.
		 *
		 * @private
		 */
		arcane function get backBufferHeight() : int
		{
			return _backBufferHeight;
		}

		arcane function set backBufferHeight(value : int) : void
		{
			_backBufferHeight = value;
			_backBufferInvalid = true;
		}

		/**
		 * The horizontal coordinate of the top-left corner of the viewport.
		 *
		 * @private
		 */
		arcane function get viewPortX() : Number
		{
			return _viewPortX;
		}

		arcane function set viewPortX(value : Number) : void
		{
			_viewPortX = value;
			_viewPortInvalid = true;
		}

		/**
		 * The vertical coordinate of the top-left corner of the viewport.
		 *
		 * @private
		 */
		arcane function get viewPortY() : Number
		{
			return _viewPortY;
		}

		arcane function set viewPortY(value : Number) : void
		{
			_viewPortY = value;
			_viewPortInvalid = true;
		}

		/**
		 * The width of the viewport.
		 *
		 * @private
		 */
		arcane function get viewPortWidth() : Number
		{
			return _viewPortWidth;
		}

		arcane function set viewPortWidth(value : Number) : void
		{
			_viewPortWidth = value;
			_viewPortInvalid = true;
		}

		/**
		 * The height of the viewport.
		 *
		 * @private
		 */
		arcane function get viewPortHeight() : Number
		{
			return _viewPortHeight;
		}

		arcane function set viewPortHeight(value : Number) : void
		{
			_viewPortHeight = value;
			_viewPortInvalid = true;
		}

		/**
		 * Disposes the resources used by the RendererBase.
		 *
		 * @private
		 */
		arcane function dispose() : void
		{
			stage3DProxy = null;
		}

		/**
		 * Renders the potentially visible geometry to the back buffer or texture.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		arcane function render(entityCollector : EntityCollector, target : TextureBase = null, surfaceSelector : int = 0, additionalClearMask : int = 7) : void
		{
			if (!_stage3DProxy) return;
			if (_viewPortInvalid) updateViewPort();
			if (_backBufferInvalid) updateBackBuffer();
			if (!_context) return;

			executeRender(entityCollector, target, surfaceSelector, additionalClearMask);
		}

		/**
		 * Renders the potentially visible geometry to the back buffer or texture. Only executed if everything is set up.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		protected function executeRender(entityCollector : EntityCollector, target : TextureBase = null, surfaceSelector : int = 0, additionalClearMask : int = 7) : void
		{
			_renderableSorter.sort(entityCollector);

			if (target) _context.setRenderToTexture(target, _enableDepthAndStencil, _antiAlias, surfaceSelector);
			else _context.setRenderToBackBuffer();

			_context.clear(_backgroundR, _backgroundG, _backgroundB, 1, 1, 0, additionalClearMask);

			draw(entityCollector);

			if (_swapBackBuffer && !target) _context.present();
		}

		/**
		 * Performs the actual drawing of geometry to the target.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 */
		protected function draw(entityCollector : EntityCollector) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Updates the viewport dimensions;
		 */
		protected function updateViewPort() : void
		{
			_stage3DProxy.viewPort = new Rectangle(_viewPortX, _viewPortY, _viewPortWidth, _viewPortHeight);
			_viewPortInvalid = false;
		}

		/**
		 * Updates the backbuffer dimensions.
		 */
		private function updateBackBuffer() : void
		{
			_stage3DProxy.configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
			_backBufferInvalid = false;
		}

		/**
		 * Assign the context once retrieved
		 */
		private function onContextUpdate(event : Event) : void
		{
			_context = _stage3DProxy.context3D;
			_contextIndex = _stage3DProxy.stage3DIndex;
		}

	}
}