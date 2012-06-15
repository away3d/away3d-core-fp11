package away3d.core.managers.mouse
{

	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.core.base.Object3D;
	import away3d.entities.Entity;
	import away3d.errors.AbstractMethodError;
	import away3d.events.MouseEvent3D;

	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * Mouse3DManager provides a manager class for detecting 3D mouse hits and sending out mouse events.
	 */
	public class Mouse3DManager
	{
		private var _previousCollidingObject:Entity;

		private var _updateDirty:Boolean;

		private var _nullVector:Vector3D;

		private var _mouseIsOccludedByAnotherView:Boolean;
		private var _mouseIsWithinTheView:Boolean;

		protected var _view:View3D;

		protected var _collidingObject:Entity;
		protected var _collisionPosition:Vector3D;
		protected var _collisionNormal:Vector3D;
		protected var _collisionUV:Point;

		private var _forceMouseMove:Boolean;
		private var _queuedEvents:Vector.<MouseEvent3D> = new Vector.<MouseEvent3D>();
		private var _mouseMoveEvent:MouseEvent = new MouseEvent( MouseEvent.MOUSE_MOVE );

		private static var _mouseUp:MouseEvent3D = new MouseEvent3D( MouseEvent3D.MOUSE_UP );
		private static var _mouseClick:MouseEvent3D = new MouseEvent3D( MouseEvent3D.CLICK );
		private static var _mouseOut:MouseEvent3D = new MouseEvent3D( MouseEvent3D.MOUSE_OUT );
		private static var _mouseDown:MouseEvent3D = new MouseEvent3D( MouseEvent3D.MOUSE_DOWN );
		private static var _mouseMove:MouseEvent3D = new MouseEvent3D( MouseEvent3D.MOUSE_MOVE );
		private static var _mouseOver:MouseEvent3D = new MouseEvent3D( MouseEvent3D.MOUSE_OVER );
		private static var _mouseWheel:MouseEvent3D = new MouseEvent3D( MouseEvent3D.MOUSE_WHEEL );
		private static var _mouseDoubleClick:MouseEvent3D = new MouseEvent3D( MouseEvent3D.DOUBLE_CLICK );

		public function Mouse3DManager() {
		}

		// ---------------------------------------------------------------------
		// Interface.
		// ---------------------------------------------------------------------

		public function update():void {

			// Only update when the mouse is in the view.
			if( !( _mouseIsWithinTheView && !_mouseIsOccludedByAnotherView ) )
				return;

			// If forceMouseMove is off, and no 2D mouse events dirtied the update, don't update either.
			if( !_forceMouseMove && !_updateDirty )
				return;

			// Store previous colliding object.
			_previousCollidingObject = _collidingObject;

			updatePicker();

			// Set null to all collision props if there is no collision.
			if( !_collidingObject ) {
				_collisionPosition = null;
				_collisionNormal = null;
				_collisionUV = null;
			}

			_updateDirty = false;
		}

		protected function updatePicker():void {
			throw new AbstractMethodError();
		}

		public function fireMouseEvents():void {

			var i:uint;
			var len:uint;
			var event:MouseEvent3D;
			var dispatcher:Object3D;

			// If colliding object has changed, queue over/out events.
			if( _collidingObject != _previousCollidingObject ) {
				if( _previousCollidingObject ) queueDispatch( _mouseOut, _mouseMoveEvent, _previousCollidingObject );
				if( _collidingObject ) queueDispatch( _mouseOver, _mouseMoveEvent, _collidingObject );
			}

			// Fire mouse move events here if forceMouseMove is on.
			if( _forceMouseMove && _collidingObject ) {
				queueDispatch( _mouseMove, _mouseMoveEvent, _collidingObject );
			}

			// Dispatch all queued events.
			len = _queuedEvents.length;
			for( i = 0; i < len; ++i ) {
				// Only dispatch from first implicitly enabled object ( one that is not a child of a mouseChildren = false hierarchy ).
				event = _queuedEvents[ i ];
				dispatcher = event.object;
				while( dispatcher && dispatcher is ObjectContainer3D && !ObjectContainer3D( dispatcher )._implicitMouseEnabled ) dispatcher = ObjectContainer3D( dispatcher ).parent;
				if( dispatcher ) {
					dispatcher.dispatchEvent( event );
				}
			}
			_queuedEvents.length = 0;
		}

		// ---------------------------------------------------------------------
		// Private.
		// ---------------------------------------------------------------------

		private function queueDispatch( event:MouseEvent3D, sourceEvent:MouseEvent, object:Entity = null ):void {

			var scenePosition:Vector3D;
			var sceneNormal:Vector3D;

			// 2D properties.
			event.ctrlKey = sourceEvent.ctrlKey;
			event.altKey = sourceEvent.altKey;
			event.shiftKey = sourceEvent.shiftKey;
			event.delta = sourceEvent.delta;
			event.screenX = _view.stage.mouseX;
			event.screenY = _view.stage.mouseY;

			// 3D properties.
			// TODO set all 3d event properties
			event.object = object ? object : _collidingObject;
			if( _collidingObject ) {
				// UV.
				if( _collisionUV ) {
					event.uv = _collisionUV;
				}
				// Position.
				event.localPosition = _collisionPosition;
				scenePosition = event.object.transform.transformVector( _collisionPosition );
				event.scenePosition = scenePosition;
				// Normal.
				if( _collisionNormal ) {
					event.localNormal = _collisionNormal;
					sceneNormal = event.object.transform.deltaTransformVector( _collisionNormal );
					event.sceneNormal = sceneNormal;
				}
			}
			else {
				event.uv = null;
				event.localPosition = _nullVector;
				event.scenePosition = _nullVector;
				event.localNormal = _nullVector;
			}

			// Store event to be dispatched later.
			_queuedEvents.push( event );
		}

		public function dispose():void {
			disableListeners();
		}

		// ---------------------------------------------------------------------
		// Listeners.
		// ---------------------------------------------------------------------

		private function onMouseMove( event:MouseEvent ):void {
			evaluateIfMouseIsWithinTheView();
//			if( !_mouseIsWithinTheView ) return; // Ignore mouse moves outside the view.
			if( _forceMouseMove ) return; // If on force mouse move, move events are managed on every update, not here.
			if( _collidingObject ) queueDispatch( _mouseMove, _mouseMoveEvent = event );
			_updateDirty = true;
		}

		private function onMouseOut( event:MouseEvent ):void {
			_mouseIsOccludedByAnotherView = true;
			if( _collidingObject ) queueDispatch( _mouseOut, event, _collidingObject );
			_updateDirty = true;
		}

		private function onMouseOver( event:MouseEvent ):void {
			_mouseIsOccludedByAnotherView = false;
			if( _collidingObject ) queueDispatch( _mouseOver, event, _collidingObject );
			_updateDirty = true;
		}

		private function onClick( event:MouseEvent ):void {
			if( _collidingObject ) queueDispatch( _mouseClick, event );
			_updateDirty = true;
		}

		private function onDoubleClick( event:MouseEvent ):void {
			if( _collidingObject ) queueDispatch( _mouseDoubleClick, event );
			_updateDirty = true;
		}

		private function onMouseDown( event:MouseEvent ):void {
			if( _collidingObject ) queueDispatch( _mouseDown, event );
			_updateDirty = true;
		}

		private function onMouseUp( event:MouseEvent ):void {
			if( _collidingObject ) queueDispatch( _mouseUp, event );
			_updateDirty = true;
		}

		private function onMouseWheel( event:MouseEvent ):void {
			if( _collidingObject ) queueDispatch( _mouseWheel, event );
			_updateDirty = true;
		}

		private function enableListeners():void {
			_view.addEventListener( MouseEvent.CLICK, onClick );
			_view.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
			_view.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			_view.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			_view.addEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			_view.addEventListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
			_view.addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
			_view.addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
		}

		private function disableListeners():void {
			_view.removeEventListener( MouseEvent.CLICK, onClick );
			_view.removeEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
			_view.removeEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			_view.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			_view.removeEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			_view.removeEventListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
			_view.removeEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
			_view.removeEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
		}

		// ---------------------------------------------------------------------
		// Getters & setters.
		// ---------------------------------------------------------------------

		public function get forceMouseMove():Boolean {
			return _forceMouseMove;
		}

		public function set forceMouseMove( value:Boolean ):void {
			_forceMouseMove = value;
		}

		public function set view( value:View3D ):void {
			_view = value;
			_nullVector = new Vector3D();
			enableListeners();
		}

		// ---------------------------------------------------------------------
		// Utils.
		// ---------------------------------------------------------------------

		private function evaluateIfMouseIsWithinTheView():void {
			var mx:Number = _view.mouseX;
			var my:Number = _view.mouseY;
			_mouseIsWithinTheView = mx >= 0 && my >= 0 && mx < _view.width && my < _view.height;
		}
	}
}