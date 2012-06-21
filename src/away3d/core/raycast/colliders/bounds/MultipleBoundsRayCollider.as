package away3d.core.raycast.colliders.bounds
{

	import away3d.core.raycast.colliders.*;

	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Entity;

	public class MultipleBoundsRayCollider extends MultipleRayColliderBase
	{
		public function MultipleBoundsRayCollider() {
			super();
		}

		override public function evaluate():void {

			reset();

			// ---------------------------------------------------------------------
			// Produce a new list of items whose bounds collide with the ray,
			// and calculate collision data.
			// ---------------------------------------------------------------------

			var i:uint, len:uint;
			var filteredEntities:Vector.<Entity>;
			var thisEntityBoundsCollider:RayColliderBase;

			// Sweep all entities.
			len = _entities.length;
			filteredEntities = new Vector.<Entity>();
			for( i = 0; i < len; i++ ) {
				// Id thisEntity.
				_entity = _entities[ i ];
				// Check for bound-ray collision.
				thisEntityBoundsCollider = _entity.boundsRayCollider;
				if( thisEntityBoundsCollider ) { // Some entities may not have a bounds collider.
					// Update bounds collider.
					thisEntityBoundsCollider.entity = _entity;
					thisEntityBoundsCollider.updateRay( _rayPosition, _rayDirection );
					thisEntityBoundsCollider.evaluate();
					// Store collision if it exists.
					if( thisEntityBoundsCollider.collides ) {
						// Tag collision.
						_numberOfCollisions++;
						_collides = true;
						// Store collision data.
						addCollisionDataForEntity( _entity, thisEntityBoundsCollider.collisionData );
						// Store in new data set.
						filteredEntities.push( _entity );
					}
				}
			}

			// Sort filtered entities from closest to furthest.
			// TODO: Instead of sorting the array, create it one item at a time in a sorted manner.
			if( _numberOfCollisions > 1 ) {
				filteredEntities = filteredEntities.sort( sortOnNearT );
			}

			// Replace data.
			_entities = filteredEntities;
		}

		private function sortOnNearT( entity1:Entity, entity2:Entity ):Number {
			var collisionVO1:RayCollisionVO = _collisionDatas[ entity1 ];
			var collisionVO2:RayCollisionVO = _collisionDatas[ entity2 ];
			return collisionVO1.nearT > collisionVO2.nearT ? 1 : -1;
		}
	}
}
