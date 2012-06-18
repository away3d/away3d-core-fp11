package away3d.core.managers
{
	import flash.display.Shape;
	import away3d.arcane;
	import away3d.debug.Debug;
	import away3d.events.Stage3DEvent;
	
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

	use namespace arcane;

	[Event(name="enterFrame", type="flash.events.Event")]
	[Event(name="exitFrame", type="flash.events.Event")]
	
	/**
	 * Stage3DProxy provides a proxy class to manage a single Stage3D instance as well as handling the creation and
	 * attachment of the Context3D (and in turn the back buffer) is uses. Stage3DProxy should never be created directly,
	 * but requested through Stage3DManager.
	 *
	 * @see away3d.core.managers.Stage3DProxy
	 *
	 * todo: consider moving all creation methods (createVertexBuffer etc) in here, so that disposal can occur here
	 * along with the context, instead of scattered throughout the framework
	 */
	public class Stage3DProxy extends EventDispatcher
	{
		private static var _frameEventDriver : Shape = new Shape();
		
		arcane var _context3D : Context3D;
		arcane var _stage3DIndex : int = -1;

		private var _stage3D : Stage3D;
		private var _activeProgram3D : Program3D;
		private var _stage3DManager : Stage3DManager;
		private var _backBufferWidth : int;
		private var _backBufferHeight : int;
		private var _antiAlias : int;
		private var _enableDepthAndStencil : Boolean;
		private var _contextRequested : Boolean;
		private var _activeVertexBuffers : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8, true);
		private var _activeTextures : Vector.<TextureBase> = new Vector.<TextureBase>(8, true);
		private var _renderTarget : TextureBase;
		private var _renderSurfaceSelector : int;
		private var _scissorRect : Rectangle;
		private var _color : uint;
		private var _backBufferDirty : Boolean;
		private var _viewPort : Rectangle;
		private var _layerRenderFunctions : Vector.<Function>;
		private var _stage : Stage;
		private var _enterFrameListenerFunctions : Vector.<Function>;
		private var _exitFrameListenerFunctions : Vector.<Function>;

		/**
		 * Creates a Stage3DProxy object. This method should not be called directly. Creation of Stage3DProxy objects should
		 * be handled by Stage3DManager.
		 * @param stage3DIndex The index of the Stage3D to be proxied.
		 * @param stage3D The Stage3D to be proxied.
		 * @param stage3DManager
		 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
		 */
		public function Stage3DProxy(stage3DIndex : int, stage3D : Stage3D, stage3DManager : Stage3DManager, forceSoftware : Boolean = false)
		{
			_stage3DIndex = stage3DIndex;
			_stage3D = stage3D;
			_stage3D.x = 0;
			_stage3D.y = 0;
			_stage3DManager = stage3DManager;
			_viewPort = new Rectangle();
			_enableDepthAndStencil = true;
			_layerRenderFunctions = new Vector.<Function>();
			_enterFrameListenerFunctions = new Vector.<Function>();
			_exitFrameListenerFunctions = new Vector.<Function>();
			
			// whatever happens, be sure this has highest priority
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate, false, 1000, false);
			requestContext(forceSoftware);
		}

		public function setSimpleVertexBuffer(index : int, buffer : VertexBuffer3D, format : String, offset : int = 0) : void
		{
			// force setting null
			if (buffer && _activeVertexBuffers[index] == buffer) return;

			_context3D.setVertexBufferAt(index, buffer, offset, format);
			_activeVertexBuffers[index] = buffer;
		}

		public function setTextureAt(index : int, texture : TextureBase) : void
		{
			if (texture != null && _activeTextures[index] == texture) return;

			_context3D.setTextureAt(index,  texture);

			_activeTextures[index] = texture;
		}

		public function setProgram(program3D : Program3D) : void
		{
			if (_activeProgram3D == program3D) return;
			_context3D.setProgram(program3D);
			_activeProgram3D = program3D;
		}

		/**
		 * Disposes the Stage3DProxy object, freeing the Context3D attached to the Stage3D.
		 */
		public function dispose() : void
		{
			_stage3DManager.removeStage3DProxy(this);
			_stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate);
			freeContext3D();
			_stage3D = null;
			_stage3DManager = null;
			_stage3DIndex = -1;
		}

		/**
		 * Configures the back buffer associated with the Stage3D object.
		 * @param backBufferWidth The width of the backbuffer.
		 * @param backBufferHeight The height of the backbuffer.
		 * @param antiAlias The amount of anti-aliasing to use.
		 * @param enableDepthAndStencil Indicates whether the back buffer contains a depth and stencil buffer.
		 */
		public function configureBackBuffer(backBufferWidth : int, backBufferHeight : int, antiAlias : int, enableDepthAndStencil : Boolean) : void
		{
			_backBufferWidth = backBufferWidth;
			_backBufferHeight = backBufferHeight;
			_antiAlias = antiAlias;
			_enableDepthAndStencil = enableDepthAndStencil;

			if (_context3D)
				_context3D.configureBackBuffer(backBufferWidth, backBufferHeight, antiAlias, enableDepthAndStencil);
		}

		public function get enableDepthAndStencil() : Boolean
		{
			return _enableDepthAndStencil;
		}

		public function set enableDepthAndStencil(enableDepthAndStencil : Boolean) : void
		{ 
			_enableDepthAndStencil = enableDepthAndStencil; 
			_backBufferDirty = true;
		}
		
		public function get renderTarget() : TextureBase
		{
			return _renderTarget;
		}

		public function get renderSurfaceSelector() : int
		{
			return _renderSurfaceSelector;
		}

		public function setRenderTarget(target : TextureBase, enableDepthAndStencil : Boolean = false, surfaceSelector : int = 0) : void
		{
			if (_renderTarget == target && surfaceSelector == _renderSurfaceSelector && _enableDepthAndStencil == enableDepthAndStencil) return;
			_renderTarget = target;
			_renderSurfaceSelector = surfaceSelector;
			_enableDepthAndStencil = enableDepthAndStencil;

			if (target)
				_context3D.setRenderToTexture(target, enableDepthAndStencil, _antiAlias, surfaceSelector);
			else
				_context3D.setRenderToBackBuffer();
		}
		
		public function clear() : void {
			if (!_context3D) return;
			
			if (_backBufferDirty) {
				configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
				_backBufferDirty = false;
			}
				
			_context3D.clear(
				((_color >> 16) & 0xff) / 255.0, 
                ((_color >> 8) & 0xff) / 255.0, 
                (_color & 0xff) / 255.0,
                ((_color >> 24) & 0xff) / 255.0 );
		}


		public function present() : void {
			if (!_context3D) return;

			_context3D.present();
		}
		
		/**
		 * Add the supplied framework rendering function to the list of layer functions to be rendered
		 * The order in which they are added determines the render order - bottom (first) to top (last)
		 * @param fn The rendering function of the framework
		 */
		public function addLayer(fn : Function) : void 
		{
			_layerRenderFunctions.push(fn);
		}

		/**
		 * Remove the supplied function from the list of layer functions to be rendered
		 * @param fn The rendering function of the framework
		 */
		public function removeLayerScene(fn : Function) : void 
		{
			_layerRenderFunctions.splice(_layerRenderFunctions.indexOf(fn), 1);
		}
		
		/**
		 * Start the automatic rendering of the added layers using the provided stage
		 * object so Enter_Frame events can be attahed
		 * @param stage The stage instance to be used to attach Enter_Frame events too.
		 */
		public function renderLayers(stage : Stage = null) : void {			
			// Remove any previous Enter_Frame listeners
			if (_stage) {
				_stage.removeEventListener(Event.ENTER_FRAME, onRenderLayerEnterFrame);
			}

			// If the stage param is null exit - can be used to cancel rendering
			if (!stage) return;
			
			// Setup the new Enter_Frame listener for rendering the layers
			_stage = stage;
			stage.addEventListener(Event.ENTER_FRAME, onRenderLayerEnterFrame);
		}
		
		public override function addEventListener(type : String, listener :Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void {
			// Only override Enter_Frame events
			if (type != Event.ENTER_FRAME && type != Event.EXIT_FRAME) {
				super.addEventListener(type, listener, useCapture, priority, useWeakReference);
				return;
			}
			
			// Only add if the listener method is not already included
			if (_enterFrameListenerFunctions.indexOf(listener) != -1 || _exitFrameListenerFunctions.indexOf(listener) != -1) return; 
			if (type == Event.ENTER_FRAME) {
				_enterFrameListenerFunctions.push(listener);
			} else {
				_exitFrameListenerFunctions.push(listener);
			}
			_frameEventDriver.addEventListener(Event.ENTER_FRAME, onLayerRenderEnterFrame, useCapture, priority, useWeakReference);
		}

		public override function removeEventListener(type : String, listener :Function, useCapture : Boolean = false) : void {
			// Only override Enter_Frame events
			if (type != Event.ENTER_FRAME && type != Event.EXIT_FRAME) {
				super.addEventListener(type, listener, useCapture); 
				return;
			}
			
			var listenerIndex:int;
			if (type == Event.ENTER_FRAME) {
				listenerIndex = _enterFrameListenerFunctions.indexOf(listener);
				if (listenerIndex == -1) return;
				
				// Remove the listener function from the list of enterFrame functions to execute
				_enterFrameListenerFunctions.splice(listenerIndex, 1);
			} else {
				listenerIndex = _exitFrameListenerFunctions.indexOf(listener);
				if (listenerIndex == -1) return;
				
				// Remove the listener function from the list of exitFrame functions to execute
				_exitFrameListenerFunctions.splice(listenerIndex, 1);
			}
			
			// Remove the main rendering listener if no EnterFrame listeners remain
			if (_enterFrameListenerFunctions.length == 0 && _exitFrameListenerFunctions.length == 0)
				_frameEventDriver.removeEventListener(Event.ENTER_FRAME, onLayerRenderEnterFrame, useCapture);
		}

		public function get scissorRect() : Rectangle
		{
			return _scissorRect;
		}

		public function set scissorRect(value : Rectangle) : void
		{
			_scissorRect = value;
			_context3D.setScissorRectangle(_scissorRect);
		}

		/**
		 * The index of the Stage3D which is managed by this instance of Stage3DProxy.
		 */
		public function get stage3DIndex() : int
		{
			return _stage3DIndex;
		}

		/**
		 * The base Stage3D object associated with this proxy.
		 */
		public function get stage3D() : Stage3D
		{
			return _stage3D;
		}

		/**
		 * The Context3D object associated with the given Stage3D object.
		 */
		public function get context3D() : Context3D
		{
			return _context3D;
		}

		/**
		 * The x position of the Stage3D.
		 */
		public function get x() : Number
		{
			return _stage3D.x;
		}

		public function set x(value : Number) : void
		{
			_stage3D.x = _viewPort.x = value;
		}

		/**
		 * The y position of the Stage3D.
		 */
		public function get y() : Number
		{
			return _stage3D.y;
		}

		public function set y(value : Number) : void
		{
			_stage3D.y = _viewPort.y = value;
		}


		/**
		 * The width of the Stage3D.
		 */
		public function get width() : int
		{ 
			return _backBufferWidth;
		}

		public function set width(width : int) : void
		{ 
			_backBufferWidth = _viewPort.width = width; 
			_backBufferDirty = true;
		}

		/**
		 * The height of the Stage3D.
		 */
		public function get height() : int
		{ 
			return _backBufferHeight;
		}
		
		public function set height(height : int) : void
		{ 
			_backBufferHeight = _viewPort.height = height; 
			_backBufferDirty = true;
		}

		/**
		 * The antiAliasing of the Stage3D.
		 */
		public function get antiAlias() : int
		{ 
			return _antiAlias;
		}
		
		public function set antiAlias(antiAlias : int) : void
		{ 
			_antiAlias = antiAlias; 
			_backBufferDirty = true;
		}

		/**
		 * A viewPort rectangle equivalent of the Stage3D size and position.
		 */
		public function get viewPort() : Rectangle
		{ 
			return _viewPort;
		}

		/**
		 * The background color of the Stage3D.
		 */
		public function get color() : uint
		{ 
			return _color;
		}
		
		public function set color(color : uint) : void
		{ 
			_color = color;
		}

		/**
		 * Frees the Context3D associated with this Stage3DProxy.
		 */
		private function freeContext3D() : void
		{
			if (_context3D) {
				_context3D.dispose();
				dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
			}
			_context3D = null;
		}

		/*
		 * Called whenever the Context3D is retrieved or lost.
		 * @param event The event dispatched.
		*/
		private function onContext3DUpdate(event : Event) : void
		{
			if (_stage3D.context3D) {
				var hadContext : Boolean = (_context3D != null);

				_context3D = _stage3D.context3D;
				_context3D.enableErrorChecking = Debug.active;
				
				// Only configure back buffer if width and height have been set,
				// which they may not have been if View3D.render() has yet to be
				// invoked for the first time.
				if (_backBufferWidth && _backBufferHeight)
					_context3D.configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
				
				// Dispatch the appropriate event depending on whether context was
				// created for the first time or recreated after a device loss.
				dispatchEvent(new Stage3DEvent(hadContext? Stage3DEvent.CONTEXT3D_RECREATED : Stage3DEvent.CONTEXT3D_CREATED));

			} else {
				throw new Error("Rendering context lost!");
			}
		}

		/**
		 * Requests a Context3D object to attach to the managed Stage3D.
		 */
		private function requestContext(forceSoftware : Boolean = false) : void
		{
			_stage3D.requestContext3D(forceSoftware? Context3DRenderMode.SOFTWARE : Context3DRenderMode.AUTO);
			_contextRequested = true;
		}
		
		/**
		 * The Enter_Frame handler for rendering framework layers on the Stage3D instance
		 */
		private function onRenderLayerEnterFrame(event : Event) : void
		{
			if (!_context3D) return; 
			
			// Clear the stage3D instance
			clear();
			
			// Render each layer using the remdering functions added
			for each (var renderFunction:Function in _layerRenderFunctions) {
				renderFunction();
			}
			
			// Call the present() to render the frame
			present();
		}
		
		/**
		 * The Enter_Frame handler for processing the proxy.ENTER_FRAME and proxy.EXIT_FRAME event handlers.
		 * Typically the proxy.ENTER_FRAME listener would render the layers for this Stage3D instance.
		 */
		private function onLayerRenderEnterFrame(event : Event) : void {
			if (!_context3D) return; 
			
			// Clear the stage3D instance
			clear();
			
			var listenerFunction:Function;
			// Render each layer using the rendering listener functions added
			for each (listenerFunction in _enterFrameListenerFunctions) {
				listenerFunction(event);
			}
			
			// Call the present() to render the frame
			present();
			
			// Call each exit function using the exitFrame listener functions added
			for each (listenerFunction in _exitFrameListenerFunctions) {
				listenerFunction(event);
			}
		}
	}
}
