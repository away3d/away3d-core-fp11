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

	public class RaycastPicker implements IPicker
	{
		// TODO: add option of finding best hit?

		private var _findClosestCollision:Boolean;

		protected var _entities:Vector.<Entity>;
		protected var _numEntities:uint;
		protected var _hasCollisions:Boolean;

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
			var rayPosition:Vector3D = view.camera.scenePosition;
			var rayDirection:Vector3D = view.getRay( x, y );

			//reset
			_hasCollisions = false;

			//evaluate
			// Perform ray-bounds collision checks.
			var localRayPosition:Vector3D;
			var localRayDirection:Vector3D;
			var collisionT:Number;
			var rayOriginIsInsideBounds:Boolean;
			var pickingCollisionVO:PickingCollisionVO;

			// Sweep all filtered entities.

			_numEntities = 0;
			var node : EntityListItem = collector.entityHead;
			while (node) {
				entity = node.entity;

				if( entity.visible && entity._implicitMouseEnabled ) {
					// convert ray to entity space
					var invSceneTransform : Matrix3D = entity.inverseSceneTransform;
					var bounds:BoundingVolumeBase = entity.bounds;
					localRayPosition = invSceneTransform.transformVector( rayPosition );
					localRayDirection = invSceneTransform.deltaTransformVector( rayDirection );

					// check for ray-bounds collision
					collisionT = bounds.rayIntersection( localRayPosition, localRayDirection );

					// accept cases on which the ray starts inside the bounds
					rayOriginIsInsideBounds = false;
					if( collisionT == -1 ) {
						rayOriginIsInsideBounds = bounds.containsPoint( localRayPosition );
						if( rayOriginIsInsideBounds ) {
							collisionT = 0;
						}
					}

					if( collisionT >= 0 ) {
						_hasCollisions = true;

						// Store collision data.
						pickingCollisionVO = entity.pickingCollisionVO;
						pickingCollisionVO.collisionT = collisionT;
						pickingCollisionVO.localRayPosition = localRayPosition;
						pickingCollisionVO.localRayDirection = localRayDirection;
						pickingCollisionVO.rayOriginIsInsideBounds = rayOriginIsInsideBounds;
						pickingCollisionVO.localNormal = bounds._rayIntersectionNormal;

						// Store in new data set.
						_entities[_numEntities++] = entity;
					}
				}
				node = node.next;
			}

			// trim before sorting
			_entities.length = _numEntities;

			// Sort entities from closest to furthest.
			// TODO: Instead of sorting the array, create it one item at a time in a sorted manner.
			// Note: EntityCollector does provide the entities with some sorting, its not random, make use of that.
			// However, line up collision test shows that the current implementation isn't too bad.
			_entities = _entities.sort( sortOnNearT );

			if( !_hasCollisions )
				return null;

			// ---------------------------------------------------------------------
			// Evaluate triangle collisions when needed.
			// Replaces collision data provided by bounds collider with more precise data.
			// ---------------------------------------------------------------------

			// does not search for closest collision, first found will do... // TODO: implement _findClosestCollision
			// Example: Bound B is inside bound A. Bound A's collision t is closer than bound B. Both have tri colliders. Bound A surface hit
			// is further than bound B surface hit. Atm, this algorithm would fail in detecting that B's surface hit is actually closer.
			// Suggestions: calculate ray bounds near and far t's and evaluate bound intersections within ray trajectory.

			var shortestCollisionDistance:Number = Number.MAX_VALUE;

			for( i = 0; i < _numEntities; ++i ) {
				entity = _entities[i];
				pickingCollisionVO = entity._pickingCollisionVO;
				if( entity._pickingCollider) {
					// If a collision exists, update the collision data and stop all checks.
					if( entity.collidesBefore(shortestCollisionDistance) ) {
						//TODO: break loop unless best hit is required
						//if (!_findClosestCollision)
							updateLocalPosition(pickingCollisionVO);
							return pickingCollisionVO;
					}
				}
				else { // A bounds collision with no triangle collider stops all checks.
					updateLocalPosition(pickingCollisionVO);
					return pickingCollisionVO;
				}
			}

			return null;
		}

		private function updateLocalPosition(pickingCollisionVO : PickingCollisionVO) : void
		{
			var collisionPos : Vector3D = pickingCollisionVO.localPosition ||= new Vector3D();
			var rayDir : Vector3D = pickingCollisionVO.localRayDirection;
			var rayPos : Vector3D = pickingCollisionVO.localRayPosition;
			var t : Number = pickingCollisionVO.collisionT;
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
			return entity1.pickingCollisionVO.collisionT > entity2.pickingCollisionVO.collisionT ? 1 : -1;
		}
	}
}
