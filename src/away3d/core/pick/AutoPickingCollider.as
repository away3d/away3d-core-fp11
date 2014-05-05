package away3d.core.pick
{
	import away3d.entities.Billboard;
	import away3d.entities.IEntity;
	import away3d.entities.Mesh;

	import flash.geom.Vector3D;

	/**
	 * Auto-selecting picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
	 * Chooses between pure AS3 picking and PixelBender picking basesd on a threshold property repreenting
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
		public function AutoPickingCollider(findClosestCollision:Boolean = false)
		{
			_as3PickingCollider = new AS3PickingCollider(findClosestCollision);
			_pbPickingCollider = new PBPickingCollider(findClosestCollision);
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
		public function testMeshCollision(entity:IEntity, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			var mesh:Mesh = entity as Mesh;
			_activePickingCollider = (mesh.numTriangles > triangleThreshold)? _pbPickingCollider : _as3PickingCollider;
			return _activePickingCollider.testMeshCollision(mesh, pickingCollisionVO, shortestCollisionDistance, findClosest);
		}

		public function testBillboardCollision(billboard:Billboard, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number):Boolean {
			_activePickingCollider = (triangleThreshold < 2)? _pbPickingCollider : _as3PickingCollider;
			return _activePickingCollider.testBillboardCollision(billboard, pickingCollisionVO, shortestCollisionDistance);
		}
	}
}
