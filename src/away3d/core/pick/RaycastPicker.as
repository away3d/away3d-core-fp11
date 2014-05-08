package away3d.core.pick
{
	import away3d.entities.IEntity;

	import flash.geom.Vector3D;
	
	import away3d.arcane;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.core.pool.EntityListItem;
	import away3d.core.traverse.RaycastCollector;

	use namespace arcane;
	
	/**
	 * Picks a 3d object from a view or scene by 3D raycast calculations.
	 * Performs an initial coarse boundary calculation to return a subset of entities whose bounding volumes intersect with the specified ray,
	 * then triggers an optional picking collider on individual entity objects to further determine the precise values of the picking ray collision.
	 */
	public class RaycastPicker implements IPicker
	{
		private static const tempRayPosition:Vector3D = new Vector3D();
		private static const tempRayDirection:Vector3D = new Vector3D();
		// TODO: add option of finding best hit?
		
		private var _findClosestCollision:Boolean;
		private var _raycastCollector:RaycastCollector = new RaycastCollector();
		private var _ignoredEntities:Array = [];
		private var _onlyMouseEnabled:Boolean = true;
		
		protected var _entities:Vector.<IEntity>;
		protected var _numEntities:uint;
		protected var _hasCollisions:Boolean;

		/**
		 * @inheritDoc
		 */
		public function get onlyMouseEnabled():Boolean
		{
			return _onlyMouseEnabled;
		}
		
		public function set onlyMouseEnabled(value:Boolean):void
		{
			_onlyMouseEnabled = value;
		}
		
		/**
		 * Creates a new <code>RaycastPicker</code> object.
		 *
		 * @param findClosestCollision Determines whether the picker searches for the closest bounds collision along the ray,
		 * or simply returns the first collision encountered Defaults to false.
		 */
		public function RaycastPicker(findClosestCollision:Boolean)
		{
			
			_findClosestCollision = findClosestCollision;
			_entities = new Vector.<IEntity>();
		}

		/**
		 * @inheritDoc
		 */
		/**
		 * @inheritDoc
		 */
		public function getViewCollision(x:Number, y:Number, view:View3D):PickingCollisionVO
		{
			//update ray
			var rayPosition:Vector3D = view.unproject(x, y, 0);
			var rayDirection:Vector3D = view.unproject(x, y, 1).subtract(rayPosition);

			return this.getSceneCollision(rayPosition, rayDirection, view.scene);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO
		{
			//clear collector
			_raycastCollector.clear();
			
			//setup ray vectors
			_raycastCollector.rayPosition = position;
			_raycastCollector.rayDirection = direction;
			
			// collect entities to test
			scene.traversePartitions(_raycastCollector);
			
			_numEntities = 0;
			var node:EntityListItem = _raycastCollector.entityHead;
			var entity:IEntity;
			while (node) {
				entity = node.entity;
				
				if (isIgnored(entity)) {
					node = node.next;
					continue;
				}
				
				_entities[_numEntities++] = entity;
				
				node = node.next;
			}
			
			//early out if no collisions detected
			if (!_numEntities)
				return null;
			
			return getPickingCollisionVO();
		}
		
		public function setIgnoreList(entities:Array):void
		{
			_ignoredEntities = entities;
		}
		
		private function isIgnored(entity:IEntity):Boolean
		{
			if (_onlyMouseEnabled && !entity.isMouseEnabled)
				return true;
			
			var ignoredEntity:IEntity;
			for each (ignoredEntity in _ignoredEntities) {
				if (ignoredEntity == entity)
					return true;
			}
			
			return false;
		}
		
		private function sortOnNearT(entity1:IEntity, entity2:IEntity):Number
		{
			return entity1.pickingCollisionVO.rayEntryDistance > entity2.pickingCollisionVO.rayEntryDistance? 1 : -1;
		}
		
		private function getPickingCollisionVO():PickingCollisionVO
		{
			// trim before sorting
			_entities.length = _numEntities;
			
			// Sort entities from closest to furthest.
			_entities = _entities.sort(sortOnNearT);
			
			// ---------------------------------------------------------------------
			// Evaluate triangle collisions when needed.
			// Replaces collision data provided by bounds collider with more precise data.
			// ---------------------------------------------------------------------
			
			var shortestCollisionDistance:Number = Number.MAX_VALUE;
			var bestCollisionVO:PickingCollisionVO;
			var pickingCollisionVO:PickingCollisionVO;
			var entity:IEntity;
			var i:uint;
			
			for (i = 0; i < _numEntities; ++i) {
				entity = _entities[i];
				pickingCollisionVO = entity.pickingCollisionVO;
				if (entity.pickingCollider) {
					// If a collision exists, update the collision data and stop all checks.
					if ((bestCollisionVO == null || pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) && entity.testCollision(shortestCollisionDistance, _findClosestCollision)) {
						shortestCollisionDistance = pickingCollisionVO.rayEntryDistance;
						bestCollisionVO = pickingCollisionVO;
						if (!_findClosestCollision) {
							updateLocalPosition(pickingCollisionVO);
							return pickingCollisionVO;
						}
					}
				} else if (bestCollisionVO == null || pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) { // A bounds collision with no triangle collider stops all checks.
					// Note: a bounds collision with a ray origin inside its bounds is ONLY ever used
					// to enable the detection of a corresponsding triangle collision.
					// Therefore, bounds collisions with a ray origin inside its bounds can be ignored
					// if it has been established that there is NO triangle collider to test
					if (!pickingCollisionVO.rayOriginIsInsideBounds) {
						updateLocalPosition(pickingCollisionVO);
						return pickingCollisionVO;
					}
				}
			}
			
			return bestCollisionVO;
		}
		
		private function updateLocalPosition(pickingCollisionVO:PickingCollisionVO):void
		{
			var collisionPos:Vector3D = pickingCollisionVO.localPosition;
			if(!collisionPos) {
				collisionPos = new Vector3D();
			}

			var rayDir:Vector3D = pickingCollisionVO.localRayDirection;
			var rayPos:Vector3D = pickingCollisionVO.localRayPosition;
			if(!rayDir || !rayPos) return;
			var t:Number = pickingCollisionVO.rayEntryDistance;
			collisionPos.x = rayPos.x + t*rayDir.x;
			collisionPos.y = rayPos.y + t*rayDir.y;
			collisionPos.z = rayPos.z + t*rayDir.z;
		}
		
		public function dispose():void
		{
		}
	}
}
