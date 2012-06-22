package away3d.core.raycast.colliders.triangles
{

	import away3d.core.base.SubMesh;
	import away3d.core.raycast.data.RayCollisionVO;

	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	public class PBSubMeshRayCollider extends SubMeshRayColliderBase
	{
		[Embed("/../pb/RayTriangleKernel.pbj", mimeType="application/octet-stream")]
		private var RayTriangleKernelClass:Class;

		private var _indexBufferDims:Point;
		private var _rayTriangleKernel:Shader;
		private var _numericIndexData:Vector.<Number>;
		private var _lastSubMeshUploaded:SubMesh;
		private var _kernelOutputBuffer:Vector.<Number>;

		// TODO: implement find best hit

		public function PBSubMeshRayCollider( findBestHit:Boolean ) {

			_kernelOutputBuffer = new Vector.<Number>();
			_rayTriangleKernel = new Shader( new RayTriangleKernelClass() as ByteArray );

			super( findBestHit );
		}

		override public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayTriangleKernel.data.rayStartPoint.value = [ position.x, position.y, position.z ];
			_rayTriangleKernel.data.rayDirection.value = [ direction.x, direction.y, direction.z ];
			super.updateRay( position, direction );
		}

		override public function evaluate():void {
			reset();
			uploadSubMeshData();
			executeKernel();
		}

		private function uploadSubMeshData():void {

			// TODO: It seems that the kernel takes almost the same time to calculate on a mesh with 2 triangles than on a
			// mesh with thousands of triangles. It might be worth exploring the possibility of accumulating buffers until a certain
			// threshold is met, and then running the kernel on a group of meshes.

			// if working on a clone, no need to resend data to pb
			// TODO: next line avoids re-upload if its the same renderable, but not if its 2 renderables referring to the same geometry or source
			// TODO: perhaps implement a geom id?
			if( _lastSubMeshUploaded && _lastSubMeshUploaded === _subMesh ) return;

			// send vertices to pb
			_vertexData = _subMesh.vertexData.concat(); // TODO: need concat? if not could affect rendering by introducing null triangles, or uncontrolled index buffer growth
			var vertexBufferDims:Point = evaluateArrayAsGrid( _vertexData );
			_rayTriangleKernel.data.vertexBuffer.width = vertexBufferDims.x;
			_rayTriangleKernel.data.vertexBuffer.height = vertexBufferDims.y;
			_rayTriangleKernel.data.vertexBufferWidth.value = [ vertexBufferDims.x ];
			_rayTriangleKernel.data.vertexBuffer.input = _vertexData;

			// send indices to pb
			_indexData = _subMesh.indexData;
			_numericIndexData = Vector.<Number>( _indexData );
			_indexBufferDims = evaluateArrayAsGrid( _numericIndexData );
			_rayTriangleKernel.data.indexBuffer.width = _indexBufferDims.x;
			_rayTriangleKernel.data.indexBuffer.height = _indexBufferDims.y;
			_rayTriangleKernel.data.indexBuffer.input = _numericIndexData;
			_lastSubMeshUploaded = _subMesh;

			_uvData = _subMesh.UVData;
		}

		private function executeKernel():void {

			// run kernel.
			var shaderJob:ShaderJob = new ShaderJob( _rayTriangleKernel, _kernelOutputBuffer, _indexBufferDims.x, _indexBufferDims.y );
			shaderJob.start( true ); // TODO: use false and listen for completion

			// find a proper collision from pb's output
			var i:uint;
			var t:Number;
			var collisionTriangleIndex:int = -1;
			var len:uint = _kernelOutputBuffer.length;
			var smallestNonNegativeT:Number = Number.MAX_VALUE;
			for( i = 0; i < len; i += 3 ) {
				t = _kernelOutputBuffer[ i ];
				if( t > 0 && t < smallestNonNegativeT ) {
					smallestNonNegativeT = t;
					collisionTriangleIndex = i;
					break; // does not search for closest collision, first found will do... // TODO: add option of finding best triangle hit?
				}
			}
			_collides = collisionTriangleIndex >= 0;

			// Construct and set collision data.
			if( _collides ) {
				_collisionData = new RayCollisionVO();
				_collisionData.t = t;
				_collisionData.localRayPosition = _rayPosition;
				_collisionData.localRayDirection = _rayDirection;
				_collisionData.position = new Vector3D(
						_rayPosition.x + t * _rayDirection.x,
						_rayPosition.y + t * _rayDirection.y,
						_rayPosition.z + t * _rayDirection.z
				);
				_collisionData.normal = getCollisionNormal( collisionTriangleIndex );
				_collisionData.uv = getCollisionUV( collisionTriangleIndex );
			}
		}

		private function getCollisionNormal( triangleIndex:uint ):Vector3D {
			var normal:Vector3D = new Vector3D();
			var i0:uint = _indexData[ triangleIndex ] * 3;
			var i1:uint = _indexData[ triangleIndex + 1 ] * 3;
			var i2:uint = _indexData[ triangleIndex + 2 ] * 3;
			var p0:Vector3D = new Vector3D( _vertexData[ i0 ], _vertexData[ i0 + 1 ], _vertexData[ i0 + 2 ] );
			var p1:Vector3D = new Vector3D( _vertexData[ i1 ], _vertexData[ i1 + 1 ], _vertexData[ i1 + 2 ] );
			var p2:Vector3D = new Vector3D( _vertexData[ i2 ], _vertexData[ i2 + 1 ], _vertexData[ i2 + 2 ] );
			var side0:Vector3D = p1.subtract( p0 );
			var side1:Vector3D = p2.subtract( p0 );
			normal = side0.crossProduct( side1 );
			normal.normalize();
			return normal;
		}

		private function getCollisionUV( triangleIndex:uint ):Point {
			var uv:Point = new Point();
			var v:Number = _kernelOutputBuffer[ triangleIndex + 1 ]; // barycentric coord 1
			var w:Number = _kernelOutputBuffer[ triangleIndex + 2 ]; // barycentric coord 2
			var u:Number = 1.0 - v - w;
			var uvIndex:Number = _indexData[ triangleIndex ] * 2;
			var uv0:Vector3D = new Vector3D( _uvData[ uvIndex ], _uvData[ uvIndex + 1 ] );
			triangleIndex++;
			uvIndex = _indexData[ triangleIndex ] * 2;
			var uv1:Vector3D = new Vector3D( _uvData[ uvIndex ], _uvData[ uvIndex + 1 ] );
			triangleIndex++;
			uvIndex = _indexData[ triangleIndex ] * 2;
			var uv2:Vector3D = new Vector3D( _uvData[ uvIndex ], _uvData[ uvIndex + 1 ] );
			uv.x = u * uv0.x + v * uv1.x + w * uv2.x;
			uv.y = u * uv0.y + v * uv1.y + w * uv2.y;
			return uv;
		}

		// TODO: this is not necessarily the most efficient way to pass data to pb ( try different grid dimensions? )
		static private function evaluateArrayAsGrid( array:Vector.<Number> ):Point {
			var count:uint = array.length / 3;
			var w:uint = Math.floor( Math.sqrt( count ) );
			var h:uint = w;
			var i:uint;
			while( w * h < count ) {
				for( i = 0; i < w; ++i ) {
					array.push( 0.0, 0.0, 0.0 );
				}
				h++;
			}
			return new Point( w, h );
		}
	}
}
