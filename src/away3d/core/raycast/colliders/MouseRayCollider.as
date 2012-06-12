package away3d.core.raycast.colliders {

	import away3d.containers.View3D;
	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	public class MouseRayCollider extends RayColliderBase {

	private var _view:View3D;
	private var _boundsCollider:MultipleBoundsRayCollider;
	private var _triangleCollider:PBTriangleRayCollider;

    public function MouseRayCollider( view:View3D ) {
        super();
		_view = view;
		_boundsCollider = new MultipleBoundsRayCollider();
        _triangleCollider = new PBTriangleRayCollider();
    }

	public function updateMouseRay():void {
		var rayPosition:Vector3D = _view.camera.position;
		var rayDirection:Vector3D = _view.unproject( _view.mouseX, _view.mouseY );
		updateRay( rayPosition, rayDirection );
	}

	override public function updateRay( position:Vector3D, direction:Vector3D ):void {
		super.updateRay( position, direction );
		_boundsCollider.updateRay( position, direction );
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
			if( entity.visible && entity.mouseEnabled ) {
				filteredEntities.push( entity );
			}
		}

		// Set the filtered items onto the bounds collider.
		_boundsCollider.updateEntities( filteredEntities );
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
		_boundsCollider.evaluate();

		// If a collision exists, extract the data from the bounds collider...
		if( _boundsCollider.aCollisionExists ) {
			// The bounds collider has filtered and populated its data, use it here from now on.
			_entities = _boundsCollider.entities;
			_collisionData = _boundsCollider.collisionData;
			_numberOfCollisions = _boundsCollider.numberOfCollisions;
		}
		else return;

		// ---------------------------------------------------------------------
		// Evaluate triangle collisions when needed.
		// Replaces collision data provided by bounds collider
		// with more precise data.
		// ---------------------------------------------------------------------

		for( i = 0; i < _numberOfCollisions; ++i ) {
			entity = _entities[ i ];
			triangleCollider = entity.triangleRayCollider;
			if( triangleCollider ) {
				// Update triangle collider.
				triangleCollider.setEntityAt( 0, entity );
				triangleCollider.updateRay( _rayPosition, _rayDirection );
				triangleCollider.evaluate();
				// If a collision exists, update the collision data and stop all checks.
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
