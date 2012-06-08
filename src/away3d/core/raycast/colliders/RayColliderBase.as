package away3d.core.raycast.colliders
{

	import away3d.core.data.LinkedListItem;
	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	public class RayColliderBase
	{
		protected var _rayPosition:Vector3D;
		protected var _rayDirection:Vector3D;

		protected var _collisionExists:Boolean;
		protected var _numberOfCollisions:uint;

		protected var _collisionData:Dictionary;
		protected var _linkedListHeadItem:LinkedListItem;

		public function RayColliderBase() {
		}

		public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayPosition = position;
			_rayDirection = direction;
		}

		public function updateLinkedListHead( currentListItem:LinkedListItem ):void {
			_linkedListHeadItem = currentListItem;
		}

		public function evaluate():void {
			throw new AbstractMethodError();
		}

		public function get aCollisionExists():Boolean {
			return _collisionExists;
		}

		public function getCollisionDataForFirstItem():RayCollisionVO {
			return _collisionData[ _linkedListHeadItem ];
		}

		public function getCollisionDataForItem( item:LinkedListItem ):RayCollisionVO {
			return _collisionData[ item ];
		}

		public function get numberOfCollisions():uint {
			return _numberOfCollisions;
		}

		protected function reset():void {
			_collisionExists = false;
			_numberOfCollisions = 0;
		}

		public function get linkedListHeadItem():LinkedListItem {
			return _linkedListHeadItem;
		}

		public function get collisionData():Dictionary {
			return _collisionData;
		}
	}
}
