package away3d.core.render
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.sort.EntitySorterBase;
	import away3d.core.sort.RenderableMergeSort;
	import away3d.core.traverse.EntityCollector;
	import away3d.errors.AbstractMethodError;
	import away3d.events.Stage3DEvent;
	import away3d.textures.Texture2DBase;

	import flash.display.BitmapData;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
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
		protected var _shareContext : Boolean = false;

		protected var _swapBackBuffer : Boolean = true;

		protected var _renderTarget : TextureBase;
		protected var _renderTargetSurface : int;

		// only used by renderers that need to render geometry to textures
		protected var _viewWidth : Number;
		protected var _viewHeight : Number;

		private var _renderableSorter : EntitySorterBase;
		private var _backgroundImageRenderer : BackgroundImageRenderer;
		private var _background : Texture2DBase;
		
		protected var _renderToTexture : Boolean;
		protected var _antiAlias : uint;
		protected var _textureRatioX : Number = 1;
		protected var _textureRatioY : Number = 1;

        private var _snapshotBitmapData:BitmapData;
        private var _snapshotRequired:Boolean;

		private var _clearOnRender : Boolean = true;

		/**
		 * Creates a new RendererBase object.
		 */
		public function RendererBase(renderToTexture : Boolean = false)
		{
			_renderableSorter = new RenderableMergeSort();
			_renderToTexture = renderToTexture;
		}

		arcane function createEntityCollector() : EntityCollector
		{
			return new EntityCollector();
		}

		arcane function get viewWidth() : Number
		{
			return _viewWidth;
		}

		arcane function set viewWidth(value : Number) : void
		{
			_viewWidth = value;
		}

		arcane function get viewHeight() : Number
		{
			return _viewHeight;
		}

		arcane function set viewHeight(value : Number) : void
		{
			_viewHeight = value;
		}

		arcane function get renderToTexture() : Boolean
		{
			return _renderToTexture;
		}

		public function get renderableSorter() : EntitySorterBase
		{
			return _renderableSorter;
		}

		public function set renderableSorter(value : EntitySorterBase) : void
		{
			_renderableSorter = value;
		}

		arcane function get clearOnRender() : Boolean
		{
			return _clearOnRender;
		}

		arcane function set clearOnRender(value : Boolean) : void
		{
			_clearOnRender = value;
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
			//else if (_stage3DProxy) throw new Error("A Stage3D instance was already assigned!");

			_stage3DProxy = value;
			if (_backgroundImageRenderer) _backgroundImageRenderer.stage3DProxy = value;

			if (value.context3D)
				_context = value.context3D;
			else
				value.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
		}

		/**
		 * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
		 * to share the same Context3D object.
		 * 
		 * @private
		 */
		arcane function get shareContext() : Boolean
		{
			return _shareContext;
		}

		arcane function set shareContext(value : Boolean) : void
		{
			_shareContext = value;
		}

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
		arcane function render(entityCollector : EntityCollector, target : TextureBase = null, scissorRect : Rectangle = null, surfaceSelector : int = 0) : void
		{
			if (!_stage3DProxy || !_context) return;

			executeRender(entityCollector, target, scissorRect, surfaceSelector);

			// clear buffers
			for (var i : uint = 0; i < 8; ++i) {
				_stage3DProxy.setSimpleVertexBuffer(i, null, null, 0);
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
		protected function executeRender(entityCollector : EntityCollector, target : TextureBase = null, scissorRect : Rectangle = null, surfaceSelector : int = 0) : void
		{
			_renderTarget = target;
			_renderTargetSurface = surfaceSelector;
			
			if (_renderableSorter)
				_renderableSorter.sort(entityCollector);

			if (_renderToTexture)
				executeRenderToTexturePass(entityCollector);

			_stage3DProxy.setRenderTarget(target, true, surfaceSelector);

			if (!_shareContext && _clearOnRender) {
				_context.clear(_backgroundR, _backgroundG, _backgroundB, _backgroundAlpha, 1, 0);
			}
			_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
			_stage3DProxy.scissorRect = scissorRect;
			if (_backgroundImageRenderer) _backgroundImageRenderer.render();

			draw(entityCollector, target);

			_context.setDepthTest(false, Context3DCompareMode.LESS);

			if ( !_shareContext ) {
				if( _snapshotRequired && _snapshotBitmapData ) {
					_context.drawToBitmapData( _snapshotBitmapData );
					_snapshotRequired = false;
				}
	
				if (_swapBackBuffer && !target) _context.present();
			}
			_stage3DProxy.scissorRect = null;
		}

        /*
        * Will draw the renderer's output on next render to the provided bitmap data.
        * */
        public function queueSnapshot( bmd:BitmapData ):void {
            _snapshotRequired = true;
            _snapshotBitmapData = bmd;
        }

		protected function executeRenderToTexturePass(entityCollector : EntityCollector) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Performs the actual drawing of geometry to the target.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 */
		protected function draw(entityCollector : EntityCollector, target : TextureBase) : void
		{
			throw new AbstractMethodError();
		}

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

		arcane function get background() : Texture2DBase
		{
			return _background;
		}

		arcane function set background(value : Texture2DBase) : void
		{
			if (_backgroundImageRenderer && !value) {
				_backgroundImageRenderer.dispose();
				_backgroundImageRenderer = null;
			}

			if (!_backgroundImageRenderer && value)
				_backgroundImageRenderer = new BackgroundImageRenderer(_stage3DProxy);

			_background = value;

			if (_backgroundImageRenderer) _backgroundImageRenderer.texture = value;
		}

		public function get backgroundImageRenderer():BackgroundImageRenderer
		{
			return _backgroundImageRenderer;
		}

		public function get antiAlias() : uint
		{
			return _antiAlias;
		}

		public function set antiAlias(antiAlias : uint) : void
		{
			_antiAlias = antiAlias;
		}

		arcane function get textureRatioX() : Number
		{
			return _textureRatioX;
		}

		arcane function set textureRatioX(value : Number) : void
		{
			_textureRatioX = value;
		}

		arcane function get textureRatioY() : Number
		{
			return _textureRatioY;
		}

		arcane function set textureRatioY(value : Number) : void
		{
			_textureRatioY = value;
		}
	}
}
