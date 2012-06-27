package away3d.core.pick
{
	import away3d.core.base.SubMesh;
	import flash.geom.Vector3D;
	/**
	 * @author robbateman
	 */
	public interface IPickingCollider
	{
		function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):void
		
		function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO):Boolean
	}
}
