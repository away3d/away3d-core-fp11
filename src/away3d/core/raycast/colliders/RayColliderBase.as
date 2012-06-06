package away3d.core.raycast.colliders
{

	import away3d.core.data.ListItem;
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	public class RayColliderBase
	{
		protected var _rayPosition:Vector3D;
		protected var _rayDirection:Vector3D;

		protected var _currentListItem:ListItem;
		protected var _collisionExists:Boolean;

		protected var _numberOfCollisions:uint;

		protected var _collisionData:Dictionary;
		protected var _collidingListItemHead:ListItem;
		protected var _lastCollidingListItem:ListItem;

		public function RayColliderBase() {
		}

		public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayPosition = position;
			_rayDirection = direction;
		}

		public function updateCurrentListItem( currentListItem:ListItem ):void {
			_currentListItem = currentListItem;
		}

		public function evaluate():void {
			throw new AbstractMethodError();
		}

		public function get aCollisionExists():Boolean {
			return _collisionExists;
		}

		public function get collisionData():Dictionary {
			if( !_collisionExists ) return null;
			return _collisionData;
		}

		public function get collidingListItemHead():ListItem {
			if( !_collisionExists ) return null;
			return _collidingListItemHead;
		}

		public function get numberOfCollisions():uint {
			return _numberOfCollisions;
		}
	}
}
