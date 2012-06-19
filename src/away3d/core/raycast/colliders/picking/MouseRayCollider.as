package away3d.core.raycast.colliders.picking {

	import away3d.arcane;
	import away3d.containers.View3D;
	import away3d.core.raycast.colliders.*;
	import away3d.core.raycast.colliders.bounds.MultipleBoundsRayCollider;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class MouseRayCollider extends RayColliderBase {

	private var _view:View3D;
	private var _multipleBoundsCollider:MultipleBoundsRayCollider;

    public function MouseRayCollider( view:View3D ) {
        super();
		_view = view;
		_multipleBoundsCollider = new MultipleBoundsRayCollider();
    }

	public function updateMouseRay():void {
		var rayPosition:Vector3D = _view.camera.scenePosition;
		var rayDirection:Vector3D = _view.getRay(_view.mouseX, _view.mouseY);
		updateRay( rayPosition, rayDirection );
	}

	override public function updateRay( position:Vector3D, direction:Vector3D ):void {
		super.updateRay( position, direction );
		_multipleBoundsCollider.updateRay( position, direction );
	}

	override public function updateEntities( entities:Vector.<Entity> ):void {

		var entity:Entity;
		var i:uint, len:uint;
		var filteredEntities:Vector.<Entity>;

		// Filter out non visibles and non mouse enableds.
		len = entities.length;
		filteredEntities = new Vector.<Entity>();
		for( i = 0; i < len; i++ ) {
			entity = entities[ i ];
//			trace( "MouseRayManager - received entity of name: " + entity.name + "." );
			if( entity.visible && entity._implicitlyMouseEnabled ) {
				filteredEntities.push( entity );
			}
		}

		// Set the filtered items onto the bounds collider.
		_multipleBoundsCollider.updateEntities( filteredEntities );
	}

    override public function evaluate():void {

		var i:uint;
		var entity:Entity;
		var triangleCollider:RayColliderBase;

		reset();

		// ---------------------------------------------------------------------
		// Filter out renderables whose bounds don't collide with ray.
		// ---------------------------------------------------------------------

		// Perform ray-bounds collision checks.
		_multipleBoundsCollider.evaluate();

		// If a collision exists, extract the data from the bounds collider...
		if( _multipleBoundsCollider.aCollisionExists ) {
			// The bounds collider has filtered and populated its data, use it here from now on.
			_entities = _multipleBoundsCollider.entities;
			_collisionData = _multipleBoundsCollider.collisionData;
			_numberOfCollisions = _multipleBoundsCollider.numberOfCollisions;
		}
		else return;

		// ---------------------------------------------------------------------
		// Evaluate triangle collisions when needed.
		// Replaces collision data provided by bounds collider
		// with more precise data.
		// ---------------------------------------------------------------------

		for( i = 0; i < _numberOfCollisions; ++i ) {
			entity = _entities[ i ];
			trace( "entity '" + entity.name + "' passed bounds collision test." );
			triangleCollider = entity.triangleRayCollider;
			if( triangleCollider ) {
				// Update triangle collider.
				triangleCollider.setEntityAt( 0, entity );
				triangleCollider.updateRay( _rayPosition, _rayDirection );
				triangleCollider.evaluate();
				// If a collision exists, update the collision data and stop all checks.
				trace( "tested triangle collision on entity '" + entity.name + "', " + triangleCollider.aCollisionExists );
				if( triangleCollider.aCollisionExists ) {
					setCollisionDataForItem( entity, triangleCollider.getCollisionDataForFirstItem() );
					_aCollisionExists = true;
					return;
				}
				else { // A failed triangle collision check discards the collision.
					_entities.splice( i, 1 );
					_numberOfCollisions--;
					if( _numberOfCollisions == 0 ) {
						_aCollisionExists = false;
					}
					i--;
				}
			}
			else { // A bounds collision with no triangle collider stops all checks.
				_aCollisionExists = true;
				return;
			}
		}
    }
}
}
