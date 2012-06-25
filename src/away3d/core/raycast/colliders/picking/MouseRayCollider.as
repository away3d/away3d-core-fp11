package away3d.core.raycast.colliders.picking
{

	import away3d.arcane;
	import away3d.containers.View3D;
	import away3d.core.raycast.colliders.*;
	import away3d.core.raycast.colliders.bounds.MultipleBoundsRayCollider;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class MouseRayCollider extends MultipleRayColliderBase
	{
		private var _view:View3D;
		private var _multipleBoundsCollider:MultipleBoundsRayCollider;

		private var _findBestHit:Boolean;

		// TODO: implement _findBestHit

		public function MouseRayCollider( view:View3D, findBestHit:Boolean ) {
			super();
			_view = view;
			_multipleBoundsCollider = new MultipleBoundsRayCollider();
			_findBestHit = findBestHit;
		}

		public function updateMouseRay():void {
			var rayPosition:Vector3D = _view.camera.scenePosition;
			var rayDirection:Vector3D = _view.getRay( _view.mouseX, _view.mouseY );
			updateRay( rayPosition, rayDirection );
		}

		override public function updateRay( position:Vector3D, direction:Vector3D ):void {
			super.updateRay( position, direction );
			_multipleBoundsCollider.updateRay( position, direction );
		}

		override public function set entities( entities:Vector.<Entity> ):void {

			var thisEntity:Entity;
			var i:uint, len:uint;
			var filteredEntities:Vector.<Entity>;

			// Filter out non visibles and non mouse enableds.
			len = entities.length;
			filteredEntities = new Vector.<Entity>();
			for( i = 0; i < len; i++ ) {
				thisEntity = entities[ i ];
				if( thisEntity.visible && thisEntity._implicitlyMouseEnabled ) {
					filteredEntities.push( thisEntity );
				}
			}

			// Set the filtered items onto the bounds collider.
			_multipleBoundsCollider.entities = filteredEntities;
		}

		override public function evaluate():void {

			reset();

			// ---------------------------------------------------------------------
			// Filter out renderables whose bounds don't collide with ray.
			// ---------------------------------------------------------------------

			// Perform ray-bounds collision checks.
			_multipleBoundsCollider.evaluate();

			// If a collision exists, extract the data from the bounds collider...
			if( _multipleBoundsCollider.collides ) {
				// The bounds collider has filtered and populated its data, use it here from now on.
				_entities = _multipleBoundsCollider.entities;
				_collisionDatas = _multipleBoundsCollider.collisionDatas;
				_numberOfCollisions = _multipleBoundsCollider.numberOfCollisions;
				_collides = true;
				_entity = _entities[ 0 ];
				_collisionData = _collisionDatas[ _entity ];
			}
			else {
				// Break if no bounds are hit.
				return;
			}

			// ---------------------------------------------------------------------
			// Evaluate triangle collisions when needed.
			// Replaces collision data provided by bounds collider with more precise data.
			// ---------------------------------------------------------------------

			if( _numberOfCollisions > 0 ) {

				// does not search for closest collision, first found will do... // TODO: implement _findBestHit
				// Example: Bound B is inside bound A. Bound A's collision t is closer than bound B. Both have tri colliders. Bound A surface hit
				// is further than bound B surface hit. Atm, this algorithm would fail in detecting that B's surface hit is actually closer.
				// Suggestions: calculate ray bounds near and far t's and evaluate bound intersections within ray trajectory.

				var i:uint;
				var triangleCollider:RayColliderBase;

				for( i = 0; i < _numberOfCollisions; ++i ) {
					_entity = _entities[ i ];
					_collisionData = _collisionDatas[ _entity ];
					triangleCollider = _entity.triangleRayCollider;
					if( triangleCollider ) {
						// Update triangle collider.
						triangleCollider.entity = _entity;
						triangleCollider.updateRay( _rayPosition, _rayDirection );
						triangleCollider.evaluate();
						// If a collision exists, update the collision data and stop all checks.
						if( triangleCollider.collides ) {
							_collisionData = triangleCollider.collisionData;
							_collides = true;
							return;
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
						return;
					}
				}
			}
		}
	}
}
