package away3d.raytracing.colliders
{

	import away3d.entities.Mesh;

	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	public class RayGroupCollider extends RayCollider
	{
		private var _boundsCollider:RayBoundsCollider;
		private var _meshCollider:RayMeshCollider;

		public function RayGroupCollider() {
			super();
			_boundsCollider = new RayBoundsCollider();
			_meshCollider = new RayMeshCollider();
		}

		// TODO: remove these on release
		public var boundsTestTime:uint;
		public var meshTestTime:uint;

		override public function evaluate( ...params ):Boolean {
			
			var meshes:Vector.<Mesh> = params[ 0 ];

			boundsTestTime = getTimer();
			var boundsCollision:Boolean = _boundsCollider.evaluate( meshes );
			boundsTestTime = getTimer() - boundsTestTime;

			// triangle mesh collision test
			meshTestTime = getTimer();
			if( boundsCollision ) {

				// sort colliders, closest first
				_boundsCollider.sortColliders();

				// find a proper mesh collision
				var numBoundCollisions:uint = _boundsCollider.colliders.length;
				for( var i:uint; i < numBoundCollisions; ++i ) {
					_meshCollider.mesh = _boundsCollider.colliders[ i ].mesh;
					var transformedRayPosition:Vector3D = _meshCollider.mesh.inverseSceneTransform.transformVector( _rayPosition );
					var transformedRayDirection:Vector3D = _meshCollider.mesh.inverseSceneTransform.deltaTransformVector( _rayDirection );
					_meshCollider.updateRay( transformedRayPosition, transformedRayDirection );
					if( _meshCollider.evaluate() ) {
						_collides = true;
						meshTestTime = getTimer() - meshTestTime;
						return true;
					}
				}
			}
			meshTestTime = getTimer() - meshTestTime;

			_collides = false;
			return false;
		}

		override public function updateRay( p:Vector3D, v:Vector3D ):void {
			_boundsCollider.updateRay( p, v );
			_meshCollider.updateRay( p, v );
			super.updateRay( p, v );
		}

		public function get meshCollider():RayMeshCollider {
			return _meshCollider;
		}

		public function get boundsCollider():RayBoundsCollider {
			return _boundsCollider;
		}
	}
}
