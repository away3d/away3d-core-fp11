package away3d.core.raycast.colliders
{

	import away3d.core.base.IRenderable;
	import away3d.core.base.SubMesh;

	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	public class TriangleCollider extends ColliderBase
	{
		[Embed("/../pb/RayTriangleKernel.pbj", mimeType="application/octet-stream")]
		private var RayTriangleKernelClass:Class;

		private var _rayTriangleKernel:Shader;
		private var _indexBufferDims:Point;
		private var _kernelOutputBuffer:Vector.<Number>;
		private var _lastRenderableUploaded:SubMesh;
		private var _collisionUV:Point;
		private var _collisionNormal:Vector3D;
		private var _collisionTriangleIndex:uint;
		private var _breakOnFirstTriangleHit:Boolean = false;
		private var _shaderJob:ShaderJob;

		public function TriangleCollider() {
			super();
			_kernelOutputBuffer = new Vector.<Number>();
			_rayTriangleKernel = new Shader( new RayTriangleKernelClass() as ByteArray );
			_collisionUV = new Point();
			_collisionNormal = new Vector3D();
		}

		override public function evaluate():Boolean {
			_collisionExists = false;
			var subMesh:SubMesh = _target as SubMesh;
			uploadRenderableData( subMesh );
			executeKernel();
			if( _collisionExists ) _collidingRenderable = subMesh;
			return _collisionExists;
		}

		private function uploadRenderableData( subMesh:SubMesh ):void {

			// TODO: It seems that the kernel takes almost the same time to calculate on a mesh with 2 triangles than on a
			// mesh with thousands of triangles. It might be worth exploring the possibility of accumulating buffers until a certain
			// threshold is met, and then running the kernel on a group of meshes.

			// if working on a clone, no need to resend data to pb
			// TODO: next line avoids re-upload if its the same renderable, but not if its 2 renderables referring to the same geometry or source
			// TODO: perhaps implement a geom id?
			if( _lastRenderableUploaded && _lastRenderableUploaded === subMesh ) return;

//        var time:uint = getTimer();

			// send vertices to pb
			var vertices:Vector.<Number> = subMesh.vertexData.concat(); // TODO: need concat? if not could affect rendering by introducing null triangles, or uncontrolled index buffer growth
			var vertexBufferDims:Point = evaluateArrayAsGrid( vertices );
			_rayTriangleKernel.data.vertexBuffer.width = vertexBufferDims.x;
			_rayTriangleKernel.data.vertexBuffer.height = vertexBufferDims.y;
			_rayTriangleKernel.data.vertexBufferWidth.value = [ vertexBufferDims.x ];
			_rayTriangleKernel.data.vertexBuffer.input = vertices;
			// send indices to pb
			var indices:Vector.<Number> = Vector.<Number>( subMesh.indexData );
			_indexBufferDims = evaluateArrayAsGrid( indices );
			_rayTriangleKernel.data.indexBuffer.width = _indexBufferDims.x;
			_rayTriangleKernel.data.indexBuffer.height = _indexBufferDims.y;
			_rayTriangleKernel.data.indexBuffer.input = indices;
			_lastRenderableUploaded = subMesh;

//        time = getTimer() - time;
//        trace( "tri-test - upload time: " + time + ", with a mesh of " + indices.length / 3 + " triangles." );
		}

		private function executeKernel():void {

//        var time:uint = getTimer();

			// run kernel.
			_shaderJob = new ShaderJob( _rayTriangleKernel, _kernelOutputBuffer, _indexBufferDims.x, _indexBufferDims.y );
			_shaderJob.start( true );

//        time = getTimer() - time;
//        trace( "tri-test - kernel time: " + time );
//        time = getTimer();

			// find a proper collision from pb's output
			var i:uint;
			var t:Number;
			var collisionTriangleIndex:int = -1;
			var len:uint = _kernelOutputBuffer.length;
			var smallestNonNegativeT:Number = Number.MAX_VALUE;
			if( _breakOnFirstTriangleHit ) {
				for( i = 0; i < len; i += 3 ) {
					t = _kernelOutputBuffer[ i ];
					if( t > 0 && t < smallestNonNegativeT ) {
						smallestNonNegativeT = t;
						collisionTriangleIndex = i;
						break;
					}
				}
			}
			else {
				for( i = 0; i < len; i += 3 ) {
					t = _kernelOutputBuffer[ i ];
					if( t > 0 && t < smallestNonNegativeT ) {
						smallestNonNegativeT = t;
						collisionTriangleIndex = i;
					}
				}
			}
			_t = smallestNonNegativeT;
			_collisionTriangleIndex = collisionTriangleIndex;
			_collisionExists = collisionTriangleIndex >= 0;

//        time = getTimer() - time;
//        trace( "tri-test - resolve time: " + time );
		}

		override public function get collisionPoint():Vector3D {
			if( !_collisionExists ) return null;
			_t = _kernelOutputBuffer[ _collisionTriangleIndex ];
			_collisionPoint.x = _rayPosition.x + _t * _rayDirection.x;
			_collisionPoint.y = _rayPosition.y + _t * _rayDirection.y;
			_collisionPoint.z = _rayPosition.z + _t * _rayDirection.z;
			return _collisionPoint;
		}

		public function get collisionNormal():Vector3D {
			if( !_collisionExists ) return null;
			var indices:Vector.<uint> = _collidingRenderable.indexData;
			var vertices:Vector.<Number> = _collidingRenderable.vertexData;
			var index:uint = _collisionTriangleIndex;
			var i0:uint = indices[ index ] * 3;
			var i1:uint = indices[ index + 1 ] * 3;
			var i2:uint = indices[ index + 2 ] * 3;
			var p0:Vector3D = new Vector3D( vertices[ i0 ], vertices[ i0 + 1 ], vertices[ i0 + 2 ] );
			var p1:Vector3D = new Vector3D( vertices[ i1 ], vertices[ i1 + 1 ], vertices[ i1 + 2 ] );
			var p2:Vector3D = new Vector3D( vertices[ i2 ], vertices[ i2 + 1 ], vertices[ i2 + 2 ] );
			var side0:Vector3D = p1.subtract( p0 );
			var side1:Vector3D = p2.subtract( p0 );
			_collisionNormal = side0.crossProduct( side1 );
			_collisionNormal.normalize();
			return _collisionNormal;
		}

		public function get collisionUV():Point {
			if( !_collisionExists ) return null;
			var indices:Vector.<uint> = _collidingRenderable.indexData;
			var uvs:Vector.<Number> = _collidingRenderable.UVData;
			var index:uint = _collisionTriangleIndex;
			var v:Number = _kernelOutputBuffer[ index + 1 ]; // barycentric coord 1
			var w:Number = _kernelOutputBuffer[ index + 2 ]; // barycentric coord 2
			var u:Number = 1.0 - v - w;
			var uvIndex:uint = indices[ index ] * 2;
			var uv0:Vector3D = new Vector3D( uvs[ uvIndex ], uvs[ uvIndex + 1 ] );
			index++;
			uvIndex = indices[ index ] * 2;
			var uv1:Vector3D = new Vector3D( uvs[ uvIndex ], uvs[ uvIndex + 1 ] );
			index++;
			uvIndex = indices[ index ] * 2;
			var uv2:Vector3D = new Vector3D( uvs[ uvIndex ], uvs[ uvIndex + 1 ] );
			_collisionUV.x = u * uv0.x + v * uv1.x + w * uv2.x;
			_collisionUV.y = u * uv0.y + v * uv1.y + w * uv2.y;
			return _collisionUV;
		}

		override public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayTriangleKernel.data.rayStartPoint.value = [ position.x, position.y, position.z ];
			_rayTriangleKernel.data.rayDirection.value = [ direction.x, direction.y, direction.z ];
			super.updateRay( position, direction );
		}

		// TODO: this is not necessarily the most efficient way to pass data to pb
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

		public function set breakOnFirstTriangleHit( value:Boolean ):void {
			_breakOnFirstTriangleHit = value;
		}
	}
}
