package away3d.core.raycast.colliders
{

	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	public class BoundsRayCollider extends RayColliderBase
	{
		public function BoundsRayCollider() {
			super();
		}

		override public function evaluate():void {

			reset();

			var entity:Entity;
			var collisionT:Number;
			var cameraIsInEntityBounds:Boolean;
			var localRayPosition:Vector3D;
			var localRayDirection:Vector3D;
			var boundsCollisionVO:RayCollisionVO;

			// Identify entity
			entity = _entities[ 0 ];

			// convert ray to object space
			localRayPosition = entity.inverseSceneTransform.transformVector( _rayPosition );
			localRayDirection = entity.inverseSceneTransform.deltaTransformVector( _rayDirection );

			// check for ray-bounds collision
			collisionT = entity.bounds.intersectsRay( localRayPosition, localRayDirection );

			// accept cases on which the ray starts inside the bounds
			cameraIsInEntityBounds = false;
			if( collisionT == -1 ) {
				cameraIsInEntityBounds = entity.bounds.containsPoint( localRayPosition );
				if( cameraIsInEntityBounds ) {
					collisionT = 0;
				}
			}

			if( collisionT >= 0 ) {

				_aCollisionExists = true;
				_numberOfCollisions++;

				// store data for the list item
				boundsCollisionVO = new RayCollisionVO();
				boundsCollisionVO.collisionNearT = collisionT;
				boundsCollisionVO.collisionFarT = entity.bounds.rayFarT;
				boundsCollisionVO.localRayPosition = localRayPosition;
				boundsCollisionVO.localRayDirection = localRayDirection;
				boundsCollisionVO.rayOriginIsInsideBounds = cameraIsInEntityBounds;
				var collisionPoint:Vector3D = new Vector3D(); // TODO: can extract from bounds object?
				collisionPoint.x = localRayPosition.x + collisionT * localRayDirection.x;
				collisionPoint.y = localRayPosition.y + collisionT * localRayDirection.y;
				collisionPoint.z = localRayPosition.z + collisionT * localRayDirection.z;
				boundsCollisionVO.collisionPoint = collisionPoint;
				setCollisionDataForItem( _entities[ 0 ], boundsCollisionVO );
			}
		}
	}
}
