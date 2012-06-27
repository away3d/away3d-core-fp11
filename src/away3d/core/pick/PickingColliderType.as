package away3d.core.pick
{
	public class PickingColliderType
	{
		// TODO: split entity pickingMethod into meshPickingMethod and subMeshPickingMethod? Allows to choose MeshRayCollider and SubMeshRayCollider separately,
		// resulting in less options. Does not allow for the merge with gpu picking methods.
		public static const BOUNDS_ONLY:IPickingCollider = null;
		
		public static const AS3_FIRST_ENCOUNTERED:IPickingCollider = new AS3PickingCollider( false );
		public static const AS3_BEST_HIT:IPickingCollider = new AS3PickingCollider( true );

		public static const PB_FIRST_ENCOUNTERED:IPickingCollider = new PBPickingCollider( false );
		public static const PB_BEST_HIT:IPickingCollider = new PBPickingCollider( true );

		public static const AUTO_FIRST_ENCOUNTERED:IPickingCollider = new AutoPickingCollider( false );
		public static const AUTO_BEST_HIT:IPickingCollider = new AutoPickingCollider( true );
	}
}
