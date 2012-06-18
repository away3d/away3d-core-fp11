package away3d.core.managers.mouse
{

	import away3d.arcane;
	import away3d.containers.View3D;
	import away3d.core.raycast.colliders.picking.MouseRayCollider;
	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.core.traverse.EntityCollector;

	use namespace arcane;

	public class RayMouse3DManager extends Mouse3DManager
	{
		private var _rayCollider:MouseRayCollider;

		public function RayMouse3DManager() {
			super();
		}

		override public function set view( view:View3D ):void {
			super.view = view;
			_rayCollider = new MouseRayCollider( view );
		}

		override protected function updatePicker():void {

			// Evaluate new colliding object.
			var collector:EntityCollector = _view.entityCollector;
			if( collector.numMouseEnableds > 0 ) {
				_rayCollider.updateMouseRay();
				_rayCollider.updateEntities( collector.entities );
				_rayCollider.evaluate();
				if( _rayCollider.aCollisionExists ) {
					_collidingObject = _rayCollider.firstEntity;
					var collisionData:RayCollisionVO = _rayCollider.getCollisionDataForFirstItem();
					_collisionPosition = collisionData.position;
					_collisionNormal = collisionData.normal;
					_collisionUV = collisionData.uv;
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
