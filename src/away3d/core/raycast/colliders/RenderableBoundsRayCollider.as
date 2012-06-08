package away3d.core.raycast.colliders
{

	import away3d.core.base.IRenderable;
	import away3d.core.data.LinkedListItem;
	import away3d.core.data.LinkedListItem;
	import away3d.core.raycast.data.RayCollisionVO;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	/*
		 * Given the first item of a linked list of RenderableListItem's, evaluates which of these items collide with a ray, evaluates ray-bounds intersection points,
		 * closest intersection point from ray origin, etc.
		 * */
	public class RenderableBoundsRayCollider extends RayColliderBase
	{
		public function RenderableBoundsRayCollider() {
			super();
		}

		/*
		* Assumes that a renderable list item has been set with updateCurrentListItem(),
		* and that a ray has been set by updateRay().
		* */
		override public function evaluate():void {

			reset();

			// ---------------------------------------------------------------------
			// Produce a new list of renderables whose bounds collide with the ray,
			// and calculate collision data.
			// ---------------------------------------------------------------------

			var collisionT:Number;
			var renderable:IRenderable;
			var lastCollidingItem:LinkedListItem;
			var cameraIsInEntityBounds:Boolean;
			var objectSpaceRayPosition:Vector3D;
			var objectSpaceRayDirection:Vector3D;
			var boundsCollisionVO:RayCollisionVO;
			var renderableListItem:LinkedListItem;

			// TODO (important): this assumes that renderables will have their own bounds.
			// At the moment renderables return their source entity bounds (which are bigger),
			// and potentially the same source entity bounds are checked multiple times.

			// sweep renderables and collect entities whose bounds are hit by ray
			renderableListItem = _linkedListHeadItem;
			while( renderableListItem ) {

				// id renderable
				renderable = renderableListItem.renderable;

				// convert ray to object space
				objectSpaceRayPosition = renderable.inverseSceneTransform.transformVector( _rayPosition );
				objectSpaceRayDirection = renderable.inverseSceneTransform.deltaTransformVector( _rayDirection );

				// check for ray-bounds collision
				collisionT = renderable.bounds.intersectsRay( objectSpaceRayPosition, objectSpaceRayDirection );

				// accept cases on which the ray starts inside the bounds
				cameraIsInEntityBounds = false;
				if( collisionT == -1 ) {
					cameraIsInEntityBounds = renderable.bounds.containsPoint( objectSpaceRayPosition );
					if( cameraIsInEntityBounds ) collisionT = 0;
				}

				// store collision cases
				if( collisionT >= 0 ) {

					_numberOfCollisions++;
					_collisionExists = true;

					// store the colliding list item
					if( lastCollidingItem == null ) {
						_linkedListHeadItem = renderableListItem;
					}
					else {
						lastCollidingItem.next = renderableListItem;
					}
					lastCollidingItem = renderableListItem;

					if( !_collisionData ) {
						_collisionData = new Dictionary();
					}

					// store data for the list item
					boundsCollisionVO = new RayCollisionVO();
					boundsCollisionVO.collisionNearT = collisionT;
					boundsCollisionVO.collisionFarT = renderable.bounds.rayFarT;
					boundsCollisionVO.localRayPosition = objectSpaceRayPosition;
					boundsCollisionVO.localRayDirection = objectSpaceRayDirection;
					boundsCollisionVO.rayOriginIsInsideBounds = cameraIsInEntityBounds;
					_collisionData[ renderableListItem ] = boundsCollisionVO;
				}

				// advance in linked list
				renderableListItem = renderableListItem.next;
			}

			// ---------------------------------------------------------------------
			// Order the produced list of colliding items from closest to furthest.
			// ---------------------------------------------------------------------

			// TODO: activate and verify
			/*var i:uint, j:uint;

			var item1:LinkedListItem;
			var item2:LinkedListItem;
			var item3:LinkedListItem;

			var boundsCollisionVO1:RayCollisionVO;
			var boundsCollisionVO2:RayCollisionVO;

			var subListLength:uint = _numberOfCollisions - 1;

			for( i = 1; i < _numberOfCollisions; ++i ) {
				item1 = _linkedListHeadItem;
				item2 = _linkedListHeadItem.next;
				item3 = item2.next;
				for( j = 1; j <= subListLength; ++j ) {
					boundsCollisionVO1 =  _collisionData[ item2 ];
					boundsCollisionVO2 =  _collisionData[ item3 ];
					if( boundsCollisionVO1.collisionNearT < boundsCollisionVO2.collisionNearT ) {
						item2.next = item3.next;
						item3.next = item2;
						item1.next = item3;
						item1 = item3;
						item3 = item2.next;
					}
					else {
						item1 = item2;
						item2 = item3;
						item3 = item3.next;
					}
				}
			}*/
		}
	}
}
