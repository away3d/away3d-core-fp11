package away3d.core.pick
{
	import away3d.entities.IEntity;

	import flash.geom.Vector3D;
	
	/**
	 * Provides an interface for picking colliders that can be assigned to individual entities in a scene for specific picking behaviour.
	 * Used with the <code>RaycastPicker</code> picking object.
	 *
	 * @see away3d.entities.Entity#pickingCollider
	 * @see away3d.core.pick.RaycastPicker
	 */
	public interface IPickingCollider
	{
		/**
		 * Sets the position and direction of a picking ray in local coordinates to the entity.
		 *
		 * @param localDirection The position vector in local coordinates
		 * @param localPosition The direction vector in local coordinates
		 */
		function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):void;

		/**
		 * Tests a <code>Billboard</code> object for a collision with the picking ray.
		 *
		 * @param entity The entity instance to be tested.
		 * @param pickingCollisionVO The collision object used to store the collision results
		 * @param shortestCollisionDistance The current value of the shortest distance to a detected collision along the ray.
		 */
		function testBillboardCollision(entity:IEntity, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number):Boolean

		/**
		 * Tests a <code>SubMesh</code> object for a collision with the picking ray.
		 *
		 * @param entity The entity instance to be tested.
		 * @param pickingCollisionVO The collision object used to store the collision results
		 * @param shortestCollisionDistance The current value of the shortest distance to a detected collision along the ray.
		 * @param findClosest
		 */
		function testMeshCollision(entity:IEntity, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number, findClosest:Boolean):Boolean;
	}
}
