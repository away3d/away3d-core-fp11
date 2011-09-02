package away3d.core.managers
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.Object3D;
	import away3d.core.render.HitTestRenderer;
	import away3d.core.traverse.EntityCollector;
	import away3d.entities.Entity;
	import away3d.events.MouseEvent3D;

	import flash.events.MouseEvent;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * Mouse3DManager provides a manager class for detecting 3D mouse hits and sending out mouse events.
	 *
	 * todo: first check if within view bounds
	 */
	public class Mouse3DManager
	{
		private var _previousActiveObject : Object3D;
		private var _previousActiveRenderable : IRenderable;
		private var _activeObject : Entity;
		private var _activeRenderable : IRenderable;
		private var _oldLocalX : Number;
		private var _oldLocalY : Number;
		private var _oldLocalZ : Number;

		private var _hitTestRenderer : HitTestRenderer;
		private var _view : View3D;

		private static var _mouseClick : MouseEvent3D = new MouseEvent3D(MouseEvent3D.CLICK);
		private static var _mouseDoubleClick : MouseEvent3D = new MouseEvent3D(MouseEvent3D.DOUBLE_CLICK);
		private static var _mouseMove : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_MOVE);
		private static var _mouseOver : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OVER);
		private static var _mouseOut : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OUT);
		private static var _mouseUp : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_UP);
		private static var _mouseDown : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_DOWN);
		private static var _mouseWheel : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_WHEEL);

		private var _queuedEvents : Vector.<MouseEvent3D> = new Vector.<MouseEvent3D>();
		private var _forceMouseMove : Boolean;
		private var _mouseMoveEvent : MouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);


//		private static var _rollOver : MouseEvent3D = new MouseEvent3D(MouseEvent3D.ROLL_OVER);
//		private static var _rollOut : MouseEvent3D = new MouseEvent3D(MouseEvent3D.ROLL_OUT);

		/**
		 * Creates a Mouse3DManager object.
		 * @param view The View3D object for which the mouse will be detected.
		 * @param hitTestRenderer The hitTestRenderer that will perform hit-test rendering.
		 */
		public function Mouse3DManager(view : View3D)
		{
			_view = view;
			_hitTestRenderer = new HitTestRenderer(view);

			// to do: add invisible container?
			_view.addEventListener(MouseEvent.CLICK, onClick);
			_view.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			_view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);	// mark moves as most important
			_view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_view.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		public function get forceMouseMove() : Boolean
		{
			return _forceMouseMove;
		}

		public function set forceMouseMove(value : Boolean) : void
		{
			_forceMouseMove = value;
		}

		private function onMouseMove(event : MouseEvent) : void
		{
			if (!_forceMouseMove)
				queueDispatch(_mouseMove, event);
		}


		arcane function get stage3DProxy() : Stage3DProxy
		{
			return _hitTestRenderer.stage3DProxy;
		}

		arcane function set stage3DProxy(value : Stage3DProxy) : void
		{
			_hitTestRenderer.stage3DProxy = value;
		}

		/**
		 * Clear all resources and listeners used by this Mouse3DManager.
		 */
		public function dispose() : void
		{
			_hitTestRenderer.dispose();
			_view.removeEventListener(MouseEvent.CLICK, onClick);
			_view.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			_view.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_view.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_view.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_view.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		private function mouseInView() : Boolean
		{
			var mx : Number = _view.mouseX;
			var my : Number = _view.mouseY;

			return mx >= 0 && my >= 0 && mx < _view.width && my < _view.height;
		}

		/**
		 * Called when the mouse clicks on the stage.
		 */
		private function onClick(event : MouseEvent) : void
		{
			if (mouseInView())
				queueDispatch(_mouseClick, event);
		}

		public function updateHitData() : void
		{
			if (mouseInView())
				getObjectHitData();
			else
				_activeRenderable = null;
		}

		/**
		 * Called when the mouse double-clicks on the stage.
		 */
		private function onDoubleClick(event : MouseEvent) : void
		{
			if (mouseInView())
				queueDispatch(_mouseDoubleClick, event);
		}

		/**
		 * Called when a mouseDown event occurs on the stage
		 */
		private function onMouseDown(event : MouseEvent) : void
		{
			if (mouseInView())
				queueDispatch(_mouseDown, event);
		}

		/**
		 * Called when a mouseUp event occurs on the stage
		 */
		private function onMouseUp(event : MouseEvent) : void
		{
			if (mouseInView())
				queueDispatch(_mouseUp, event);
		}

		/**
		 * Called when a mouseWheel event occurs on the stage
		 */
		private function onMouseWheel(event : MouseEvent) : void
		{
			if (mouseInView())
				queueDispatch(_mouseWheel, event);
		}

		/**
		 * Get the object hit information at the mouse position.
		 */
		private function getObjectHitData() : void
		{
			if (!_forceMouseMove && _queuedEvents.length == 0)
				return;

			_previousActiveObject = _activeObject;
			_previousActiveRenderable = _activeRenderable;


			var collector : EntityCollector = _view.entityCollector;

			// todo: would it be faster to run a custom ray-intersect collector instead of using entity collector's data?
			// todo: shouldn't render it every time, only when invalidated (on move or view render)
			if (collector.numMouseEnableds > 0) {
				_hitTestRenderer.update(_view.mouseX / _view.width, _view.mouseY / _view.height, collector);
				_activeRenderable = _hitTestRenderer.hitRenderable;
				_activeObject = (_activeRenderable && _activeRenderable.mouseEnabled) ? _activeRenderable.sourceEntity : null;
			}
			else {
				_activeObject = null;
				_activeRenderable = null;
			}
		}

		/**
		 * Sends out a MouseEvent3D based on the MouseEvent that triggered it on the Stage.
		 * @param event3D The MouseEvent3D that will be dispatched.
		 * @param sourceEvent The MouseEvent that triggered the dispatch.
		 * @param renderable The IRenderable object that is the subject of the MouseEvent3D.
		 */
		private function dispatch(event3D : MouseEvent3D) : void
		{
			var renderable : IRenderable;
			var local : Vector3D = _hitTestRenderer.localHitPosition;

			// assign default renderable if it wasn't provide on queue time
			if (!(renderable = (event3D.renderable ||= _activeRenderable))) return;

			event3D.material = renderable.material;
			event3D.object = renderable.sourceEntity;

			if (renderable.mouseDetails && local) {
				event3D.uv = _hitTestRenderer.hitUV;
				event3D.localX = local.x;
				event3D.localY = local.y;
				event3D.localZ = local.z;
			}
			else {
				event3D.uv = null;
				event3D.localX = -1;
				event3D.localY = -1;
				event3D.localZ = -1;
			}

			// only dispatch from first implicitly enabled object (one that is not a child of a mouseChildren=false hierarchy)
			var dispatcher : ObjectContainer3D = renderable.sourceEntity;

			while (dispatcher && !dispatcher._implicitMouseEnabled) dispatcher = dispatcher.parent;
			dispatcher.dispatchEvent(event3D);
		}

		private function queueDispatch(event : MouseEvent3D, sourceEvent : MouseEvent, renderable : IRenderable = null) : void
		{
			event.ctrlKey = sourceEvent.ctrlKey;
			event.altKey = sourceEvent.altKey;
			event.shiftKey = sourceEvent.shiftKey;
			event.renderable = renderable;
			event.delta = sourceEvent.delta;
			event.screenX = _view.stage.mouseX;
			event.screenY = _view.stage.mouseY;

			_queuedEvents.push(event);
		}

		public function fireMouseEvents() : void
		{
			if (_activeObject != _previousActiveObject) {
				if (_previousActiveRenderable) queueDispatch(_mouseOut, _mouseMoveEvent, _previousActiveRenderable);
				if (_activeRenderable) queueDispatch(_mouseOver, _mouseMoveEvent, _activeRenderable);
			}

			if (_forceMouseMove && _activeRenderable) {
				var localX : Number;
				var localY : Number;
				var localZ : Number;

				if (_activeRenderable.mouseDetails) {
					localX = _hitTestRenderer.localHitPosition.x;
					localY = _hitTestRenderer.localHitPosition.y;
					localZ = _hitTestRenderer.localHitPosition.z;
				}
				else {
					localX = localY = localZ = -1;
				}

				if ((localX != _oldLocalX) || (localY != _oldLocalY) || (localZ != _oldLocalZ)) {
					queueDispatch(_mouseMove, _mouseMoveEvent, _activeRenderable);

					_oldLocalX = localX;
					_oldLocalY = localY;
					_oldLocalZ = localZ;
				}
			}

			var len : uint = _queuedEvents.length;

			for (var i : uint = 0; i < len; ++i)
				dispatch(_queuedEvents[i]);

			_queuedEvents.length = 0;
		}
	}
}