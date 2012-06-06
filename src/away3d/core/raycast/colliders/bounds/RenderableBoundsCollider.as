package away3d.core.raycast.colliders.bounds
{

	import away3d.core.base.IRenderable;
	import away3d.core.data.LinkedListUtil;
	import away3d.core.data.ListItem;
	import away3d.core.data.RenderableListItem;
	import away3d.core.raycast.colliders.RayColliderBase;
	import away3d.core.raycast.colliders.bounds.vo.BoundsCollisionVO;

	import flash.geom.Vector3D;

	/*
	 * Given the first item of a linked list of RenderableListItem's, evaluates which of these items collide with a ray, evaluates ray-bounds intersection points,
	 * closest intersection point from ray origin, etc.
	 * */
	public class RenderableBoundsCollider extends RayColliderBase
	{
		public function RenderableBoundsCollider() {
			super();
		}

		/*
		* Assumes that a renderable list item has been set with updateCurrentListItem(),
		* and that a ray has been set by updateRay().
		* */
		override public function evaluate():void {

			var collisionT:Number;
			var renderable:IRenderable;
			var cameraIsInEntityBounds:Boolean;
			var objectSpaceRayPosition:Vector3D;
			var objectSpaceRayDirection:Vector3D;
			var boundsCollisionVO:BoundsCollisionVO;

			var renderableListItem:RenderableListItem = RenderableListItem( _currentListItem );

			_lastCollidingListItem = null;
			_numberOfCollisions = 0;

			// sweep renderables and collect entities whose bounds are hit by ray
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

					// store the colliding list item
					if( _lastCollidingListItem == null ) {
						_collidingListItemHead = renderableListItem;
					}
					else {
						_lastCollidingListItem.next = renderableListItem;
					}
					_lastCollidingListItem = renderableListItem;

					// store data for the list item
					boundsCollisionVO = new BoundsCollisionVO();
					boundsCollisionVO.collisionNearT = collisionT;
					boundsCollisionVO.collisionFarT = renderable.bounds.rayFarT;
					boundsCollisionVO.localRayPosition = objectSpaceRayPosition;
					boundsCollisionVO.localRayDirection = objectSpaceRayDirection;
					boundsCollisionVO.rayOriginIsInsideBounds = cameraIsInEntityBounds;
					_collisionData[ renderableListItem ] = boundsCollisionVO;
				}

				// advance in linked list
				renderableListItem = RenderableListItem( renderableListItem.next );
			}

			// sort collider list from nearest t to furthest t
			LinkedListUtil.sortLinkedList( _collidingListItemHead, _numberOfCollisions, onNearestT );
		}

		private function onNearestT( item1:ListItem, item2:ListItem ):int {
			var boundsCollisionVO1:BoundsCollisionVO = _collisionData[ item1 ];
			var boundsCollisionVO2:BoundsCollisionVO = _collisionData[ item2 ];
			return boundsCollisionVO1.collisionNearT < boundsCollisionVO2.collisionNearT ? -1 : 1;
		}
	}
}
