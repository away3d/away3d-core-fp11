package away3d.core.pick
{
	import away3d.core.base.*;
	
	import flash.geom.*;
	
	/**
	 * Auto-selecting picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
	 * Chooses between pure AS3 picking and PixelBender picking based on a threshold property representing
	 * the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
	 * 
	 * @see away3d.entities.Entity#pickingCollider
	 * @see away3d.core.pick.RaycastPicker
	 */
	public class AutoPickingCollider implements IPickingCollider
	{
		private var _pbPickingCollider:PBPickingCollider;
		private var _as3PickingCollider:AS3PickingCollider;
		private var _activePickingCollider:IPickingCollider;
		
		/**
		 * Represents the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
		 */
		public var triangleThreshold:uint = 1024;
		
		/**
		 * Creates a new <code>AutoPickingCollider</code> object.
		 * 
		 * @param findClosestCollision Determines whether the picking collider searches for the closest collision along the ray. Defaults to false.
		 */
		public function AutoPickingCollider( findClosestCollision:Boolean = false )
		{
			_as3PickingCollider = new AS3PickingCollider( findClosestCollision );
			_pbPickingCollider = new PBPickingCollider( findClosestCollision );
		}
		
		/**
		 * @inheritDoc
		 */
		public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):void
		{
			_as3PickingCollider.setLocalRay(localPosition, localDirection);
			_pbPickingCollider.setLocalRay(localPosition, localDirection);
		}
		
		/**
		 * @inheritDoc
		 */
		public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number):Boolean
		{
			_activePickingCollider = (subMesh.numTriangles > triangleThreshold)? _pbPickingCollider : _as3PickingCollider;
			return _activePickingCollider.testSubMeshCollision(subMesh, pickingCollisionVO, shortestCollisionDistance);
		}
	}
}
