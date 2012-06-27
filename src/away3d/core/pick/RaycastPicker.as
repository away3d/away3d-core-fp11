package away3d.core.pick
{

	import away3d.core.base.SubMesh;
	import away3d.arcane;
	import away3d.containers.*;
	import away3d.core.traverse.*;
	import away3d.entities.*;

	import flash.geom.*;
	
	use namespace arcane;

	public class RaycastPicker implements IPicker
	{
		private var _entity:Entity;
		
		// TODO: add option of finding best hit?

		private var _findBestHit:Boolean;
		
		protected var _entities:Vector.<Entity>;
		protected var _numberOfCollisions:uint;
		protected var _collides:Boolean;
		protected var _pickingCollisionVO:PickingCollisionVO;
		
		public function RaycastPicker( findBestHit:Boolean ) {
			
			_findBestHit = findBestHit;
		}
		
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
			var collisionT:Number;
			var rayOriginIsInsideBounds:Boolean;
			
			// Sweep all filtered entities.
			len = filteredEntities.length;
			_entities = new Vector.<Entity>();
			for( i = 0; i < len; i++ ) {
				// Id thisEntity.
				_entity = filteredEntities[ i ];
				
				// convert ray to entity space
				localRayPosition = _entity.inverseSceneTransform.transformVector( rayPosition );
				localRayDirection = _entity.inverseSceneTransform.deltaTransformVector( rayDirection );
	
				// check for ray-bounds collision
				collisionT = _entity.bounds.intersectsRay( localRayPosition, localRayDirection );
	
				// accept cases on which the ray starts inside the bounds
				rayOriginIsInsideBounds = false;
				if( collisionT == -1 ) {
					rayOriginIsInsideBounds = _entity.bounds.containsPoint( localRayPosition );
					if( rayOriginIsInsideBounds ) {
						collisionT = 0;
					}
				}
	
				if( collisionT >= 0 ) {
	
					_collides = true;
					_numberOfCollisions++;
					
					// Store collision data.
					_pickingCollisionVO = _entity.pickingCollisionVO;
					_pickingCollisionVO.collisionT = collisionT;
					_pickingCollisionVO.localRayPosition = localRayPosition;
					_pickingCollisionVO.localRayDirection = localRayDirection;
					_pickingCollisionVO.rayOriginIsInsideBounds = rayOriginIsInsideBounds;
					_pickingCollisionVO.localPosition = _entity.bounds.rayIntersectionPoint;
					_pickingCollisionVO.localNormal = _entity.bounds.rayIntersectionNormal;
					
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
			
			// does not search for closest collision, first found will do... // TODO: implement _findBestHit
			// Example: Bound B is inside bound A. Bound A's collision t is closer than bound B. Both have tri colliders. Bound A surface hit
			// is further than bound B surface hit. Atm, this algorithm would fail in detecting that B's surface hit is actually closer.
			// Suggestions: calculate ray bounds near and far t's and evaluate bound intersections within ray trajectory.
			
			var pickingCollider:IPickingCollider;

			for( i = 0; i < _numberOfCollisions; ++i ) {
				_entity = _entities[ i ];
				_pickingCollisionVO = _entity.pickingCollisionVO;
				pickingCollider = _entity.pickingCollider;
				if( pickingCollider) {
					// If a collision exists, update the collision data and stop all checks.
					if( testCollision( pickingCollider, _pickingCollisionVO ) )
						return _pickingCollisionVO;
				} else { // A bounds collision with no triangle collider stops all checks.
					return _pickingCollisionVO;
				}
			}
			
			return null;
		}
		
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
		
		private function testCollision(pickingCollider:IPickingCollider, pickingCollisionVO:PickingCollisionVO):Boolean
		{
			pickingCollider.setLocalRay(pickingCollisionVO.localRayPosition, pickingCollisionVO.localRayDirection);
			
			if (pickingCollisionVO.entity is Mesh) {
				var mesh:Mesh = pickingCollisionVO.entity as Mesh;
				var subMesh:SubMesh;
				for each (subMesh in mesh.subMeshes)
					if (pickingCollider.testSubMeshCollision(subMesh, pickingCollisionVO))
						return true;
			} else {
				//if not a mesh, rely on entity bounds
				return true;
			}
			
			return false;
		}
	}
}
