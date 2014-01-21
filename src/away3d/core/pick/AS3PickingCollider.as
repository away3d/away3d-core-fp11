package away3d.core.pick
{
	import away3d.core.base.*;
	
	import flash.geom.*;
	
	/**
	 * Pure AS3 picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
	 *
	 * @see away3d.entities.Entity#pickingCollider
	 * @see away3d.core.pick.RaycastPicker
	 */
	public class AS3PickingCollider extends PickingColliderBase implements IPickingCollider
	{
		private var _findClosestCollision:Boolean;
		
		/**
		 * Creates a new <code>AS3PickingCollider</code> object.
		 *
		 * @param findClosestCollision Determines whether the picking collider searches for the closest collision along the ray. Defaults to false.
		 */
		public function AS3PickingCollider(findClosestCollision:Boolean = false)
		{
			_findClosestCollision = findClosestCollision;
		}
		
		/**
		 * @inheritDoc
		 */
		public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number):Boolean
		{
			var t:Number;
			var i0:uint, i1:uint, i2:uint;
			var rx:Number, ry:Number, rz:Number;
			var nx:Number, ny:Number, nz:Number;
			var cx:Number, cy:Number, cz:Number;
			var coeff:Number, u:Number, v:Number, w:Number;
			var p0x:Number, p0y:Number, p0z:Number;
			var p1x:Number, p1y:Number, p1z:Number;
			var p2x:Number, p2y:Number, p2z:Number;
			var s0x:Number, s0y:Number, s0z:Number;
			var s1x:Number, s1y:Number, s1z:Number;
			var nl:Number, nDotV:Number, D:Number, disToPlane:Number;
			var Q1Q2:Number, Q1Q1:Number, Q2Q2:Number, RQ1:Number, RQ2:Number;
			var indexData:Vector.<uint> = subMesh.indexData;
			var vertexData:Vector.<Number> = subMesh.vertexData;
			var uvData:Vector.<Number> = subMesh.UVData;
			var collisionTriangleIndex:int = -1;
			var bothSides:Boolean = (subMesh.material && subMesh.material.bothSides);
			
			var vertexStride:uint = subMesh.vertexStride;
			var vertexOffset:uint = subMesh.vertexOffset;
			var uvStride:uint = subMesh.UVStride;
			var uvOffset:uint = subMesh.UVOffset;
			var numIndices:int = indexData.length;
			
			for (var index:uint = 0; index < numIndices; index += 3) { // sweep all triangles
				// evaluate triangle indices
				i0 = vertexOffset + indexData[ index ]*vertexStride;
				i1 = vertexOffset + indexData[ uint(index + 1) ]*vertexStride;
				i2 = vertexOffset + indexData[ uint(index + 2) ]*vertexStride;
				
				// evaluate triangle vertices
				p0x = vertexData[ i0 ];
				p0y = vertexData[ uint(i0 + 1) ];
				p0z = vertexData[ uint(i0 + 2) ];
				p1x = vertexData[ i1 ];
				p1y = vertexData[ uint(i1 + 1) ];
				p1z = vertexData[ uint(i1 + 2) ];
				p2x = vertexData[ i2 ];
				p2y = vertexData[ uint(i2 + 1) ];
				p2z = vertexData[ uint(i2 + 2) ];
				
				// evaluate sides and triangle normal
				s0x = p1x - p0x; // s0 = p1 - p0
				s0y = p1y - p0y;
				s0z = p1z - p0z;
				s1x = p2x - p0x; // s1 = p2 - p0
				s1y = p2y - p0y;
				s1z = p2z - p0z;
				nx = s0y*s1z - s0z*s1y; // n = s0 x s1
				ny = s0z*s1x - s0x*s1z;
				nz = s0x*s1y - s0y*s1x;
				nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz); // normalize n
				nx *= nl;
				ny *= nl;
				nz *= nl;
				
				// -- plane intersection test --
				nDotV = nx*rayDirection.x + ny* +rayDirection.y + nz*rayDirection.z; // rayDirection . normal
				if (( !bothSides && nDotV < 0.0 ) || ( bothSides && nDotV != 0.0 )) { // an intersection must exist
					// find collision t
					D = -( nx*p0x + ny*p0y + nz*p0z );
					disToPlane = -( nx*rayPosition.x + ny*rayPosition.y + nz*rayPosition.z + D );
					t = disToPlane/nDotV;
					// find collision point
					cx = rayPosition.x + t*rayDirection.x;
					cy = rayPosition.y + t*rayDirection.y;
					cz = rayPosition.z + t*rayDirection.z;
					// collision point inside triangle? ( using barycentric coordinates )
					Q1Q2 = s0x*s1x + s0y*s1y + s0z*s1z;
					Q1Q1 = s0x*s0x + s0y*s0y + s0z*s0z;
					Q2Q2 = s1x*s1x + s1y*s1y + s1z*s1z;
					rx = cx - p0x;
					ry = cy - p0y;
					rz = cz - p0z;
					RQ1 = rx*s0x + ry*s0y + rz*s0z;
					RQ2 = rx*s1x + ry*s1y + rz*s1z;
					coeff = 1/( Q1Q1*Q2Q2 - Q1Q2*Q1Q2 );
					v = coeff*( Q2Q2*RQ1 - Q1Q2*RQ2 );
					w = coeff*( -Q1Q2*RQ1 + Q1Q1*RQ2 );
					if (v < 0)
						continue;
					if (w < 0)
						continue;
					u = 1 - v - w;
					if (!( u < 0 ) && t > 0 && t < shortestCollisionDistance) { // all tests passed
						shortestCollisionDistance = t;
						collisionTriangleIndex = index/3;
						pickingCollisionVO.rayEntryDistance = t;
						pickingCollisionVO.localPosition = new Vector3D(cx, cy, cz);
						pickingCollisionVO.localNormal = new Vector3D(nx, ny, nz);
						pickingCollisionVO.uv = getCollisionUV(indexData, uvData, index, v, w, u, uvOffset, uvStride);
						pickingCollisionVO.index = index;
						pickingCollisionVO.subGeometryIndex = getMeshSubMeshIndex(subMesh);
						
						// if not looking for best hit, first found will do...
						if (!_findClosestCollision)
							return true;
					}
				}
			}
			
			if (collisionTriangleIndex >= 0)
				return true;
			
			return false;
		}
	}
}
