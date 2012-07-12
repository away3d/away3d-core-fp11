package away3d.core.pick
{

	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.arcane;
	import away3d.core.data.EntityListItem;
	import away3d.core.traverse.EntityCollector;
	import away3d.entities.Entity;

	import flash.geom.Matrix3D;

	import flash.geom.Vector3D;

	use namespace arcane;
	
	/**
	 * Picks a 3d object from a view or scene by 3D raycast calculations.
	 * Performs an initial coarse boundary calculation to return a subset of entities whose bounding volumes intersect with the specified ray,
	 * then triggers an optional picking collider on individual entity objects to further determine the precise values of the picking ray collision.
	 */
	public class RaycastPicker implements IPicker
	{
		// TODO: add option of finding best hit?

		private var _findClosestCollision:Boolean;

		protected var _entities:Vector.<Entity>;
		protected var _numEntities:uint;
		protected var _hasCollisions:Boolean;

		/**
		 * Creates a new <code>RaycastPicker</code> object.
		 * 
		 * @param findClosestCollision Determines whether the picker searches for the closest bounds collision along the ray,
		 * or simply returns the first collision encountered Defaults to false.
		 */
		public function RaycastPicker( findClosestCollision:Boolean ) {

			_findClosestCollision = findClosestCollision;
			_entities = new Vector.<Entity>();
		}

		/**
		 * @inheritDoc
		 */
		public function getViewCollision(x:Number, y:Number, view:View3D):PickingCollisionVO
		{
			var entity : Entity;
			//cast ray through the collection of entities on the view
			var collector:EntityCollector = view.entityCollector;
			var i:uint;

			if( collector.numMouseEnableds == 0 )
				return null;

			//update ray
			var rayPosition:Vector3D = view.unproject( x, y, 0 );
			var rayDirection:Vector3D = view.unproject( x, y, 1 );
			rayDirection = rayDirection.subtract( rayPosition );

			//reset
			_hasCollisions = false;

			// Perform ray-bounds collision checks.
			var localRayPosition:Vector3D;
			var localRayDirection:Vector3D;

			var rayEntryDistance:Number;
			var pickingCollisionVO:PickingCollisionVO;

			// Sweep all filtered entities.

			_numEntities = 0;
			var node : EntityListItem = collector.entityHead;
			while (node) {
				entity = node.entity;

				if( entity.visible && entity._ancestorsAllowMouseEnabled && entity.mouseEnabled ) {
					pickingCollisionVO = entity.pickingCollisionVO;
					// convert ray to entity space
					var invSceneTransform : Matrix3D = entity.inverseSceneTransform;
					var bounds:BoundingVolumeBase = entity.bounds;
					localRayPosition = invSceneTransform.transformVector( rayPosition );
					localRayDirection = invSceneTransform.deltaTransformVector( rayDirection );

					// check for ray-bounds collision
					rayEntryDistance = bounds.rayIntersection( localRayPosition, localRayDirection, pickingCollisionVO.localNormal ||= new Vector3D());

					if( rayEntryDistance >= 0 ) {
						_hasCollisions = true;

						// Store collision data.
						pickingCollisionVO.rayEntryDistance = rayEntryDistance;
						pickingCollisionVO.localRayPosition = localRayPosition;
						pickingCollisionVO.localRayDirection = localRayDirection;
						pickingCollisionVO.rayOriginIsInsideBounds = rayEntryDistance == 0;

						// Store in new data set.
						_entities[_numEntities++] = entity;
					}
				}
				node = node.next;
			}

			// trim before sorting
			_entities.length = _numEntities;

			// Sort entities from closest to furthest.
			_entities = _entities.sort( sortOnNearT );

			if( !_hasCollisions )
				return null;

			// ---------------------------------------------------------------------
			// Evaluate triangle collisions when needed.
			// Replaces collision data provided by bounds collider with more precise data.
			// ---------------------------------------------------------------------

			var shortestCollisionDistance:Number = Number.MAX_VALUE;
			var bestCollisionVO:PickingCollisionVO;

			for( i = 0; i < _numEntities; ++i ) {
				entity = _entities[i];
				pickingCollisionVO = entity._pickingCollisionVO;
				if(entity.pickingCollider) {
					// If a collision exists, update the collision data and stop all checks.
					if( (bestCollisionVO == null || pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) && entity.collidesBefore(shortestCollisionDistance, _findClosestCollision) ) {
						shortestCollisionDistance = pickingCollisionVO.rayEntryDistance;
						bestCollisionVO = pickingCollisionVO;
						//TODO: break loop unless best hit is required
						if (!_findClosestCollision) {
							updateLocalPosition(pickingCollisionVO);
							return pickingCollisionVO;
						}
					}
				}
				else if (bestCollisionVO == null || pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) { // A bounds collision with no triangle collider stops all checks.
					updateLocalPosition(pickingCollisionVO);
					return pickingCollisionVO;
				}
			}

			return bestCollisionVO;
		}

		private function updateLocalPosition(pickingCollisionVO : PickingCollisionVO) : void
		{
			var collisionPos : Vector3D = pickingCollisionVO.localPosition ||= new Vector3D();
			var rayDir : Vector3D = pickingCollisionVO.localRayDirection;
			var rayPos : Vector3D = pickingCollisionVO.localRayPosition;
			var t : Number = pickingCollisionVO.rayEntryDistance;
			collisionPos.x = rayPos.x + t*rayDir.x;
			collisionPos.y = rayPos.y + t*rayDir.y;
			collisionPos.z = rayPos.z + t*rayDir.z;
		}

		/**
		 * @inheritDoc
		 */
		public function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO
		{
			//cast ray through the scene
			// Evaluate new colliding object.
			return null;
		}

		private function sortOnNearT( entity1:Entity, entity2:Entity ):Number
		{
			return entity1.pickingCollisionVO.rayEntryDistance > entity2.pickingCollisionVO.rayEntryDistance ? 1 : -1;
		}
	}
}
