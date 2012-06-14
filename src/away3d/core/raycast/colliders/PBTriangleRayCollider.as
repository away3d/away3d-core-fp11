package away3d.core.raycast.colliders
{

	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubMesh;
	import away3d.core.raycast.data.RayCollisionVO;
	import away3d.entities.Mesh;

	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Point;

	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	public class PBTriangleRayCollider extends TriangleRayCollider
	{
		[Embed("/../pb/RayTriangleKernel.pbj", mimeType="application/octet-stream")]
		private var RayTriangleKernelClass:Class;

		private var _collisionUV:Point;
		private var _shaderJob:ShaderJob;
		private var _indexBufferDims:Point;
		private var _uvData:Vector.<Number>;
		private var _rayTriangleKernel:Shader;
		private var _collisionNormal:Vector3D;
		private var _indexData:Vector.<Number>;
		private var _vertexData:Vector.<Number>;
		private var _collisionTriangleIndex:uint;
		private var _lastRenderableUploaded:SubMesh;
		private var _kernelOutputBuffer:Vector.<Number>;

		public function PBTriangleRayCollider() {

			_kernelOutputBuffer = new Vector.<Number>();
			_rayTriangleKernel = new Shader( new RayTriangleKernelClass() as ByteArray );
			_collisionUV = new Point();
			_collisionNormal = new Vector3D();

			super();
		}

		override public function set localRayPosition( value:Vector3D ):void {
			super.localRayPosition = value;
			_rayTriangleKernel.data.rayStartPoint.value = [ localRayPosition.x, localRayPosition.y, localRayPosition.z ];
		}

		override public function set localRayDirection( value:Vector3D ):void {
			super.localRayDirection = value;
			_rayTriangleKernel.data.rayDirection.value = [ localRayDirection.x, localRayDirection.y, localRayDirection.z ];
		}

		override protected function evaluateSubMesh( subMesh:SubMesh ):Boolean {
			uploadSubMeshData( subMesh );
			return executeKernel();
		}

		private function uploadSubMeshData( subMesh:SubMesh ):void {

			// TODO: It seems that the kernel takes almost the same time to calculate on a mesh with 2 triangles than on a
			// mesh with thousands of triangles. It might be worth exploring the possibility of accumulating buffers until a certain
			// threshold is met, and then running the kernel on a group of meshes.

			// if working on a clone, no need to resend data to pb
			// TODO: next line avoids re-upload if its the same renderable, but not if its 2 renderables referring to the same geometry or source
			// TODO: perhaps implement a geom id?
			if( _lastRenderableUploaded && _lastRenderableUploaded === subMesh ) return;

			// send vertices to pb
			_vertexData = subMesh.vertexData.concat(); // TODO: need concat? if not could affect rendering by introducing null triangles, or uncontrolled index buffer growth
			var vertexBufferDims:Point = evaluateArrayAsGrid( _vertexData );
			_rayTriangleKernel.data.vertexBuffer.width = vertexBufferDims.x;
			_rayTriangleKernel.data.vertexBuffer.height = vertexBufferDims.y;
			_rayTriangleKernel.data.vertexBufferWidth.value = [ vertexBufferDims.x ];
			_rayTriangleKernel.data.vertexBuffer.input = _vertexData;

			// send indices to pb
			_indexData = Vector.<Number>( subMesh.indexData );
			_indexBufferDims = evaluateArrayAsGrid( _indexData );
			_rayTriangleKernel.data.indexBuffer.width = _indexBufferDims.x;
			_rayTriangleKernel.data.indexBuffer.height = _indexBufferDims.y;
			_rayTriangleKernel.data.indexBuffer.input = _indexData;
			_lastRenderableUploaded = subMesh;

			_uvData = subMesh.UVData;
		}

		private function executeKernel():Boolean {

			// run kernel.
			_shaderJob = new ShaderJob( _rayTriangleKernel, _kernelOutputBuffer, _indexBufferDims.x, _indexBufferDims.y );
			_shaderJob.start( true );

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
					break; // does not search for closest collision, first found will do... // TODO: add option of finding best tri hit? on a different collider?
				}
			}
			_collisionTriangleIndex = collisionTriangleIndex;
			var collides:Boolean = collisionTriangleIndex >= 0;

			// Construct and set collision data.
			if( collides ) {
				var collisionVO:RayCollisionVO = new RayCollisionVO();
				collisionVO.nearT = t;
				collisionVO.localRayPosition = localRayPosition;
				collisionVO.localRayDirection = localRayDirection;
				collisionVO.position = new Vector3D(
						localRayPosition.x + t * localRayDirection.x,
						localRayPosition.y + t * localRayDirection.y,
						localRayPosition.z + t * localRayDirection.z
				);
				collisionVO.normal = collisionNormal;
				collisionVO.uv = collisionUV;
				setCollisionDataForItem( _targetMesh, collisionVO );
			}

			return collides;
		}

		override protected function get collisionNormal():Vector3D {
			var index:uint = _collisionTriangleIndex;
			var i0:Number = _indexData[ index ] * 3;
			var i1:Number = _indexData[ index + 1 ] * 3;
			var i2:Number = _indexData[ index + 2 ] * 3;
			var p0:Vector3D = new Vector3D( _vertexData[ i0 ], _vertexData[ i0 + 1 ], _vertexData[ i0 + 2 ] );
			var p1:Vector3D = new Vector3D( _vertexData[ i1 ], _vertexData[ i1 + 1 ], _vertexData[ i1 + 2 ] );
			var p2:Vector3D = new Vector3D( _vertexData[ i2 ], _vertexData[ i2 + 1 ], _vertexData[ i2 + 2 ] );
			var side0:Vector3D = p1.subtract( p0 );
			var side1:Vector3D = p2.subtract( p0 );
			_collisionNormal = side0.crossProduct( side1 );
			_collisionNormal.normalize();
			return _collisionNormal;
		}

		override protected function get collisionUV():Point {
			var index:uint = _collisionTriangleIndex;
			var v:Number = _kernelOutputBuffer[ index + 1 ]; // barycentric coord 1
			var w:Number = _kernelOutputBuffer[ index + 2 ]; // barycentric coord 2
			var u:Number = 1.0 - v - w;
			var uvIndex:Number = _indexData[ index ] * 2;
			var uv0:Vector3D = new Vector3D( _uvData[ uvIndex ], _uvData[ uvIndex + 1 ] );
			index++;
			uvIndex = _indexData[ index ] * 2;
			var uv1:Vector3D = new Vector3D( _uvData[ uvIndex ], _uvData[ uvIndex + 1 ] );
			index++;
			uvIndex = _indexData[ index ] * 2;
			var uv2:Vector3D = new Vector3D( _uvData[ uvIndex ], _uvData[ uvIndex + 1 ] );
			_collisionUV.x = u * uv0.x + v * uv1.x + w * uv2.x;
			_collisionUV.y = u * uv0.y + v * uv1.y + w * uv2.y;
			return _collisionUV;
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
