package away3d.core.managers
{
	import away3d.arcane;
	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.Object3D;
	import away3d.core.render.HitTestRenderer;
	import away3d.core.traverse.EntityCollector;
	import away3d.entities.Entity;
	import away3d.events.MouseEvent3D;
	
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
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
		private var _lastmove_mouseX:Number;
		private var _lastmove_mouseY:Number;

		private var _stage : Stage;
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
		private static var _rollOver : MouseEvent3D = new MouseEvent3D(MouseEvent3D.ROLL_OVER);
		private static var _rollOut : MouseEvent3D = new MouseEvent3D(MouseEvent3D.ROLL_OUT);

		/**
		 * Creates a Mouse3DManager object.
		 * @param view The View3D object for which the mouse will be detected.
		 * @param hitTestRenderer The hitTestRenderer that will perform hit-test rendering.
		 */
		public function Mouse3DManager(view : View3D, hitTestRenderer : HitTestRenderer)
		{
			_view = view;
			_stage = view.stage;
			_hitTestRenderer = hitTestRenderer;

			// to do: add invisible container?
			_stage.addEventListener(MouseEvent.CLICK, onClick);
			_stage.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			_stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			//_stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 1);	// mark moves as most important
			_stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		/**
		 * Clear all resources and listeners used by this Mouse3DManager.
		 */
		public function dispose() : void
		{
			_stage.removeEventListener(MouseEvent.CLICK, onClick);
			_stage.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			_stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
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
			if (!mouseInView()) return;
			// todo: implement invalidation and only rerender if view is invalid?
			getObjectHitData();
			if (_activeRenderable) dispatch(_mouseClick, event, _activeRenderable);
		}

		/**
		 * Called when the mouse double-clicks on the stage.
		 */
		private function onDoubleClick(event : MouseEvent) : void
		{
			if (!mouseInView()) return;
			getObjectHitData();
			if (_activeRenderable) dispatch(_mouseDoubleClick, event, _activeRenderable);
		}

		/**
		 * Called when a mouseDown event occurs on the stage
		 */
		private function onMouseDown(event : MouseEvent) : void
		{
			if (!mouseInView()) return;
			getObjectHitData();
			if (_activeRenderable) dispatch(_mouseDown, event, _activeRenderable);
		}

		/**
		 * Called when a mouseUp event occurs on the stage
		 */
		private function onMouseUp(event : MouseEvent) : void
		{
			if (!mouseInView()) return;
			getObjectHitData();
			dispatch(_mouseUp, event, _activeRenderable);
		}

		/**
		 * Called when a mouseWheel event occurs on the stage
		 */
		private function onMouseWheel(event : MouseEvent) : void
		{
			if (!mouseInView()) return;
			getObjectHitData();
			if (_activeRenderable) dispatch(_mouseWheel, event, _activeRenderable);
		}

		/**
		 * Get the object hit information at the mouse position.
		 */
		private function getObjectHitData() : void
		{
			var collector : EntityCollector = _view.entityCollector;

			_previousActiveObject = _activeObject;
			_previousActiveRenderable = _activeRenderable;

			// todo: would it be faster to run a custom ray-intersect collector instead of using entity collector's data?
			// todo: shouldn't render it every time, only when invalidated (on move or view render)
			if (collector.numMouseEnableds > 0) {
				_hitTestRenderer.update((_view.mouseX-_view.x)/_view.width, (_view.mouseY-_view.y)/_view.height, collector);
				_activeRenderable = _hitTestRenderer.hitRenderable;
				_activeObject = (_activeRenderable && _activeRenderable.mouseEnabled)? _activeRenderable.sourceEntity : null;
			}
			else {
				_activeObject = null;
			}
		}

		/**
		 * Sends out a MouseEvent3D based on the MouseEvent that triggered it on the Stage.
		 * @param event3D The MouseEvent3D that will be dispatched.
		 * @param sourceEvent The MouseEvent that triggered the dispatch.
		 * @param renderable The IRenderable object that is the subject of the MouseEvent3D.
		 */
		private function dispatch(event3D : MouseEvent3D, sourceEvent : MouseEvent, renderable : IRenderable) : void
		{
			if (!renderable) return;

			var local : Vector3D = _hitTestRenderer.localHitPosition;

			event3D.ctrlKey = sourceEvent.ctrlKey;
			event3D.altKey = sourceEvent.altKey;
			event3D.shiftKey = sourceEvent.shiftKey;
			event3D.material = renderable.material;
			event3D.object = renderable.sourceEntity;
			event3D.renderable = renderable;
			event3D.delta = sourceEvent.delta;
			event3D.screenX = _view.stage.mouseX;
			event3D.screenY = _view.stage.mouseY;

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

			renderable.sourceEntity.dispatchEvent(event3D);
		}
		
		/**
		 * Manually fires a mouseMove3D event.
		 */
		public function fireMouseMoveEvent(force:Boolean = false):void
		{
			if (!mouseInView()) return;
			
			getObjectHitData();
			
			var _mouseMoveEvent:MouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);
			var _mouseX:Number = _mouseMoveEvent.localX = _view.mouseX;
			var _mouseY:Number = _mouseMoveEvent.localY = _view.mouseY;
			
			if (!(_view.mouseZeroMove || force))
				if ((_mouseX == _lastmove_mouseX) && (_mouseY == _lastmove_mouseY))
					return;
			
			if (_activeObject == _previousActiveObject) {
				if (_activeRenderable) dispatch(_mouseMove, _mouseMoveEvent, _activeRenderable);
			} else {
				if (_previousActiveRenderable) dispatch(_mouseOut, _mouseMoveEvent, _previousActiveRenderable);
				if (_activeRenderable) dispatch(_mouseOver, _mouseMoveEvent, _activeRenderable);
			}
			
			_lastmove_mouseX = _mouseX;
			_lastmove_mouseY = _mouseY;
		}
	}
}