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
		public static const AS3_TRIANGLE_HIT:RayColliderBase = new MeshRayCollider( new AS3SubMeshRayCollider() );
		public static const PB_TRIANGLE_HIT:RayColliderBase = new MeshRayCollider( new PBSubMeshRayCollider() );
		public static const AUTO_TRIANGLE_HIT:RayColliderBase = new MeshRayCollider( new AutoSubMeshRayCollider() );
	}
}
