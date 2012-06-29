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
		 * Pure AS3 picking collider that returns the first encountered hit on an Entity. Useful for low poly meshes and applying to many mesh instances.
		 * 
		 * @see away3d.core.pick.AS3PickingCollider
		 */
		public static const AS3_FIRST_ENCOUNTERED:IPickingCollider = new AS3PickingCollider( false );
		
		/**
		 * Pure AS3 picking collider that returns the best (closest) hit on an Entity. Useful for low poly meshes and applying to many mesh instances.
		 * 
		 * @see away3d.core.pick.AS3PickingCollider
		 */
		public static const AS3_BEST_HIT:IPickingCollider = new AS3PickingCollider( true );
		
		/**
		 * PixelBender-based picking collider that returns the first encountered hit on an Entity. Useful for fast picking high poly meshes on desktop devices.
		 * 
		 * @see away3d.core.pick.PBPickingCollider
		 */
		public static const PB_FIRST_ENCOUNTERED:IPickingCollider = new PBPickingCollider( false );
				
		/**
		 * PixelBender-based picking collider that returns the best (closest) hit on an Entity. Useful for fast picking high poly meshes on desktop devices.
		 * 
		 * @see away3d.core.pick.PBPickingCollider
		 */
		public static const PB_BEST_HIT:IPickingCollider = new PBPickingCollider( true );
		
		/**
		 * Auto-selecting picking collider that returns the first encountered hit on an Entity.
		 * Chooses between pure AS3 picking and PixelBender picking based on a threshold property representing
		 * the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
		 * Useful for picking meshes with a mixture of polycounts.
		 * 
		 * @see away3d.core.pick.AutoPickingCollider
		 * @see away3d.core.pick.AutoPickingCollider#triangleThreshold
		 */
		public static const AUTO_FIRST_ENCOUNTERED:IPickingCollider = new AutoPickingCollider( false );
		
		/**
		 * Auto-selecting picking collider that returns the best (closest) hit on an Entity
		 * Chooses between pure AS3 picking and PixelBender picking based on a threshold property representing 
		 * the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
		 * Useful for picking meshes with a mixture of polycounts.
		 * 
		 * @see away3d.core.pick.AutoPickingCollider
		 * @see away3d.core.pick.AutoPickingCollider#triangleThreshold
		 */
		public static const AUTO_BEST_HIT:IPickingCollider = new AutoPickingCollider( true );
	}
}
