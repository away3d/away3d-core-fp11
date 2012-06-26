package away3d.core.raycast.colliders
{

	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Entity;
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;

	public class RayColliderBase
	{
		protected var _entity:Entity;
		protected var _collides:Boolean;
		protected var _rayPosition:Vector3D;
		protected var _rayDirection:Vector3D;
		protected var _collisionData:RayCollisionVO;

		public function RayColliderBase() {
		}

		public function evaluate():void {
			throw new AbstractMethodError();
		}

		public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayPosition = position;
			_rayDirection = direction;
		}

		public function set entity( entity:Entity ):void {
			_entity = entity;
		}

		public function get entity():Entity {
			return _entity;
		}

		protected function reset():void {
			_collides = false;
			_collisionData = null;
		}

		public function get collides():Boolean {
			return _collides;
		}

		public function get collisionData():RayCollisionVO {
			return _collisionData;
		}

		public function set collisionData( data:RayCollisionVO ):void {
			_collisionData = data;
		}

		public function get rayPosition():Vector3D {
			return _rayPosition;
		}

		public function get rayDirection():Vector3D {
			return _rayDirection;
		}
	}
}
