package away3d.core.managers {
	import flash.display.Stage3D;
	import flash.events.EventDispatcher;
	import away3d.events.Stage3DEvent;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.display3D.Context3D;
	/**
	 * @author Greg
	 */
	public class LayerManager extends EventDispatcher {
		private var _managerInstance : Stage3DManager;
		private var _stage3DProxy : Stage3DProxy;
		private var _context3D : Context3D;
		private var _stage : Stage;
		private var _renderList : Vector.<Function>;
		private var _color : uint = 0;
		private var _stage3D : Stage3D;
		private var _width : int;
		private var _height : int;
		private var _antiAliasing : int;
		
		public function get stage3DProxy() : Stage3DProxy { return _stage3DProxy; }
		public function set stage3DProxy(stage3DProxy : Stage3DProxy) : void { _stage3DProxy = stage3DProxy; }

		public function get context3D() : Context3D { return _context3D; }
		public function set context3D(context3D : Context3D) : void { _context3D = context3D; }

		public function get stage3D() : Stage3D { return _stage3D; }

		public function get color() : uint{ return _color; }
		public function set color(color : uint) : void{ _color=color; }

		public function get width() : int { return _width; }
		public function set width(width : int) : void { _width = width; updateBackBuffer(); }

		public function get height() : int { return _height; }
		public function set height(height : int) : void { _height = height; updateBackBuffer(); }

		public function get antiAliasing() : int { return _antiAliasing; }
		public function set antiAliasing(antiAliasing : int) : void { _antiAliasing = antiAliasing; updateBackBuffer(); }

		public function LayerManager(stage:Stage, stage3DProxy:Stage3DProxy = null) {
			_stage = stage;
			_renderList = new Vector.<Function>();
			_width = _stage.stageWidth;
			_height = _stage.stageHeight;
			_antiAliasing = 1;
			
			_managerInstance = Stage3DManager.getInstance(stage);
			
			_stage3DProxy = stage3DProxy ||= _managerInstance.getFreeStage3DProxy();
			_stage3D = _stage.stage3Ds[_stage3DProxy.stage3DIndex];
			
			if (_stage3DProxy.context3D == null) 
				_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DActive);
		}

		private function onContext3DActive(event : Stage3DEvent) : void {
			_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DActive);
			
			_context3D = _stage3DProxy.context3D;
			updateBackBuffer();
			
			dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_CREATED));
		}
		
		private function updateBackBuffer() : void {
			if (_context3D) {
				_context3D.configureBackBuffer(_width, _height, _antiAliasing, true);
			}
		}

		public function render(renderList:Vector.<Function>) : void {
			_renderList = renderList;	
			updateBackBuffer();
			
			_stage.addEventListener(Event.ENTER_FRAME, renderLayers);			
		}

		private function renderLayers(event : Event) : void {
			if (_context3D == null) return;
			
			// Process user scene updates
			dispatchEvent(new Event(Event.ENTER_FRAME));
			
			_context3D.clear(
				((_color >> 16) & 0xff) / 255.0, 
                ((color >> 8) & 0xff) / 255.0, 
                (color & 0xff) / 255.0,
                ((color >> 24) & 0xff) / 255.0 );

			for each (var renderFunc:Function in _renderList) {
				renderFunc();
			}

			_context3D.present();
		}
	}
}
