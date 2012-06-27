package away3d.core.pick
{

	import away3d.core.raycast.colliders.RayColliderBase;
	import away3d.entities.Entity;
	import away3d.core.raycast.data.RayCollisionVO;
	import flash.utils.Dictionary;
	import away3d.arcane;
	import away3d.containers.*;
	import away3d.core.traverse.*;

	import flash.geom.*;
	
	use namespace arcane;

	public class RaycastPicker implements IPicker
	{
		private var _entity:Entity;
		
		// TODO: add option of finding best hit?

		private var _findBestHit:Boolean;
		
		protected var _entities:Vector.<Entity>;
		protected var _numberOfCollisions:uint;
		protected var _collisionDatas:Dictionary;
		protected var _collides:Boolean;
		protected var _collisionData:RayCollisionVO;
		
		public function RaycastPicker( findBestHit:Boolean ) {
			
			_findBestHit = findBestHit;
		}
		
		public function getViewCollision(x:Number, y:Number, view:View3D):PickingCollisionVO
		{
			//cast ray through the collection of entities on the view
			var collector:EntityCollector = view.entityCollector;
			
			// Evaluate new colliding object.
			if( collector.numMouseEnableds > 0 ) {
				
				//update ray
				var rayPosition:Vector3D = view.camera.scenePosition;
				var rayDirection:Vector3D = view.getRay( x, y );
				
				//set entities
				var thisEntity:Entity;
				var i:uint, len:uint;
				var filteredEntities:Vector.<Entity>;
	
				// Filter out non visibles and non mouse enableds.
				len = collector.entities.length;
				filteredEntities = new Vector.<Entity>();
				for( i = 0; i < len; i++ ) {
					thisEntity = collector.entities[ i ];
					if( thisEntity.visible && thisEntity._implicitMouseEnabled ) {
						filteredEntities.push( thisEntity );
					}
				}
				
				//reset
				_collides = false;
				_collisionData = null;
				_numberOfCollisions = 0;
				_collisionDatas = null;
				
				//evaluate
				// Perform ray-bounds collision checks.
				var thisEntityBoundsCollider:RayColliderBase;
	
				// Sweep all filtered entities.
				len = filteredEntities.length;
				_entities = new Vector.<Entity>();
				for( i = 0; i < len; i++ ) {
					// Id thisEntity.
					_entity = filteredEntities[ i ];
					// Check for bound-ray collision.
					thisEntityBoundsCollider = _entity.boundsRayCollider;
					if( thisEntityBoundsCollider ) { // Some entities may not have a bounds collider.
						// Update bounds collider.
						thisEntityBoundsCollider.entity = _entity;
						thisEntityBoundsCollider.updateRay( rayPosition, rayDirection );
						thisEntityBoundsCollider.evaluate();
						// Store collision if it exists.
						if( thisEntityBoundsCollider.collides ) {
							// Tag collision.
							_numberOfCollisions++;
							_collides = true;
							// Store collision data.
							if( _collisionDatas == null ) {
								_collisionDatas = new Dictionary();
							}
							_collisionDatas[ _entity ] = thisEntityBoundsCollider.collisionData;
							// Store in new data set.
							_entities.push( _entity );
						}
					}
				}
	
				// Sort entities from closest to furthest.
				// TODO: Instead of sorting the array, create it one item at a time in a sorted manner.
				// Note: EntityCollector does provide the entities with some sorting, its not random, make use of that.
				// However, line up collision test shows that the current implementation isn't too bad.
				if( _numberOfCollisions > 1 ) {
					_entities = _entities.sort( sortOnNearT );
				}
				
				// If a collision exists, extract the data from the bounds collider...
				if( _collides ) {
					// The bounds collider has filtered and populated its data, use it here from now on.
					_entity = _entities[ 0 ];
					_collisionData = _collisionDatas[ _entity ];
				
		
					// ---------------------------------------------------------------------
					// Evaluate triangle collisions when needed.
					// Replaces collision data provided by bounds collider with more precise data.
					// ---------------------------------------------------------------------
		
					if( _numberOfCollisions > 0 ) {
		
						// does not search for closest collision, first found will do... // TODO: implement _findBestHit
						// Example: Bound B is inside bound A. Bound A's collision t is closer than bound B. Both have tri colliders. Bound A surface hit
						// is further than bound B surface hit. Atm, this algorithm would fail in detecting that B's surface hit is actually closer.
						// Suggestions: calculate ray bounds near and far t's and evaluate bound intersections within ray trajectory.
						
						var triangleCollider:RayColliderBase;
		
						for( i = 0; i < _numberOfCollisions; ++i ) {
							_entity = _entities[ i ];
							_collisionData = _collisionDatas[ _entity ];
							triangleCollider = _entity.triangleRayCollider;
							if( triangleCollider ) {
								// Update triangle collider.
								triangleCollider.entity = _entity;
								triangleCollider.updateRay( rayPosition, rayDirection );
								triangleCollider.evaluate();
								// If a collision exists, update the collision data and stop all checks.
								if( triangleCollider.collides ) {
									_collisionData = triangleCollider.collisionData;
									_collides = true;
									break;
								}
								else { // A failed triangle collision check discards the collision.
									_entities.splice( i, 1 );
									_numberOfCollisions--;
									if( _numberOfCollisions == 0 ) {
										_collides = false;
									}
									i--;
								}
							}
							else { // A bounds collision with no triangle collider stops all checks.
								_collides = true;
								break;
							}
						}
					}
				}
				
				
				if( _collides ) {
					var _collisionVO:PickingCollisionVO = _entity.pickingCollisionVO;
					_collisionVO.localPosition = _collisionData.position;
					_collisionVO.localNormal = _collisionData.normal;
					_collisionVO.uv = _collisionData.uv;
					
					return _collisionVO;
				} else {
					return null;
				}
			}
			else {
				return null;
			}
		}
		
		public function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO
		{
			//cast ray through the scene
			
			// Evaluate new colliding object.
			return null;
		}
		
		private function sortOnNearT( entity1:Entity, entity2:Entity ):Number {
			var collisionVO1:RayCollisionVO = _collisionDatas[ entity1 ];
			var collisionVO2:RayCollisionVO = _collisionDatas[ entity2 ];
			return collisionVO1.t > collisionVO2.t ? 1 : -1;
		}
	}
}
