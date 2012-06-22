package away3d.core.raycast.colliders.picking
{
	import away3d.core.raycast.colliders.RayColliderBase;
	import away3d.core.raycast.colliders.triangles.AS3SubMeshRayCollider;
	import away3d.core.raycast.colliders.triangles.AutoSubMeshRayCollider;
	import away3d.core.raycast.colliders.triangles.MeshRayCollider;
	import away3d.core.raycast.colliders.triangles.PBSubMeshRayCollider;

	public class CpuPickingMethod
	{
		public static const BOUNDS_ONLY:RayColliderBase = null;
		public static const LOW_POLY_MESH:RayColliderBase = new MeshRayCollider( new AS3SubMeshRayCollider( false ), false );
		public static const LOW_POLY_MESH_1:RayColliderBase = new MeshRayCollider( new AS3SubMeshRayCollider( false ), true );
		public static const LOW_POLY_MESH_2:RayColliderBase = new MeshRayCollider( new AS3SubMeshRayCollider( true ), true );
		public static const LOW_POLY_MESH_3:RayColliderBase = new MeshRayCollider( new AS3SubMeshRayCollider( true ), false );
		public static const HIGH_POLY_MESH:RayColliderBase = new MeshRayCollider( new PBSubMeshRayCollider( false ), false );
		public static const HIGH_POLY_MESH_1:RayColliderBase = new MeshRayCollider( new PBSubMeshRayCollider( false ), true );
		public static const HIGH_POLY_MESH_2:RayColliderBase = new MeshRayCollider( new PBSubMeshRayCollider( false ), true );
		public static const HIGH_POLY_MESH_3:RayColliderBase = new MeshRayCollider( new PBSubMeshRayCollider( false ), true );
		public static const AUTO_MESH:RayColliderBase = new MeshRayCollider( new AutoSubMeshRayCollider( false ), false );
		public static const AUTO_MESH_1:RayColliderBase = new MeshRayCollider( new AutoSubMeshRayCollider( false ), true );
		public static const AUTO_MESH_2:RayColliderBase = new MeshRayCollider( new AutoSubMeshRayCollider( true ), true );
		public static const AUTO_MESH_3:RayColliderBase = new MeshRayCollider( new AutoSubMeshRayCollider( true ), false );
	}
}
