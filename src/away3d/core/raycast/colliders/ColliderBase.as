package away3d.core.raycast.colliders
{

	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;

	public class ColliderBase
	{
		protected var _collisionExists:Boolean;
		protected var _rayPosition:Vector3D;
		protected var _rayDirection:Vector3D;
		protected var _collisionPoint:Vector3D;
		protected var _t:Number;
		protected var _collidingRenderable:IRenderable;

		public function ColliderBase() {
			_rayPosition = new Vector3D();
			_rayDirection = new Vector3D();
			_collisionPoint = new Vector3D();
		}

		public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayPosition = position;
			_rayDirection = direction;
		}

		public function evaluate( item:RenderableListItem ):Boolean {
			throw new AbstractMethodError();
		}

		public function get collisionExists():Boolean {
			return _collisionExists;
		}

		public function get collisionPoint():Vector3D {
			if( !_collisionExists ) return null;
			return _collisionPoint;
		}

		public function get collidingRenderable():IRenderable {
			if( !_collisionExists ) return null;
			return _collidingRenderable;
		}

		public function get collisionT():Number {
			return _t;
		}
	}
}
