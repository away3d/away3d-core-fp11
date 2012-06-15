package away3d.core.raycast.colliders.triangles
{

	import away3d.core.base.SubMesh;
	import away3d.core.raycast.colliders.RayColliderBase;
	import away3d.entities.Entity;

	public class SubMeshRayColliderBase extends RayColliderBase
	{
		protected var _entity:Entity;
		protected var _subMesh:SubMesh;

		protected var _uvData:Vector.<Number>;
		protected var _indexData:Vector.<uint>;
		protected var _vertexData:Vector.<Number>;

		public function SubMeshRayColliderBase() {
			super();
		}

		public function set subMesh( value:SubMesh ):void {
			_subMesh = value;
		}

		public function set entity( value:Entity ):void {
			_entity = value;
		}

		public function get entity():Entity {
			return _entity;
		}
	}
}
