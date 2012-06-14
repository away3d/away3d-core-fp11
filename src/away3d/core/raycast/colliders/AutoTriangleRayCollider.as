package away3d.core.raycast.colliders
{

	import away3d.core.base.SubMesh;
	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	public class AutoTriangleRayCollider extends TriangleRayCollider
	{
		private var _triangleCountLimit:uint = 1000; // TODO: evaluate good default value

		private var _triangleCountLimitDirty:Boolean = true;
		private var _activeChildCollider:TriangleRayCollider;

		public function AutoTriangleRayCollider() {
			super();
			_activeChildCollider = new AS3TriangleRayCollider();
		}

		public function get triangleCountLimit():uint {
			return _triangleCountLimit;
		}

		public function set triangleCountLimit( value:uint ):void {
			if( value == _triangleCountLimit ) return;
			_triangleCountLimit = value;
			_triangleCountLimitDirty = true;
		}

		override public function evaluateSubMesh( subMesh:SubMesh ):Boolean {

			// Need sub collider swap?
			if( _triangleCountLimitDirty ) {

				if( subMesh.numTriangles > _triangleCountLimit ) _activeChildCollider = new PBTriangleRayCollider();
				else _activeChildCollider = new AS3TriangleRayCollider();

				_triangleCountLimitDirty = false;
			}

			// Make sure the new collider has the necessary data.
			_activeChildCollider.targetMesh = targetMesh;
			_activeChildCollider.localRayPosition = localRayPosition;
			_activeChildCollider.localRayDirection = localRayPosition;

			// Evaluate collision.
			var collides:Boolean = _activeChildCollider.evaluateSubMesh( subMesh );
			if( collides ) {
				_collisionData = _activeChildCollider.collisionData;
			}

			trace( "sub mesh collision: " + collides ); // TODO: weird, returns true whenever mouse is over bounds...
			// Means it always returns true??

			return collides;
		}
	}
}
