package away3d.core.managers
{
	
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.core.pick.IPicker;
	import away3d.core.pick.PickingCollisionVO;
	import away3d.core.pick.PickingType;
	import away3d.events.TouchEvent3D;
	
	import flash.events.TouchEvent;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	public class Touch3DManager
	{
		private var _updateDirty:Boolean = true;
		private var _nullVector:Vector3D = new Vector3D();
		private var _numTouchPoints:uint;
		private var _touchPoint:TouchPoint;
		private var _collidingObject:PickingCollisionVO;
		private var _previousCollidingObject:PickingCollisionVO;
		protected static var _collidingObjectFromTouchId:Dictionary;
		protected static var _previousCollidingObjectFromTouchId:Dictionary;
		private static var _queuedEvents:Vector.<TouchEvent3D> = new Vector.<TouchEvent3D>();
		
		private var _touchPoints:Vector.<TouchPoint>;
		private var _touchPointFromId:Dictionary;
		
		private var _touchMoveEvent:TouchEvent = new TouchEvent(TouchEvent.TOUCH_MOVE);
		
		private var _forceTouchMove:Boolean;
		private var _touchPicker:IPicker = PickingType.RAYCAST_FIRST_ENCOUNTERED;
		private var _view:View3D;
		
		public function Touch3DManager()
		{
			super();
			_touchPoints = new Vector.<TouchPoint>();
			_touchPointFromId = new Dictionary();
			_collidingObjectFromTouchId = new Dictionary();
			_previousCollidingObjectFromTouchId = new Dictionary();
		}
		
		// ---------------------------------------------------------------------
		// Interface.
		// ---------------------------------------------------------------------
		
		public function updateCollider():void
		{
			
			if (_forceTouchMove || _updateDirty) { // If forceTouchMove is off, and no 2D Touch events dirty the update, don't update either.
				for (var i:uint; i < _numTouchPoints; ++i) {
					_touchPoint = _touchPoints[ i ];
					_collidingObject = _touchPicker.getViewCollision(_touchPoint.x, _touchPoint.y, _view);
					_collidingObjectFromTouchId[ _touchPoint.id ] = _collidingObject;
				}
			}
		}
		
		public function fireTouchEvents():void
		{
			
			var i:uint;
			var len:uint;
			var event:TouchEvent3D;
			var dispatcher:ObjectContainer3D;
			
			for (i = 0; i < _numTouchPoints; ++i) {
				_touchPoint = _touchPoints[ i ];
				// If colliding object has changed, queue over/out events.
				_collidingObject = _collidingObjectFromTouchId[ _touchPoint.id ];
				_previousCollidingObject = _previousCollidingObjectFromTouchId[ _touchPoint.id ];
				if (_collidingObject != _previousCollidingObject) {
					if (_previousCollidingObject)
						queueDispatch(TouchEvent3D.TOUCH_OUT, _touchMoveEvent, _previousCollidingObject, _touchPoint);
					if (_collidingObject)
						queueDispatch(TouchEvent3D.TOUCH_OVER, _touchMoveEvent, _collidingObject, _touchPoint);
				}
				// Fire Touch move events here if forceTouchMove is on.
				if (_forceTouchMove && _collidingObject)
					queueDispatch(TouchEvent3D.TOUCH_MOVE, _touchMoveEvent, _collidingObject, _touchPoint);
			}
			
			// Dispatch all queued events.
			len = _queuedEvents.length;
			for (i = 0; i < len; ++i) {
				
				// Only dispatch from first implicitly enabled object ( one that is not a child of a TouchChildren = false hierarchy ).
				event = _queuedEvents[i];
				dispatcher = event.object;
				
				while (dispatcher && !dispatcher._ancestorsAllowMouseEnabled)
					dispatcher = dispatcher.parent;
				
				if (dispatcher)
					dispatcher.dispatchEvent(event);
			}
			_queuedEvents.length = 0;
			
			_updateDirty = false;
			
			for (i = 0; i < _numTouchPoints; ++i) {
				_touchPoint = _touchPoints[ i ];
				_previousCollidingObjectFromTouchId[ _touchPoint.id ] = _collidingObjectFromTouchId[ _touchPoint.id ];
			}
		}
		
		public function enableTouchListeners(view:View3D):void
		{
			view.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
			view.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
			view.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		}
		
		public function disableTouchListeners(view:View3D):void
		{
			view.removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
			view.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
			view.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		}
		
		public function dispose():void
		{
			_touchPicker.dispose();
			_touchPoints = null;
			_touchPointFromId = null;
			_collidingObjectFromTouchId = null;
			_previousCollidingObjectFromTouchId = null;
		}
		
		// ---------------------------------------------------------------------
		// Private.
		// ---------------------------------------------------------------------
		
		private function queueDispatch(emitType:String, sourceEvent:TouchEvent, collider:PickingCollisionVO, touch:TouchPoint):void
		{
			
			var event:TouchEvent3D = new TouchEvent3D(emitType);
			
			// 2D properties.
			event.ctrlKey = sourceEvent.ctrlKey;
			event.altKey = sourceEvent.altKey;
			event.shiftKey = sourceEvent.shiftKey;
			event.screenX = touch.x;
			event.screenY = touch.y;
			event.touchPointID = touch.id;
			
			// 3D properties.
			if (collider) {
				// Object.
				event.object = collider.entity;
				event.renderable = collider.renderable;
				// UV.
				event.uv = collider.uv;
				// Position.
				event.localPosition = collider.localPosition? collider.localPosition.clone() : null;
				// Normal.
				event.localNormal = collider.localNormal? collider.localNormal.clone() : null;
				// Face index.
				event.index = collider.index;
				// SubGeometryIndex.
				event.subGeometryIndex = collider.subGeometryIndex;
				
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
		
		// ---------------------------------------------------------------------
		// Event handlers.
		// ---------------------------------------------------------------------
		
		private function onTouchBegin(event:TouchEvent):void
		{
			
			var touch:TouchPoint = new TouchPoint();
			touch.id = event.touchPointID;
			touch.x = event.stageX;
			touch.y = event.stageY;
			_numTouchPoints++;
			_touchPoints.push(touch);
			_touchPointFromId[ touch.id ] = touch;
			
			updateCollider(); // ensures collision check is done with correct mouse coordinates on mobile
			
			_collidingObject = _collidingObjectFromTouchId[ touch.id ];
			if (_collidingObject)
				queueDispatch(TouchEvent3D.TOUCH_BEGIN, event, _collidingObject, touch);
			
			_updateDirty = true;
		}
		
		private function onTouchMove(event:TouchEvent):void
		{
			
			var touch:TouchPoint = _touchPointFromId[ event.touchPointID ];
			
			if (!touch) return;
			
			touch.x = event.stageX;
			touch.y = event.stageY;
			
			_collidingObject = _collidingObjectFromTouchId[ touch.id ];
			if (_collidingObject)
				queueDispatch(TouchEvent3D.TOUCH_MOVE, _touchMoveEvent = event, _collidingObject, touch);
			
			_updateDirty = true;
		}
		
		private function onTouchEnd(event:TouchEvent):void
		{
			
			var touch:TouchPoint = _touchPointFromId[ event.touchPointID ];
			
			if (!touch) return;
			
			_collidingObject = _collidingObjectFromTouchId[ touch.id ];
			if (_collidingObject)
				queueDispatch(TouchEvent3D.TOUCH_END, event, _collidingObject, touch);
			
			_touchPointFromId[ touch.id ] = null;
			_numTouchPoints--;
			_touchPoints.splice(_touchPoints.indexOf(touch), 1);
			
			_updateDirty = true;
		}
		
		// ---------------------------------------------------------------------
		// Getters & setters.
		// ---------------------------------------------------------------------
		
		public function get forceTouchMove():Boolean
		{
			return _forceTouchMove;
		}
		
		public function set forceTouchMove(value:Boolean):void
		{
			_forceTouchMove = value;
		}
		
		public function get touchPicker():IPicker
		{
			return _touchPicker;
		}
		
		public function set touchPicker(value:IPicker):void
		{
			_touchPicker = value;
		}
		
		public function set view(value:View3D):void
		{
			_view = value;
		}
	}
}

class TouchPoint
{
	public var id:int;
	public var x:Number;
	public var y:Number;
}
