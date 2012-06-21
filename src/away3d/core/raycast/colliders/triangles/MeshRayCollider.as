package away3d.core.raycast.colliders.triangles
{

	import away3d.core.base.Object3D;
	import away3d.core.base.SubMesh;
	import away3d.core.raycast.colliders.*;
	import away3d.entities.Mesh;

	public class MeshRayCollider extends RayColliderBase
	{
		private var _subMeshCollider:SubMeshRayColliderBase;

		public function MeshRayCollider( subMeshCollider:SubMeshRayColliderBase ) {
			super();
			_subMeshCollider = subMeshCollider;
		}

		override public function evaluate():void {
			reset();
			evaluateObject3D( _entity );
		}

		private function evaluateObject3D( object3d:Object3D ):void {

			var i:uint, len:uint;

			// Evaluate mesh's sub-mesh objects.
			if( object3d is Mesh ) {
				var mesh:Mesh = object3d as Mesh;
				_subMeshCollider.entity = mesh;
				// Transform ray to mesh's object space.
				_subMeshCollider.updateRay(
					mesh.inverseSceneTransform.transformVector( _rayPosition ),
					mesh.inverseSceneTransform.deltaTransformVector( _rayDirection )
				);
				len = mesh.subMeshes.length;
				for( i = 0; i < len; i++ ) {
					var subMesh:SubMesh = mesh.subMeshes[ i ];
					trace( "tri testing on subMesh of " + subMesh.numTriangles + " triangles." );
					_subMeshCollider.subMesh = subMesh;
					_subMeshCollider.evaluate();
					if( _subMeshCollider.collides ) {
						_collides = true;
						_collisionData = _subMeshCollider.collisionData;
						return;
					}
				}
			}

			// Note, potential children are not swept by the collider, it ignores them completely.
			// However, when used for picking, EntityCollector provides a flattened list of entities with children at the same level of their parents,
		}
	}
}
