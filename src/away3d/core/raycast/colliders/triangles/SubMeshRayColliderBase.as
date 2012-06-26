package away3d.core.raycast.colliders.triangles
{

	import away3d.core.base.SubMesh;
	import away3d.core.raycast.colliders.RayColliderBase;

	public class SubMeshRayColliderBase extends RayColliderBase
	{
		protected var _subMesh:SubMesh;

		protected var _uvData:Vector.<Number>;
		protected var _indexData:Vector.<uint>;
		protected var _vertexData:Vector.<Number>;

		protected var _findBestHit:Boolean;

		public function SubMeshRayColliderBase( findBestHit:Boolean ) {
			_findBestHit = findBestHit;
			super();
		}

		public function set subMesh( value:SubMesh ):void {
			_subMesh = value;
		}
	}
}
