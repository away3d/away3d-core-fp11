package away3d.core.managers
{

	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.core.base.Object3D;
	import away3d.core.raycast.colliders.picking.MouseRayCollider;
	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.core.traverse.EntityCollector;
	import away3d.entities.Entity;
	import away3d.events.MouseEvent3D;

	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * Mouse3DManager provides a manager class for detecting 3D mouse hits and sending out mouse events.
	 *
	 * todo: first check if within view bounds
	 */
	public class Mouse3DManager
	{
		private var _previousCollidingObject:Entity;
		private var _collidingObject:Entity;
		private var _oldLocalX:Number;
		private var _oldLocalY:Number;
		private var _oldLocalZ:Number;

		private var _mouseIsOccludedByAnotherView:Boolean;
		private var _mouseIsWithinTheView:Boolean;

		private var _view:View3D;
		private var _rayCollider:MouseRayCollider;

//		private var _forceMouseMove:Boolean;
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

		public function Mouse3DManager( view:View3D ) {
			_view = view;
			_rayCollider = new MouseRayCollider( view );
			enableListeners();
		}

		// ---------------------------------------------------------------------
		// Interface.
		// ---------------------------------------------------------------------

		public function update():void {
			if( _mouseIsWithinTheView && !_mouseIsOccludedByAnotherView ) { // Only update when the mouse is in the view.

				// Store previous colliding object.
				_previousCollidingObject = _collidingObject;

				// Evaluate new colliding object.
				var collector:EntityCollector = _view.entityCollector;
				if( collector.numMouseEnableds > 0 ) {
					_rayCollider.updateMouseRay();
					_rayCollider.updateEntities( collector.entities );
					_rayCollider.evaluate();
					_collidingObject = _rayCollider.aCollisionExists ? _rayCollider.firstEntity : null;
				}
				else {
					_collidingObject = null;
				}
			}
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

			/*if( _forceMouseMove && _collidingObject ) {

			 var localX:Number;
			 var localY:Number;
			 var localZ:Number;

			 if( _collidingObject ) {
			 var local:Vector3D = _rayCollider.getCollisionDataForFirstItem().collisionPoint;
			 localX = local.x;
			 localY = local.y;
			 localZ = local.z;
			 }
			 else {
			 localX = localY = localZ = -1;
			 }

			 if( ( localX != _oldLocalX ) || ( localY != _oldLocalY ) || ( localZ != _oldLocalZ ) ) {
			 queueDispatch( _mouseMove, _mouseMoveEvent, _collidingObject );
			 _oldLocalX = localX;
			 _oldLocalY = localY;
			 _oldLocalZ = localZ;
			 }
			 }*/

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

			var local:Vector3D;
			var scene:Vector3D;
			var normal:Vector3D;
			var sceneNormal:Vector3D;
			var collisionData:RayCollisionVO;

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
			if( _rayCollider.aCollisionExists ) {
				collisionData = _rayCollider.getCollisionDataForFirstItem();
				// UV.
				var collisionUV:Point = collisionData.uv;
				if( collisionUV ) {
					event.uv = collisionUV;
				}
				// Position.
				local = collisionData.position;
				event.localX = local.x;
				event.localY = local.y;
				event.localZ = local.z;
				scene = event.object.transform.transformVector( local );
				event.sceneX = scene.x;
				event.sceneY = scene.y;
				event.sceneZ = scene.z;
				// Normal.
				normal = collisionData.normal;
				if( normal ) {
					event.localNormalX = normal.x;
					event.localNormalY = normal.y;
					event.localNormalZ = normal.z;
					sceneNormal = event.object.transform.deltaTransformVector( normal );
					event.sceneNormalX = sceneNormal.x;
					event.sceneNormalY = sceneNormal.y;
					event.sceneNormalZ = sceneNormal.z;
				}
			}
			else {
				event.uv = null;
				event.localX = -1;
				event.localY = -1;
				event.localZ = -1;
				event.sceneX = -1;
				event.sceneY = -1;
				event.sceneZ = -1;
				event.localNormalX = -1;
				event.localNormalY = -1;
				event.localNormalZ = -1;
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
//			if( _forceMouseMove ) return; // If on force mouse move, move events are managed on every update, not here.
			if( _collidingObject ) queueDispatch( _mouseMove, _mouseMoveEvent = event );
		}

		private function onMouseOut( event:MouseEvent ):void {
			_mouseIsOccludedByAnotherView = true;
			if( _collidingObject ) queueDispatch( _mouseOut, event, _collidingObject );
		}

		private function onMouseOver( event:MouseEvent ):void {
			_mouseIsOccludedByAnotherView = false;
			if( _collidingObject ) queueDispatch( _mouseOver, event, _collidingObject );
		}

		private function onClick( event:MouseEvent ):void {
//			if( evaluateIfMouseIsWithinTheView() ) queueDispatch( _mouseClick, event );
		}

		private function onDoubleClick( event:MouseEvent ):void {
//			if( evaluateIfMouseIsWithinTheView() ) queueDispatch( _mouseDoubleClick, event );
		}

		private function onMouseDown( event:MouseEvent ):void {
			queueDispatch( _mouseDown, event );
		}

		private function onMouseUp( event:MouseEvent ):void {
			queueDispatch( _mouseUp, event );
		}

		private function onMouseWheel( event:MouseEvent ):void {
//			if( evaluateIfMouseIsWithinTheView() ) queueDispatch( _mouseWheel, event );
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

		/*public function get forceMouseMove():Boolean {
		 return _forceMouseMove;
		 }

		 public function set forceMouseMove( value:Boolean ):void {
		 _forceMouseMove = value;
		 }*/

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