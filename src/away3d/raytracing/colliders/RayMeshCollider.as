package away3d.raytracing.colliders
{

	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;

	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	public class RayMeshCollider extends RayCollider
	{
		[Embed("../pb/RayTriangleKernel.pbj", mimeType="application/octet-stream")]
		private var RayTriangleKernelClass:Class;

		private var _rayTriangleKernel:Shader;
		private var _mesh:Mesh;
		private var _indexBufferDims:Point;
		private var _intersectionBuffer:Vector.<Number>; // kernel output
		private var _lastSubGeometry:SubGeometry;

		public function RayMeshCollider() {
			super();
			_intersectionBuffer = new Vector.<Number>();
			_rayTriangleKernel = new Shader( new RayTriangleKernelClass() as ByteArray );
		}

		public function set mesh( mesh:Mesh ):void {

			_mesh = mesh;

			var subGeometry:SubGeometry = _mesh.geometry.subGeometries[ 0 ];

			// if working on a clone, no need to resend data to pb
			if( _lastSubGeometry && _lastSubGeometry == subGeometry ) {
				return;
			}

			// -----------------------
			// send vertices to pb
			// -----------------------

			var vertices:Vector.<Number> = subGeometry.vertexData.concat();

			// configure array into grid
			var vertexBufferDims:Point = setToNearestGridDimensions( vertices );

			// send
			_rayTriangleKernel.data.vertexBuffer.width = vertexBufferDims.x;
			_rayTriangleKernel.data.vertexBuffer.height = vertexBufferDims.y;
			_rayTriangleKernel.data.vertexBufferDims.value = [ vertexBufferDims.x, vertexBufferDims.y ];
			_rayTriangleKernel.data.vertexBuffer.input = vertices;

			// -----------------------
			// send indices to pb
			// -----------------------

			// TODO: REALLY NEED TO CAST INDICES AS NUMBERS?
			var indices:Vector.<Number> = subGeometry.indicesAsNumbers;

			// configure array into grid
			_indexBufferDims = setToNearestGridDimensions( indices );

			// send
			_rayTriangleKernel.data.indexBuffer.width = _indexBufferDims.x;
			_rayTriangleKernel.data.indexBuffer.height = _indexBufferDims.y;
			_rayTriangleKernel.data.indexBuffer.input = indices;

			_lastSubGeometry = subGeometry;
		}

		private function setToNearestGridDimensions( array:Vector.<Number> ):Point {
			var count:uint = array.length / 3;
			var w:uint = Math.floor( Math.sqrt( count ) );
			var h:uint = w;
			var i:uint;
			while(w * h < count) {
				for( i = 0; i < w; ++i ) {
					array.push( 0, 0, 0 );
				}
				h++;
			}
			return new Point( w, h );
		}

		override public function updateRay( position:Vector3D, direction:Vector3D ):void {
			_rayTriangleKernel.data.rayStartPoint.value = [ position.x, position.y, position.z ];
			_rayTriangleKernel.data.rayDirection.value = [ direction.x, direction.y, direction.z ];
			super.updateRay( position, direction );
		}

		override public function evaluate( ...params ):Boolean {

			_collides = false;

			// run kernel.
			var rayTriangleKernelJob:ShaderJob = new ShaderJob( _rayTriangleKernel, _intersectionBuffer, _indexBufferDims.x, _indexBufferDims.y );
			rayTriangleKernelJob.start( true );

			// evaluate kernel output and find intersection
			var len:uint = _intersectionBuffer.length / 4;
			var smallestNonNegativeT:Number = Number.MAX_VALUE;
			var targetIndex:uint;
			for( var i:uint; i < len; ++i ) {
				var index:uint = i * 4;
				var t:Number = _intersectionBuffer[ index ];
				if( t > 0 && t < smallestNonNegativeT ) {
					smallestNonNegativeT = t;
					targetIndex = index;
					_collides = true;
				}
			}

			if( _collides ) {
				rayPoint.x = _intersectionBuffer[ targetIndex + 1 ];
				rayPoint.y = _intersectionBuffer[ targetIndex + 2 ];
				rayPoint.z = _intersectionBuffer[ targetIndex + 3 ];
				rayPoint = mesh.transform.transformVector( rayPoint );
			}

			return _collides;
		}

		public function get mesh():Mesh {
			return _mesh;
		}
	}
}
