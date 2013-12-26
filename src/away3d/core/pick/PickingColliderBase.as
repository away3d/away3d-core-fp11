package away3d.core.pick
{
	import flash.geom.*;
	
	import away3d.tools.utils.GeomUtil;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	
	/**
	 * An abstract base class for all picking collider classes. It should not be instantiated directly.
	 */
	public class PickingColliderBase
	{
		protected var rayPosition:Vector3D;
		protected var rayDirection:Vector3D;
		
		public function PickingColliderBase()
		{
		
		}
		
		protected function getCollisionNormal(indexData:Vector.<uint>, vertexData:Vector.<Number>, triangleIndex:uint, normal:Vector3D = null):Vector3D
		{
			var i0:uint = indexData[ triangleIndex ]*3;
			var i1:uint = indexData[ triangleIndex + 1 ]*3;
			var i2:uint = indexData[ triangleIndex + 2 ]*3;

			var side0x:Number = vertexData[ i1 ] - vertexData[ i0 ];
			var side0y:Number = vertexData[ i1 + 1] - vertexData[ i0 + 1];
			var side0z:Number = vertexData[ i1 + 2] - vertexData[ i0 + 2];
			var side1x:Number = vertexData[ i2 ] - vertexData[ i0 ];
			var side1y:Number = vertexData[ i2 + 1] - vertexData[ i0 + 1];
			var side1z:Number = vertexData[ i2 + 2] - vertexData[ i0 + 2];

			if(!normal) normal = new Vector3D();
			normal.x = side0y*side1z - side0z*side1y;
			normal.y = side0z*side1x - side0x*side1z;
			normal.z = side0x*side1y - side0y*side1x;
			normal.w = 1;
			normal.normalize();
			return normal;
		}
		
		protected function getCollisionUV(indexData:Vector.<uint>, uvData:Vector.<Number>, triangleIndex:uint, v:Number, w:Number, u:Number, uvOffset:uint, uvStride:uint, uv:Point = null):Point
		{
			var uIndex:uint = indexData[ triangleIndex ]*uvStride + uvOffset;
			var uv0x:Number = uvData[ uIndex ];
			var uv0y:Number = uvData[ uIndex +1 ];
			uIndex = indexData[ triangleIndex + 1 ]*uvStride + uvOffset;
			var uv1x:Number = uvData[ uIndex ];
			var uv1y:Number = uvData[ uIndex +1 ];
			uIndex = indexData[ triangleIndex + 2 ]*uvStride + uvOffset;
			var uv2x:Number = uvData[ uIndex ];
			var uv2y:Number = uvData[ uIndex +1 ];
			if(!uv) uv = new Point();
			uv.x = u*uv0x + v*uv1x + w*uv2x;
			uv.y = u*uv0y + v*uv1y + w*uv2y;
			return uv;
		}
		
		protected function getMeshSubgeometryIndex(subGeometry:SubGeometry):uint
		{
			return GeomUtil.getMeshSubgeometryIndex(subGeometry);
		}
		
		protected function getMeshSubMeshIndex(subMesh:SubMesh):uint
		{
			return GeomUtil.getMeshSubMeshIndex(subMesh);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):void
		{
			rayPosition = localPosition;
			rayDirection = localDirection;
		}
	}
}
