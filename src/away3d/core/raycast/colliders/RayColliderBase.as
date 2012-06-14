package away3d.core.raycast.colliders
{

	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Entity;
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	// TODO: Use linked lists instead of vectors.

	public class RayColliderBase
	{
		protected var _rayPosition:Vector3D;
		protected var _rayDirection:Vector3D;

		protected var _aCollisionExists:Boolean;
		protected var _numberOfCollisions:uint;

		protected var _collisionData:Dictionary;
		protected var _entities:Vector.<Entity>;

		public function RayColliderBase() {
		}

		public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayPosition = position;
			_rayDirection = direction;
		}

		public function updateEntities( entities:Vector.<Entity> ):void {
			_entities = entities;
		}

		public function evaluate():void {
			throw new AbstractMethodError();
		}

		public function get aCollisionExists():Boolean {
			return _aCollisionExists;
		}

		public function getCollisionDataForFirstItem():RayCollisionVO {
			return _collisionData[ _entities[ 0 ] ];
		}

		public function getCollisionDataForItem( entity:Entity ):RayCollisionVO {
			return _collisionData[ entity ];
		}

		public function setCollisionDataForItem( entity:Entity, data:RayCollisionVO ):void {
			if( !_collisionData ) {
				_collisionData = new Dictionary();
			}
			_collisionData[ entity ] = data;
		}

		public function get numberOfCollisions():uint {
			return _numberOfCollisions;
		}

		protected function reset():void {
			_aCollisionExists = false;
			_numberOfCollisions = 0;
			_collisionData = null;
		}

		public function get firstEntity():Entity {
			return _entities[ 0 ];
		}

		public function get collisionData():Dictionary {
			return _collisionData;
		}

		public function get entities():Vector.<Entity> {
			return _entities;
		}

		public function setEntityAt( index:uint, entity:Entity ):void {
			if( !_entities ) {
				_entities = new Vector.<Entity>();
			}
			_entities[ index ] = entity;
		}

		public function get rayPosition():Vector3D {
			return _rayPosition;
		}

		public function get rayDirection():Vector3D {
			return _rayDirection;
		}
	}
}
