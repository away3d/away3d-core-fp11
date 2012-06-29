package away3d.core.pick
{

	import away3d.arcane;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.core.traverse.*;
	import away3d.entities.*;
	
	import flash.geom.*;
	
	use namespace arcane;
	
	/**
	 * Picks a 3d object from a view or scene by 3D raycast calculations.
	 * Performs an initial coarse boundary calculation to return a subset of entities whose bounding volumes intersect with the specified ray,
	 * then triggers an optional picking collider on individual entity objects to further determine the precise values of the picking ray collision.
	 */
	public class RaycastPicker implements IPicker
	{
		private var _entity:Entity;
		
		// TODO: add option of finding best hit?

		private var _findClosestCollision:Boolean;
		
		protected var _entities:Vector.<Entity>;
		protected var _numberOfCollisions:uint;
		protected var _collides:Boolean;
		protected var _pickingCollisionVO:PickingCollisionVO;
		
		/**
		 * Creates a new <code>RaycastPicker</code> object.
		 * 
		 * @param findClosestCollision Determines whether the picker searches for the closest bounds collision along the ray,
		 * or simply returns the first collision encountered Defaults to false.
		 */
		public function RaycastPicker( findClosestCollision:Boolean ) {
			
			_findClosestCollision = findClosestCollision;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getViewCollision(x:Number, y:Number, view:View3D):PickingCollisionVO
		{
			//cast ray through the collection of entities on the view
			var collector:EntityCollector = view.entityCollector;
			
			//global vars
			var i:uint, len:uint;
			
			// Evaluate new colliding object.
			if( collector.numMouseEnableds == 0 )
				return null;
			
			//update ray
			var rayPosition:Vector3D = view.camera.scenePosition;
			var rayDirection:Vector3D = view.getRay( x, y );
			
			//set entities
			var filteredEntities:Vector.<Entity> = new Vector.<Entity>();

			// Filter out non visibles and non mouse enableds.
			len = collector.entities.length;
			for( i = 0; i < len; i++ ) {
				_entity = collector.entities[ i ];
				if( _entity.visible && _entity._implicitMouseEnabled ) {
					filteredEntities.push( _entity );
				}
			}
			
			//reset
			_collides = false;
			_numberOfCollisions = 0;
			
			//evaluate
			// Perform ray-bounds collision checks.
			var localRayPosition:Vector3D;
			var localRayDirection:Vector3D;
			
			// Sweep all filtered entities.
			len = filteredEntities.length;
			_entities = new Vector.<Entity>();
			for( i = 0; i < len; i++ ) {

				// Id thisEntity.
				_entity = filteredEntities[ i ];

				_pickingCollisionVO = _entity.pickingCollisionVO;
				
				// convert ray to entity space
				localRayPosition = _entity.inverseSceneTransform.transformVector( rayPosition );
				localRayDirection = _entity.inverseSceneTransform.deltaTransformVector( rayDirection );
				
				// check for ray-bounds collision
				if( _entity.bounds.intersectsRay( localRayPosition, localRayDirection, _pickingCollisionVO ) ) {
	
					_collides = true;
					_numberOfCollisions++;
					
					// Store collision data.
					_pickingCollisionVO.localRayPosition = localRayPosition;
					_pickingCollisionVO.localRayDirection = localRayDirection;
					
					// Store in new data set.
					_entities.push( _entity );
				}
			}

			// Sort entities from closest to furthest.
			// TODO: Instead of sorting the array, create it one item at a time in a sorted manner.
			// Note: EntityCollector does provide the entities with some sorting, its not random, make use of that.
			// However, line up collision test shows that the current implementation isn't too bad.
			if( _numberOfCollisions > 1 ) {
				_entities = _entities.sort( sortOnNearT );
			}
			
			if( !_collides )
				return null;
			
			// ---------------------------------------------------------------------
			// Evaluate triangle collisions when needed.
			// Replaces collision data provided by bounds collider with more precise data.
			// ---------------------------------------------------------------------

			var pickingCollider:IPickingCollider;
			var shortestCollisionDistance:Number = Number.MAX_VALUE;
			var bestCollisionVO:PickingCollisionVO;

			for( i = 0; i < _numberOfCollisions; ++i ) {
				_entity = _entities[ i ];
				_pickingCollisionVO = _entity.pickingCollisionVO;
				pickingCollider = _entity.pickingCollider;
				if( pickingCollider) {
					// If no triangle collision has been found, do the triangle test and remember it, if successful. If there is a previous collision, only consider a new candidate if bounds intersect.
					if( (bestCollisionVO == null || _pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) && testCollision( pickingCollider, _pickingCollisionVO, shortestCollisionDistance )) { // new collision is potentially in front of previous best
						shortestCollisionDistance = _pickingCollisionVO.rayEntryDistance;
						bestCollisionVO = _pickingCollisionVO;
						if (!_findClosestCollision)
							return _pickingCollisionVO;
					}
				}
				else if (bestCollisionVO == null || _pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) { // First found bounds collision with no triangle collider will do.
					return _pickingCollisionVO;
				}
			}

			return bestCollisionVO;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO
		{
			//cast ray through the scene
			//TODO: implement scene-based picking
			
			// Evaluate new colliding object.
			return null;
		}

		private function testCollision(pickingCollider:IPickingCollider, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number):Boolean
		{
			pickingCollider.setLocalRay(pickingCollisionVO.localRayPosition, pickingCollisionVO.localRayDirection);

			if (pickingCollisionVO.entity is Mesh) {
				var mesh:Mesh = pickingCollisionVO.entity as Mesh;
				var subMesh:SubMesh;
				var collides:Boolean;
				
				for each (subMesh in mesh.subMeshes) {
					if( pickingCollider.testSubMeshCollision( subMesh, pickingCollisionVO, shortestCollisionDistance ) ) {
						shortestCollisionDistance = _pickingCollisionVO.rayEntryDistance;
						collides = true;
						if( !_findClosestCollision )
							return true;
					}
				}
				
				return collides;
			}
			else { // if not a mesh, rely on entity bounds
				return true;
			}
		}
		
		private function sortOnNearT( entity1:Entity, entity2:Entity ):Number
		{
			return entity1.pickingCollisionVO.rayEntryDistance > entity2.pickingCollisionVO.rayEntryDistance ? 1 : -1;
		}
	}
}
