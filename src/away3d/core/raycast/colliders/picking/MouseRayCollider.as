package away3d.core.raycast.colliders.picking
{

	import away3d.arcane;
	import away3d.containers.View3D;
	import away3d.core.raycast.colliders.*;
	import away3d.core.raycast.colliders.bounds.MultipleBoundsRayCollider;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	use namespace arcane;

	public class MouseRayCollider extends MultipleRayColliderBase
	{
		private var _view:View3D;
		private var _multipleBoundsCollider:MultipleBoundsRayCollider;

		public function MouseRayCollider( view:View3D ) {
			super();
			_view = view;
			_multipleBoundsCollider = new MultipleBoundsRayCollider();
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
			var time:uint = getTimer(); // TODO: remove
			_multipleBoundsCollider.evaluate();
			time = getTimer() - time; // TODO: remove
			trace( "checked bound collisions in " + time + "ms." ); // TODO: remove

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

				// TODO: must consider bounds intersections.

				var i:uint;
				var triangleCollider:RayColliderBase;

				for( i = 0; i < _numberOfCollisions; ++i ) {
					_entity = _entities[ i ];
					_collisionData = _collisionDatas[ _entity ];
					triangleCollider = _entity.triangleRayCollider;
					if( triangleCollider ) {
						trace( "initiating thisEntity triangle collision check..." );
						time = getTimer(); // TODO: remove
						// Update triangle collider.
						triangleCollider.entity = _entity;
						triangleCollider.updateRay( _rayPosition, _rayDirection );
						triangleCollider.evaluate();
						// If a collision exists, update the collision data and stop all checks.
						if( triangleCollider.collides ) {
							_collisionData = triangleCollider.collisionData;
							_collides = true;
							time = getTimer() - time; // TODO: remove
							trace( "checked triangle collisions in " + time + "ms." ); // TODO: remove
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
						time = getTimer() - time; // TODO: remove
						trace( "checked triangle collisions in " + time + "ms." ); // TODO: remove
						return;
					}
				}
				time = getTimer() - time; // TODO: remove
				trace( "checked triangle collisions in " + time + "ms." ); // TODO: remove
			}
		}
	}
}
