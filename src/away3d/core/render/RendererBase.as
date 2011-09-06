package away3d.core.render
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.managers.Texture3DProxy;
	import away3d.core.sort.EntitySorterBase;
	import away3d.core.sort.RenderableMergeSort;
	import away3d.core.traverse.EntityCollector;
	import away3d.errors.AbstractMethodError;
	import away3d.events.Stage3DEvent;

	import flash.display.BitmapData;

	import flash.display.BitmapData;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.Texture;
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

		protected var _backgroundR : Number = 0;
		protected var _backgroundG : Number = 0;
		protected var _backgroundB : Number = 0;
		protected var _backgroundAlpha : Number = 1;

		protected var _swapBackBuffer : Boolean = true;

		protected var _renderTarget : TextureBase;
		protected var _renderTargetSurface : int;

		private var _renderableSorter : EntitySorterBase;
		private var _backgroundImageRenderer : BackgroundImageRenderer;
		private var _backgroundImage : BitmapData;

		/**
		 * Creates a new RendererBase object.
		 */
		public function RendererBase()
		{
			_renderableSorter = new RenderableMergeSort();
		}

		public function get renderableSorter() : EntitySorterBase
		{
			return _renderableSorter;
		}

		public function set renderableSorter(value : EntitySorterBase) : void
		{
			_renderableSorter = value;
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
				if (_stage3DProxy) _stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
				_stage3DProxy = null;
				_context = null;

//				_contextIndex = -1;
				return;
			}
			else if (_stage3DProxy) throw new Error("A Stage3D instance was already assigned!");

			_stage3DProxy = value;
			if (_backgroundImageRenderer) _backgroundImageRenderer.stage3DProxy = value;

			if (value.context3D)
				_context = value.context3D;
			else
				value.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
		}

		/**
		 * The width of the back buffer.
		 *
		 * @private
		 */
		/*arcane function get backBufferWidth() : int
		{
			return _backBufferWidth;
		}

		arcane function set backBufferWidth(value : int) : void
		{
			_backBufferWidth = value;
			_backBufferInvalid = true;
		}    */

		/**
		 * The height of the back buffer.
		 *
		 * @private
		 */
		/*arcane function get backBufferHeight() : int
		{
			return _backBufferHeight;
		}

		arcane function set backBufferHeight(value : int) : void
		{
			_backBufferHeight = value;
			_backBufferInvalid = true;
		}  */


		/**
		 * Disposes the resources used by the RendererBase.
		 *
		 * @private
		 */
		arcane function dispose() : void
		{
			stage3DProxy = null;
			if (_backgroundImageRenderer) {
				_backgroundImageRenderer.dispose();
				_backgroundImageRenderer = null;
			}
		}

		/**
		 * Renders the potentially visible geometry to the back buffer or texture.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		arcane function render(entityCollector : EntityCollector, target : TextureBase = null, scissorRect : Rectangle = null, surfaceSelector : int = 0, additionalClearMask : int = 7) : void
		{
			if (!_stage3DProxy || !_context) return;

			_renderTarget = target;
			_renderTargetSurface = surfaceSelector;
			executeRender(entityCollector, target, scissorRect, surfaceSelector, additionalClearMask);

			// clear buffers
			for (var i : uint = 0; i < 8; ++i) {
				_stage3DProxy.setSimpleVertexBuffer(i, null);
				_stage3DProxy.setTextureAt(i, null);
			}
		}

		/**
		 * Renders the potentially visible geometry to the back buffer or texture. Only executed if everything is set up.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		protected function executeRender(entityCollector : EntityCollector, target : TextureBase = null, scissorRect : Rectangle = null, surfaceSelector : int = 0, additionalClearMask : int = 7) : void
		{
			if (_renderableSorter) _renderableSorter.sort(entityCollector);

			_stage3DProxy.setRenderTarget(target, true, surfaceSelector);

			_context.clear(_backgroundR, _backgroundG, _backgroundB, _backgroundAlpha, 1, 0, additionalClearMask);
			_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
			_stage3DProxy.scissorRect = scissorRect;
			if (_backgroundImageRenderer) _backgroundImageRenderer.render();

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
		/*protected function updateViewPort() : void
		{
			_stage3DProxy.x = _viewPortX;
			_stage3DProxy.y = _viewPortY;
			_viewPortInvalid = false;
		}   */

		/**
		 * Assign the context once retrieved
		 */
		private function onContextUpdate(event : Event) : void
		{
			_context = _stage3DProxy.context3D;

//			_contextIndex = _stage3DProxy.stage3DIndex;
		}

		arcane function get backgroundAlpha() : Number
		{
			return _backgroundAlpha;
		}

		arcane function set backgroundAlpha(value : Number) : void
		{
			_backgroundAlpha = value;
		}

		arcane function get backgroundImage() : BitmapData
		{
			return _backgroundImage;
		}

		arcane function set backgroundImage(value : BitmapData) : void
		{
			if (_backgroundImageRenderer && !value) {
				_backgroundImageRenderer.dispose();
				_backgroundImageRenderer = null;
			}

			if (!_backgroundImageRenderer && value)
				_backgroundImageRenderer = new BackgroundImageRenderer(_stage3DProxy);

			_backgroundImage = value;
			if (_backgroundImageRenderer) _backgroundImageRenderer.bitmapData = value;
		}
	}
}
