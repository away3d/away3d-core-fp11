package away3d.core.raycast.colliders {

	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.LinkedListItem;
	import away3d.core.data.LinkedListItem;
	import away3d.core.raycast.data.MouseHitMethod;
	import away3d.core.raycast.data.RayCollisionVO;

	import flash.geom.Vector3D;

	public class MouseRayCollider extends RayColliderBase {

	private var _view:View3D;
	private var _boundsCollider:RenderableBoundsRayCollider;
	private var _triangleCollider:PBTriangleRayCollider;

    public function MouseRayCollider( view:View3D ) {
        super();
		_view = view;
		_boundsCollider = new RenderableBoundsRayCollider();
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

	override public function updateLinkedListHead( currentListItem:LinkedListItem ):void {
		super.updateLinkedListHead( currentListItem );
		_boundsCollider.updateLinkedListHead( currentListItem );
	}

    override public function evaluate():void {

		reset();

		// ---------------------------------------------------------------------
		// Filter out renderables whose bounds don't collide with ray.
		// ---------------------------------------------------------------------

		_boundsCollider.evaluate();
		if( !_boundsCollider.aCollisionExists ) return;
		else {
			_linkedListHeadItem = _boundsCollider.linkedListHeadItem;
			_collisionData = _boundsCollider.collisionData;
		}

		// ---------------------------------------------------------------------
		// Evaluate triangle collisions when needed.
		// Replaces collision data provided by bounds collider
		// with more precise data.
		// ---------------------------------------------------------------------

		var renderable:IRenderable;
		var boundsCollisionVO:RayCollisionVO;
		var renderableListItem:LinkedListItem;

		renderableListItem = _linkedListHeadItem;
		while( renderableListItem ) {

			renderable = renderableListItem.renderable;

			switch( renderable.mouseHitMethod ) {
				case MouseHitMethod.BOUNDS_ONLY:
					// Do nothing.
					break;
				case MouseHitMethod.TRIANGLE_AS3:
					// todo
					break;
				case MouseHitMethod.TRIANGLE_PIXEL_BENDER:
					// todo
					break;
				case MouseHitMethod.TRIANGLE_AUTO:
					// todo
					break;
			}

			renderableListItem = renderableListItem.next;
		}
    }
}
}
