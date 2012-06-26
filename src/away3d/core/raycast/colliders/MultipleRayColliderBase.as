package away3d.core.raycast.colliders
{

	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Entity;

	import flash.utils.Dictionary;

	// TODO: use linked lists instead of vectors? line up collision test shows that vectors aren't too bad

	public class MultipleRayColliderBase extends RayColliderBase
	{
		protected var _entities:Vector.<Entity>;
		protected var _numberOfCollisions:uint;
		protected var _collisionDatas:Dictionary;

		public function MultipleRayColliderBase() {
			super();
		}

		override protected function reset():void {
			super.reset();
			_numberOfCollisions = 0;
			_collisionDatas = null;
		}

		public function addCollisionDataForEntity( thisEntity:Entity, data:RayCollisionVO ):void {
			if( _collisionDatas == null ) {
				_collisionDatas = new Dictionary();
			}
			_collisionDatas[ thisEntity ] = data;
		}

		public function getCollisionDataForEntity( thisEntity:Entity ):RayCollisionVO {
			return _collisionDatas[ thisEntity ];
		}

		public function get entities():Vector.<Entity> {
			return _entities;
		}

		public function set entities( value:Vector.<Entity> ):void {
			_entities = value;
		}

		public function get numberOfCollisions():uint {
			return _numberOfCollisions;
		}

		public function get collisionDatas():Dictionary {
			return _collisionDatas;
		}

		public function set collisionDatas( value:Dictionary ):void {
			_collisionDatas = value;
		}
	}
}
