package away3d.core.managers.mouse
{

	import away3d.arcane;
	import away3d.containers.View3D;
	import away3d.core.managers.Mouse3DManager;
	import away3d.core.raycast.colliders.picking.MouseRayCollider;
	import away3d.core.traverse.EntityCollector;

	use namespace arcane;

	public class RayMouse3DManager extends Mouse3DManager
	{
		private var _mouseRayCollider:MouseRayCollider;

		// TODO: add option of finding best hit?

		private var _findBestHit:Boolean;

		public function RayMouse3DManager( findBestHit:Boolean ) {
			super();
			_findBestHit = findBestHit;
		}

		override public function set view( view:View3D ):void {
			super.view = view;
			_mouseRayCollider = new MouseRayCollider( view, _findBestHit );
		}

		override protected function updatePicker():void {

			// Evaluate new colliding object.
			var collector:EntityCollector = _view.entityCollector;
			if( collector.numMouseEnableds > 0 ) {
				_mouseRayCollider.updateMouseRay();
				_mouseRayCollider.entities = collector.entities;
				_mouseRayCollider.evaluate();
				if( _mouseRayCollider.collides ) {
					_collidingObject = _mouseRayCollider.entity;
					_collisionPosition = _mouseRayCollider.collisionData.position;
					_collisionNormal = _mouseRayCollider.collisionData.normal;
					_collisionUV = _mouseRayCollider.collisionData.uv;
				}
				else {
					_collidingObject = null;
				}
			}
			else {
				_collidingObject = null;
			}
		}
	}
}
