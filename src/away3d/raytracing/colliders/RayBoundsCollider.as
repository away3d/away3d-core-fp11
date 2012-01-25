package away3d.raytracing.colliders
{

	import away3d.bounds.BoundingVolumeBase;
	import away3d.entities.Mesh;
	import away3d.raytracing.data.CollisionVO;

	import flash.geom.Vector3D;

	public class RayBoundsCollider extends RayCollider
	{
		private var _closestCollisionPoint:Vector3D;
		private var _closestCollisionMesh:Mesh;

		private var _colliders:Vector.<CollisionVO>;

		public function RayBoundsCollider() {
			super();
		}

		/*
		 Tests for collisions between the ray and the bounds of a group of meshes.
		 NOTE: If a mesh has children, they are ignored.
		 */
		override public function evaluate( ...params ):Boolean {

			var meshes:Vector.<Mesh> = params[ 0 ];

			_colliders = new Vector.<CollisionVO>();

			var mesh:Mesh;
			var bounds:BoundingVolumeBase;
			var len:uint = meshes.length;
			for( var i:uint; i < len; ++i ) {

				mesh = meshes[ i ];
				if( mesh.visible ) {
					bounds = mesh.bounds;

					// transform ray to object space
					var tp:Vector3D = mesh.inverseSceneTransform.transformVector( _rayPosition );
					var tv:Vector3D = mesh.inverseSceneTransform.deltaTransformVector( _rayDirection );

					var t:Number = bounds.intersectsRay( tp, tv );

					if( t > 0 ) {
						var objSpaceCollisionPoint:Vector3D = new Vector3D(
								tp.x + t * tv.x,
								tp.y + t * tv.y,
								tp.z + t * tv.z
						);
						_colliders.push( new CollisionVO( mesh, t, objSpaceCollisionPoint ) );
					}
				}
			}

			_collides = _colliders.length > 0;

			return _collides;
		}

		public function evaluateClosestCollision():void {

			_closestCollisionPoint = new Vector3D();
			_closestCollisionMesh = null;

			if( _colliders.length == 0 ) {
				return;
			}

			// find smallest t
			var i:uint;
			var len:uint = _colliders.length;
			var smallestTIndex:uint = 0;
			for( i = 1; i < len; ++i ) {
				if( _colliders[ i ].t < _colliders[ smallestTIndex ].t ) {
					smallestTIndex = i;
				}
			}

			_closestCollisionMesh = _colliders[ smallestTIndex ].mesh;
			_closestCollisionPoint = _colliders[ smallestTIndex ].mesh.sceneTransform.transformVector( _colliders[ smallestTIndex ].point );
		}

		public function sortColliders():void {
			if( _colliders.length == 0 ) return;
			_colliders = _colliders.sort( sortOnClosestT );
		}

		private function sortOnClosestT( a:CollisionVO, b:CollisionVO ):Number {
			if( a.t < b.t ) return -1;
			else if( a.t > b.t ) return 1;
			else return 0;
		}

		public function get colliders():Vector.<CollisionVO> {
			return _colliders;
		}

		public function get closestCollisionPoint():Vector3D {
			return _closestCollisionPoint;
		}

		public function get closestCollisionMesh():Mesh {
			return _closestCollisionMesh;
		}
	}
}
