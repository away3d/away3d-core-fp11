package away3d.core.pick
{
	/**
	 * Options for setting a picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
	 * 
	 * @see away3d.entities.Entity#pickingCollider
	 * @see away3d.core.pick.RaycastPicker
	 */
	public class PickingColliderType
	{
		/**
		 * Default null collider that forces picker to only use entity bounds for hit calculations on an Entity
		 */
		public static const BOUNDS_ONLY:IPickingCollider = null;
		
		/**
		 * Pure AS3 picking collider that returns the first encountered hit on an Entity
		 */
		public static const AS3_FIRST_ENCOUNTERED:IPickingCollider = new AS3PickingCollider( false );
		
		/**
		 * Pure AS3 picking collider that returns the best (closest) hit on an Entity
		 */
		public static const AS3_BEST_HIT:IPickingCollider = new AS3PickingCollider( true );
		
		/**
		 * PixelBender-based picking collider that returns the first encountered hit on an Entity
		 */
		public static const PB_FIRST_ENCOUNTERED:IPickingCollider = new PBPickingCollider( false );
		public static const PB_BEST_HIT:IPickingCollider = new PBPickingCollider( true );
		
		/**
		 * Auto-selecting picking collider that returns the first encountered hit on an Entity
		 */
		public static const AUTO_FIRST_ENCOUNTERED:IPickingCollider = new AutoPickingCollider( false );
		
		/**
		 * Auto-selecting picking collider that returns the best (closest) hit on an Entity
		 */
		public static const AUTO_BEST_HIT:IPickingCollider = new AutoPickingCollider( true );
	}
}
