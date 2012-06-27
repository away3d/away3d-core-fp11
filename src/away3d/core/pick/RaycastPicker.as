package away3d.core.pick
{

	import away3d.arcane;
	import away3d.containers.*;
	import away3d.core.raycast.colliders.picking.*;
	import away3d.core.traverse.*;

	import flash.geom.*;
	
	use namespace arcane;

	public class RaycastPicker implements IPicker
	{
		private var _mouseRayCollider:MouseRayCollider;
		
		// TODO: add option of finding best hit?

		private var _findBestHit:Boolean;
		
		public var position : Vector3D;
		
		public var direction : Vector3D;
		
		public function RaycastPicker( findBestHit:Boolean ) {
			
			_findBestHit = findBestHit;
			_mouseRayCollider = new MouseRayCollider(findBestHit);
		}
		
		public function getViewCollision(x:Number, y:Number, view:View3D):PickingCollisionVO
		{
			//cast ray through the collection of entities on the view
			var collector:EntityCollector = view.entityCollector;
			
			
			// Evaluate new colliding object.
			if( collector.numMouseEnableds > 0 ) {
				_mouseRayCollider.updateMouseRay(view);
				_mouseRayCollider.entities = collector.entities;
				_mouseRayCollider.evaluate();
				if( _mouseRayCollider.collides ) {
					var _collisionVO:PickingCollisionVO = _mouseRayCollider.entity.pickingCollisionVO;
					_collisionVO.localPosition = _mouseRayCollider.collisionData.position;
					_collisionVO.localNormal = _mouseRayCollider.collisionData.normal;
					_collisionVO.uv = _mouseRayCollider.collisionData.uv;
					
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
	}
}
