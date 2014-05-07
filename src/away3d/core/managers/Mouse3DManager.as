package away3d.core.managers
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.core.base.Object3D;
	import away3d.core.pick.IPicker;
	import away3d.core.pick.PickingCollisionVO;
	import away3d.core.pick.PickingType;
	import away3d.events.MouseEvent3D;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	/**
	 * Mouse3DManager enforces a singleton pattern and is not intended to be instanced.
	 * it provides a manager class for detecting 3D mouse hits on View3D objects and sending out 3D mouse events.
	 */
	public class Mouse3DManager
	{
		private static var _view3Ds:Dictionary;
		private static var _view3DLookup:Vector.<View3D>;
		private static var _viewCount:int = 0;
		
		private var _activeView:View3D;
		arcane var updateDirty:Boolean;
		arcane var collidingObject:PickingCollisionVO;

		private var _nullVector:Vector3D = new Vector3D();
//		protected static var _collidingObject:PickingCollisionVO;
		private static var _previousCollidingObject:PickingCollisionVO;
		private static var _collidingViewObjects:Vector.<PickingCollisionVO>;
		private static var _queuedEvents:Vector.<MouseEvent3D> = new Vector.<MouseEvent3D>();
		
		private var _mouseMoveEvent:MouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);
		
		private static var _mouseUp:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_UP);
		private static var _mouseClick:MouseEvent3D = new MouseEvent3D(MouseEvent3D.CLICK);
		private static var _mouseOut:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OUT);
		private static var _mouseDown:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_DOWN);
		private static var _mouseMove:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_MOVE);
		private static var _mouseOver:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OVER);
		private static var _mouseWheel:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_WHEEL);
		private static var _mouseDoubleClick:MouseEvent3D = new MouseEvent3D(MouseEvent3D.DOUBLE_CLICK);
		private var _mousePicker:IPicker = PickingType.RAYCAST_FIRST_ENCOUNTERED;
		private var _childDepth:int = 0;
		private static var _previousCollidingView:int = -1;
		private static var _collidingView:int = -1;
		private var _collidingDownObject:PickingCollisionVO;
		private var _collidingUpObject:PickingCollisionVO;
		
		/**
		 * Creates a new <code>Mouse3DManager</code> object.
		 */
		public function Mouse3DManager()
		{
			if (!_view3Ds) {
				_view3Ds = new Dictionary();
				_view3DLookup = new Vector.<View3D>();
			}
		}

		public function fireMouseEvents(forceMouseMove:Boolean):void
		{
			var i:uint;
			var len:uint;
			var event:MouseEvent3D;
			var dispatcher:Object3D;
			
			// If multiple view are used, determine the best hit based on the depth intersection.
			if (_collidingViewObjects) {
				collidingObject = null;
				// Get the top-most view colliding object
				var distance:Number = Infinity;
				var view:View3D;
				for (var v:int = _viewCount - 1; v >= 0; v--) {
					view = _view3DLookup[v];
					if (_collidingViewObjects[v] && (view.layeredView || _collidingViewObjects[v].rayEntryDistance < distance)) {
						distance = _collidingViewObjects[v].rayEntryDistance;
						collidingObject = _collidingViewObjects[v];
						if (view.layeredView)
							break;
					}
				}
			}
			
			// If colliding object has changed, queue over/out events.
			if (collidingObject != _previousCollidingObject) {
				if (_previousCollidingObject)
					queueDispatch(_mouseOut, _mouseMoveEvent, _previousCollidingObject);
				if (collidingObject)
					queueDispatch(_mouseOver, _mouseMoveEvent, collidingObject);
			}
			
			// Fire mouse move events here if forceMouseMove is on.
			if (forceMouseMove && collidingObject)
				queueDispatch(_mouseMove, _mouseMoveEvent, collidingObject);
			
			// Dispatch all queued events.
			len = _queuedEvents.length;
			for (i = 0; i < len; ++i) {
				// Only dispatch from first implicitly enabled object ( one that is not a child of a mouseChildren = false hierarchy ).
				event = _queuedEvents[i];
				dispatcher = event.object;
				
				while (dispatcher && !dispatcher.isMouseEnabled)
					dispatcher = dispatcher.parent;
				
				if (dispatcher)
					dispatcher.dispatchEvent(event);
			}
			_queuedEvents.length = 0;
			
			_previousCollidingObject = collidingObject;
			updateDirty = false;
		}
		
		public function addViewLayer(view:View3D):void
		{
			var stg:Stage = view.stage;

			if (!hasKey(view))
				_view3Ds[view] = 0;
			
			_childDepth = 0;
			traverseDisplayObjects(stg);
			_viewCount = _childDepth;
		}
		
		public function enableMouseListeners(view:View3D):void
		{
			view.addEventListener(MouseEvent.CLICK, onClick);
			view.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			view.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			view.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			view.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}
		
		public function disableMouseListeners(view:View3D):void
		{
			view.removeEventListener(MouseEvent.CLICK, onClick);
			view.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			view.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			view.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			view.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			view.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			view.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}
		
		public function dispose():void
		{
			_mousePicker.dispose();
		}
		
		// ---------------------------------------------------------------------
		// Private.
		// ---------------------------------------------------------------------
		
		private function queueDispatch(event:MouseEvent3D, sourceEvent:MouseEvent, collider:PickingCollisionVO = null):void
		{
			// 2D properties.
			event.ctrlKey = sourceEvent.ctrlKey;
			event.altKey = sourceEvent.altKey;
			event.shiftKey = sourceEvent.shiftKey;
			event.delta = sourceEvent.delta;
			event.screenX = sourceEvent.localX;
			event.screenY = sourceEvent.localY;
			
			collider ||= collidingObject;
			
			// 3D properties.
			if (collider) {
				// Object.
				event.object = collider.object;
				event.materialOwner = collider.materialOwner;
				// UV.
				event.uv = collider.uv;
				// Position.
				event.localPosition = collider.localPosition? collider.localPosition.clone() : null;
				// Normal.
				event.localNormal = collider.localNormal? collider.localNormal.clone() : null;
				// Face index.
				event.index = collider.index;
			} else {
				// Set all to null.
				event.uv = null;
				event.object = null;
				event.localPosition = _nullVector;
				event.localNormal = _nullVector;
				event.index = 0;
				event.subGeometryIndex = 0;
			}
			
			// Store event to be dispatched later.
			_queuedEvents.push(event);
		}
		
		private function reThrowEvent(event:MouseEvent):void
		{
			if (!_activeView || (_activeView && !_activeView.shareContext))
				return;
			
			for (var v:* in _view3Ds) {
				if (v != _activeView && _view3Ds[v] < _view3Ds[_activeView])
					v.dispatchEvent(event);
			}
		}
		
		private function hasKey(view:View3D):Boolean
		{
			for (var v:* in _view3Ds) {
				if (v === view)
					return true;
			}
			return false;
		}
		
		private function traverseDisplayObjects(container:DisplayObjectContainer):void
		{
			var childCount:int = container.numChildren;
			var c:int = 0;
			var child:DisplayObject;
			for (c = 0; c < childCount; c++) {
				child = container.getChildAt(c);
				for (var v:* in _view3Ds) {
					if (child == v) {
						_view3Ds[child] = _childDepth;
						_view3DLookup[_childDepth] = v;
						_childDepth++;
					}
				}
				if (child is DisplayObjectContainer)
					traverseDisplayObjects(child as DisplayObjectContainer);
			}
		}
		
		// ---------------------------------------------------------------------
		// Listeners.
		// ---------------------------------------------------------------------
		
		private function onMouseMove(event:MouseEvent):void
		{
			if (collidingObject)
				queueDispatch(_mouseMove, _mouseMoveEvent = event);
			else
				reThrowEvent(event);
			updateDirty = true;
		}
		
		private function onMouseOut(event:MouseEvent):void
		{
			_activeView = null;
			if (collidingObject)
				queueDispatch(_mouseOut, event, collidingObject);
			updateDirty = true;
		}
		
		private function onMouseOver(event:MouseEvent):void
		{
			_activeView = (event.currentTarget as View3D);
			if (collidingObject && _previousCollidingObject != collidingObject)
				queueDispatch(_mouseOver, event, collidingObject);
			else
				reThrowEvent(event);
			updateDirty = true;
		}
		
		private function onClick(event:MouseEvent):void
		{
			if (collidingObject) {
				queueDispatch(_mouseClick, event);
			} else
				reThrowEvent(event);
			updateDirty = true;
		}
		
		private function onDoubleClick(event:MouseEvent):void
		{
			if (collidingObject)
				queueDispatch(_mouseDoubleClick, event);
			else
				reThrowEvent(event);
			updateDirty = true;
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			_activeView = (event.currentTarget as View3D);
			_activeView.updateCollider(); // ensures collision check is done with correct mouse coordinates on mobile
			if (collidingObject) {
				queueDispatch(_mouseDown, event);
				_previousCollidingObject = collidingObject;
			} else
				reThrowEvent(event);
			updateDirty = true;
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			if (collidingObject) {
				queueDispatch(_mouseUp, event);
				_previousCollidingObject = collidingObject;
			} else
				reThrowEvent(event);
			updateDirty = true;
		}
		
		private function onMouseWheel(event:MouseEvent):void
		{
			if (collidingObject)
				queueDispatch(_mouseWheel, event);
			else
				reThrowEvent(event);
			updateDirty = true;
		}
		

		public function get mousePicker():IPicker
		{
			return _mousePicker;
		}
		
		public function set mousePicker(value:IPicker):void
		{
			_mousePicker = value;
		}

		public function get activeView():View3D {
			return _activeView;
		}
	}
}
