package away3d.core.raycast.colliders.bounds
{

	import away3d.core.raycast.colliders.*;
	import away3d.core.raycast.data.RayCollisionVO;

	public class BoundsRayCollider extends RayColliderBase
	{
		public function BoundsRayCollider() {
			super();
		}

		override public function evaluate():void {

			reset();

			var collisionT:Number;
			var cameraIsInEntityBounds:Boolean;

			// convert ray to object space
			_rayPosition = _entity.inverseSceneTransform.transformVector( _rayPosition );
			_rayDirection = _entity.inverseSceneTransform.deltaTransformVector( _rayDirection );

			// check for ray-bounds collision
			collisionT = _entity.bounds.intersectsRay( _rayPosition, _rayDirection );

			// accept cases on which the ray starts inside the bounds
			cameraIsInEntityBounds = false;
			if( collisionT == -1 ) {
				cameraIsInEntityBounds = _entity.bounds.containsPoint( _rayPosition );
				if( cameraIsInEntityBounds ) {
					collisionT = 0;
				}
			}

			if( collisionT >= 0 ) {

				_collides = true;

				// Store collision data.
				_collisionData = new RayCollisionVO();
				_collisionData.nearT = collisionT;
				_collisionData.farT = _entity.bounds.rayFarT;
				_collisionData.localRayPosition = _rayPosition;
				_collisionData.localRayDirection = _rayDirection;
				_collisionData.rayOriginIsInsideBounds = cameraIsInEntityBounds;
				_collisionData.position = _entity.bounds.rayIntersectionPoint;
				_collisionData.normal = _entity.bounds.rayIntersectionNormal;
			}
		}
	}
}
