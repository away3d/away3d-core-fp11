package away3d.core.pick
{

	import away3d.core.base.IRenderable;
	import away3d.entities.*;
	
	import flash.geom.*;
	
	/**
	 * Value object for a picking collision returned by a picking collider. Created as unique objects on entities
	 * 
	 * @see away3d.entities.Entity#pickingCollisionVO
	 * @see away3d.core.pick.IPickingCollider
	 */
	public class PickingCollisionVO
	{
		/**
		 * The entity to which this collision object belongs.
		 */
		public var entity:Entity;
		
		/**
		 * The local position of the collision on the entity's surface.
		 */
		public var localPosition:Vector3D;
		
		/**
		 * The local normal vector at the position of the collision.
		 */
		public var localNormal:Vector3D;
		
		/**
		 * The uv coordinate at the position of the collision.
		 */
		public var uv:Point;
		
		/**
		 * The starting position of the colliding ray in local coordinates.
		 */
		public var localRayPosition:Vector3D;
		
		/**
		 * The direction of the colliding ray in local coordinates.
		 */		
		public var localRayDirection:Vector3D;

		/**
		 * The starting position of the colliding ray in scene coordinates.
		 */
		public var rayPosition:Vector3D;

		/**
		 * The direction of the colliding ray in scene coordinates.
		 */
		public var rayDirection:Vector3D;
		
		/**
		 * Determines if the ray position is contained within the entity bounds.
		 * 
		 * @see away3d.entities.Entity#bounds
		 */
		public var rayOriginIsInsideBounds:Boolean;
		
		/**
		 * The distance along the ray from the starting position to the calculated intersection entry point with the entity.
		 */
		public var rayEntryDistance:Number;

		/**
		 * The IRenderable associated with a collision.
		 */
		public var renderable:IRenderable;

		/**
		 * Creates a new <code>PickingCollisionVO</code> object.
		 * 
		 * @param entity The entity to which this collision object belongs.
		 */
		function PickingCollisionVO(entity:Entity)
		{
			this.entity = entity;
		}
	}
}
