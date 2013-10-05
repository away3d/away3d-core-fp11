package away3d.core.pick
{
	import away3d.core.base.*;
	
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.*;
	
	/**
	 * PixelBender-based picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
	 *
	 * @see away3d.entities.Entity#pickingCollider
	 * @see away3d.core.pick.RaycastPicker
	 */
	public class PBPickingCollider extends PickingColliderBase implements IPickingCollider
	{
		[Embed("/../pb/RayTriangleKernel.pbj", mimeType="application/octet-stream")]
		private var RayTriangleKernelClass:Class;
		
		private var _findClosestCollision:Boolean;
		
		private var _rayTriangleKernel:Shader;
		private var _lastSubMeshUploaded:SubMesh;
		private var _kernelOutputBuffer:Vector.<Number>;
		
		/**
		 * Creates a new <code>PBPickingCollider</code> object.
		 *
		 * @param findClosestCollision Determines whether the picking collider searches for the closest collision along the ray. Defaults to false.
		 */
		public function PBPickingCollider(findClosestCollision:Boolean = false)
		{
			_findClosestCollision = findClosestCollision;
			
			_kernelOutputBuffer = new Vector.<Number>();
			_rayTriangleKernel = new Shader(new RayTriangleKernelClass() as ByteArray);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):void
		{
			super.setLocalRay(localPosition, localDirection);
			
			//update ray
			_rayTriangleKernel.data.rayStartPoint.value = [ rayPosition.x, rayPosition.y, rayPosition.z ];
			_rayTriangleKernel.data.rayDirection.value = [ rayDirection.x, rayDirection.y, rayDirection.z ];
		}
		
		/**
		 * @inheritDoc
		 */
		public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Number):Boolean
		{
			var cx:Number, cy:Number, cz:Number;
			var u:Number, v:Number, w:Number;
			var indexData:Vector.<uint> = subMesh.indexData;
			var vertexData:Vector.<Number> = subMesh.subGeometry.vertexPositionData;
			var uvData:Vector.<Number> = subMesh.UVData;
			var numericIndexData:Vector.<Number> = Vector.<Number>(indexData);
			var indexBufferDims:Point = evaluateArrayAsGrid(numericIndexData);
			
			// if working on a clone, no need to resend data to pb
			if (!_lastSubMeshUploaded || _lastSubMeshUploaded !== subMesh) {
				// send vertices to pb
				var duplicateVertexData:Vector.<Number> = vertexData.concat();
				var vertexBufferDims:Point = evaluateArrayAsGrid(duplicateVertexData);
				_rayTriangleKernel.data.vertexBuffer.width = vertexBufferDims.x;
				_rayTriangleKernel.data.vertexBuffer.height = vertexBufferDims.y;
				_rayTriangleKernel.data.vertexBufferWidth.value = [ vertexBufferDims.x ];
				_rayTriangleKernel.data.vertexBuffer.input = duplicateVertexData;
				_rayTriangleKernel.data.bothSides.value = [ (subMesh.material && subMesh.material.bothSides)? 1.0 : 0.0 ];
				
				// send indices to pb
				_rayTriangleKernel.data.indexBuffer.width = indexBufferDims.x;
				_rayTriangleKernel.data.indexBuffer.height = indexBufferDims.y;
				_rayTriangleKernel.data.indexBuffer.input = numericIndexData;
			}
			
			_lastSubMeshUploaded = subMesh;
			
			// run kernel.
			var shaderJob:ShaderJob = new ShaderJob(_rayTriangleKernel, _kernelOutputBuffer, indexBufferDims.x, indexBufferDims.y);
			shaderJob.start(true);
			
			// find a proper collision from pb's output
			var i:uint;
			var t:Number;
			var collisionTriangleIndex:int = -1;
			var len:uint = _kernelOutputBuffer.length;
			for (i = 0; i < len; i += 3) {
				t = _kernelOutputBuffer[ i ];
				if (t > 0 && t < shortestCollisionDistance) {
					shortestCollisionDistance = t;
					collisionTriangleIndex = i;
					
					//break loop unless best hit is required
					if (!_findClosestCollision)
						break;
				}
			}
			
			// Detect collision
			if (collisionTriangleIndex >= 0) {
				
				pickingCollisionVO.rayEntryDistance = shortestCollisionDistance;
				cx = rayPosition.x + shortestCollisionDistance*rayDirection.x;
				cy = rayPosition.y + shortestCollisionDistance*rayDirection.y;
				cz = rayPosition.z + shortestCollisionDistance*rayDirection.z;
				pickingCollisionVO.localPosition = new Vector3D(cx, cy, cz);
				pickingCollisionVO.localNormal = getCollisionNormal(indexData, vertexData, collisionTriangleIndex);
				v = _kernelOutputBuffer[ collisionTriangleIndex + 1 ]; // barycentric coord 1
				w = _kernelOutputBuffer[ collisionTriangleIndex + 2 ]; // barycentric coord 2
				u = 1.0 - v - w;
				pickingCollisionVO.uv = getCollisionUV(indexData, uvData, collisionTriangleIndex, v, w, u, 0, 2);
				
				return true;
			}
			
			return false;
		}
		
		private function evaluateArrayAsGrid(array:Vector.<Number>):Point
		{
			var count:uint = array.length/3;
			var w:uint = Math.floor(Math.sqrt(count));
			var h:uint = w;
			var i:uint;
			while (w*h < count) {
				for (i = 0; i < w; ++i)
					array.push(0.0, 0.0, 0.0);
				h++;
			}
			return new Point(w, h);
		}
	}
}
