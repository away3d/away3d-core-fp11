package away3d.core.raycast.colliders
{

	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubMesh;
	import away3d.entities.Mesh;
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;

	public class TriangleRayCollider extends RayColliderBase
	{
		private var _targetMesh:Mesh;
		private var _localRayPosition:Vector3D;
		private var _localRayDirection:Vector3D;

		public function TriangleRayCollider() {
			super();
		}

		override public function evaluate():void {
			reset();
			evaluateObject3D( _entities[ 0 ] );
		}

		private function evaluateObject3D( object3d:Object3D ):void {

			var i:uint, len:uint;
			var container:ObjectContainer3D;

			// Sweep children and sub-meshes.
			if( object3d is ObjectContainer3D ) {

				// Evaluate mesh sub-meshes.
				if( object3d is Mesh ) {
					_targetMesh = object3d as Mesh;
					// Transform ray to mesh's object space.
					localRayPosition = _targetMesh.inverseSceneTransform.transformVector( _rayPosition );
					localRayDirection = _targetMesh.inverseSceneTransform.deltaTransformVector( _rayDirection );
					len = _targetMesh.subMeshes.length;
					for( i = 0; i < len; i++ ) {
						if( evaluateSubMesh( _targetMesh.subMeshes[ i ] ) ) {
							_aCollisionExists = true;
							return;
						}
					}
				}

				// Evaluate container children.
				container = object3d as ObjectContainer3D;
				len = container.numChildren;
				for( i = 0; i < len; i++ ) {
					if( !_aCollisionExists ) {
						evaluateObject3D( container.getChildAt( i ) );
					}
				}
			}
		}

		public function evaluateSubMesh( subMesh:SubMesh ):Boolean {
			throw new AbstractMethodError();
		}

		public function get localRayPosition():Vector3D {
			return _localRayPosition;
		}

		public function set localRayPosition( value:Vector3D ):void {
			_localRayPosition = value;
		}

		public function get localRayDirection():Vector3D {
			return _localRayDirection;
		}

		public function set localRayDirection( value:Vector3D ):void {
			_localRayDirection = value;
		}

		public function get targetMesh():Mesh {
			return _targetMesh;
		}

		public function set targetMesh( value:Mesh ):void {
			_targetMesh = value;
		}
	}
}
