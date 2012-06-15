package away3d.core.raycast.colliders.triangles
{

	import away3d.core.base.SubMesh;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	public class AutoSubMeshRayCollider extends SubMeshRayColliderBase
	{
		private var _triangleCountLimit:uint = 256; // TODO: evaluate good default value

		private var _triangleCountLimitDirty:Boolean;
		private var _pbSubMeshRayCollider:PBSubMeshRayCollider;
		private var _as3SubMeshRayCollider:AS3SubMeshRayCollider;
		private var _activeSubMeshRayCollider:SubMeshRayColliderBase;

		public function AutoSubMeshRayCollider() {
			super();
			_as3SubMeshRayCollider = new AS3SubMeshRayCollider();
			_pbSubMeshRayCollider = new PBSubMeshRayCollider();
		}

		override public function evaluate():void {
			reset();
			if( !_activeSubMeshRayCollider || _triangleCountLimitDirty ) {
				_activeSubMeshRayCollider = _subMesh.numTriangles > _triangleCountLimit ? _pbSubMeshRayCollider : _as3SubMeshRayCollider;
				_triangleCountLimitDirty = false;
			}
			_activeSubMeshRayCollider.evaluate();
			_aCollisionExists = _activeSubMeshRayCollider.aCollisionExists;
			if( _aCollisionExists ) {
				_collisionData = _activeSubMeshRayCollider.collisionData;
			}
		}

		public function set triangleCountLimit( value:uint ):void {
			if( value == _triangleCountLimit ) return;
			_triangleCountLimit = value;
			_triangleCountLimitDirty = true;
		}


		override public function updateRay( position:Vector3D, direction:Vector3D ):void {
			super.updateRay( position, direction );
			_as3SubMeshRayCollider.updateRay( position, direction );
			_pbSubMeshRayCollider.updateRay( position, direction );
		}

		override public function set subMesh( value:SubMesh ):void {
			super.subMesh = value;
			_as3SubMeshRayCollider.subMesh = value;
			_pbSubMeshRayCollider.subMesh = value;
		}

		override public function set entity( value:Entity ):void {
			super.entity = value;
			_as3SubMeshRayCollider.entity = value;
			_pbSubMeshRayCollider.entity = value;
		}

		override public function get entity():Entity {
			return _entity;
		}
	}
}
