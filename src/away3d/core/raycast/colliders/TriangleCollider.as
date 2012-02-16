package away3d.core.raycast.colliders
{

	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;

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
		private var _lastRenderableUploaded:IRenderable;
		private var _collisionUV:Point;
		private var _collisionTriangleIndex:uint;
		private var _breakOnFirstTriangleHit:Boolean = false;

		public function TriangleCollider() {
			super();
			_kernelOutputBuffer = new Vector.<Number>();
			_rayTriangleKernel = new Shader( new RayTriangleKernelClass() as ByteArray );
			_collisionUV = new Point();
		}

		override public function evaluate( item:RenderableListItem ):Boolean {
			_collisionExists = false;
			var renderable:IRenderable = item.renderable;
			uploadRenderableData( renderable );
			executeKernel();
			if( _collisionExists ) _collidingRenderable = renderable;
			return _collisionExists;
		}

		private function uploadRenderableData( renderable:IRenderable ):void {
			// if working on a clone, no need to resend data to pb
			// TODO: next line avoids re-upload if its the same renderable, but not if its 2 renderables referring to the same geometry or source
			// TODO: perhaps implement a geom id?
			if( _lastRenderableUploaded && _lastRenderableUploaded === renderable ) return;
			// send vertices to pb
			var vertices:Vector.<Number> = renderable.vertexData.concat(); // TODO: need concat? if not could affect rendering by introducing null triangles, or uncontrolled index buffer growth
			var vertexBufferDims:Point = evaluateArrayAsGrid( vertices );
			_rayTriangleKernel.data.vertexBuffer.width = vertexBufferDims.x;
			_rayTriangleKernel.data.vertexBuffer.height = vertexBufferDims.y;
			_rayTriangleKernel.data.vertexBufferWidth.value = [ vertexBufferDims.x ];
			_rayTriangleKernel.data.vertexBuffer.input = vertices;
			// send indices to pb
			var indices:Vector.<Number> = Vector.<Number>( renderable.indexData );
			_indexBufferDims = evaluateArrayAsGrid( indices );
			_rayTriangleKernel.data.indexBuffer.width = _indexBufferDims.x;
			_rayTriangleKernel.data.indexBuffer.height = _indexBufferDims.y;
			_rayTriangleKernel.data.indexBuffer.input = indices;
			_lastRenderableUploaded = renderable;
		}

		private function executeKernel():void {
			// run kernel.
			var rayTriangleKernelJob:ShaderJob = new ShaderJob( _rayTriangleKernel, _kernelOutputBuffer, _indexBufferDims.x, _indexBufferDims.y );
			rayTriangleKernelJob.start( true );
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
		}

		override public function get collisionPoint():Vector3D {
			if( !_collisionExists ) return null;
			_t = _kernelOutputBuffer[ _collisionTriangleIndex ];
			_collisionPoint.x = _rayPosition.x + _t * _rayDirection.x;
			_collisionPoint.y = _rayPosition.y + _t * _rayDirection.y;
			_collisionPoint.z = _rayPosition.z + _t * _rayDirection.z;
			return _collisionPoint;
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
