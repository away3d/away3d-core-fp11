package away3d.core.pick
{
	import away3d.core.base.*;
	
	import flash.geom.*;


	public class AutoPickingCollider implements IPickingCollider
	{
		private var _pbPickingCollider:PBPickingCollider;
		private var _as3PickingCollider:AS3PickingCollider;
		private var _activePickingCollider:IPickingCollider;

		public var triangleThreshold:uint = 256;

		// TODO: implement find best hit
		public function AutoPickingCollider( findBestHit:Boolean = false )
		{
			_as3PickingCollider = new AS3PickingCollider( findBestHit );
			_pbPickingCollider = new PBPickingCollider( findBestHit );
		}
		
		public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):void
		{
			_as3PickingCollider.setLocalRay(localPosition, localDirection);
			_pbPickingCollider.setLocalRay(localPosition, localDirection);
		}
		
		public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO):Boolean
		{
			_activePickingCollider = (subMesh.numTriangles > triangleThreshold)? _pbPickingCollider : _as3PickingCollider;
			
			return _activePickingCollider.testSubMeshCollision(subMesh, pickingCollisionVO);
		}
	}
}
