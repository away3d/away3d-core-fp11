package away3d.utils
{

	public class GeometryUtil
	{
		/*
		* Combines a set of separate raw buffers into an interleaved one, compatible
		* with CompactSubGeometry. SubGeometry uses separate buffers, whereas CompactSubGeometry
		* uses a single, combined buffer.
		* */
		public static function interleaveBuffers( numVertices:uint,
												  vertices:Vector.<Number> = null,
												  normals:Vector.<Number> = null,
												  tangents:Vector.<Number> = null,
												  uvs:Vector.<Number> = null,
												  suvs:Vector.<Number> = null
				):Vector.<Number> {

			var i:uint, compIndex:uint, uvCompIndex:uint, interleavedCompIndex:uint;
			var interleavedBuffer:Vector.<Number>;

			interleavedBuffer = new Vector.<Number>();

			/**
			 * 0 - 2: vertex position X, Y, Z
			 * 3 - 5: normal X, Y, Z
			 * 6 - 8: tangent X, Y, Z
			 * 9 - 10: U V
			 * 11 - 12: Secondary U V
			 */
			for( i = 0; i < numVertices; ++i ) {
				uvCompIndex = i * 2;
				compIndex = i * 3;
				interleavedCompIndex = i * 13;
				interleavedBuffer[ interleavedCompIndex     ]  = vertices ? vertices[ compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 1 ]  = vertices ? vertices[ compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 2 ]  = vertices ? vertices[ compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 3 ]  = normals ? normals[   compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 4 ]  = normals ? normals[   compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 5 ]  = normals ? normals[   compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 6 ]  = tangents ? tangents[ compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 7 ]  = tangents ? tangents[ compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 8 ]  = tangents ? tangents[ compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 9 ]  = uvs ? uvs[      	  uvCompIndex     ] : 0;
				interleavedBuffer[ interleavedCompIndex + 10 ] = uvs ? uvs[     	  uvCompIndex + 1 ] : 0;
				interleavedBuffer[ interleavedCompIndex + 11 ] = suvs ? suvs[    	  uvCompIndex 	  ] : 0;
				interleavedBuffer[ interleavedCompIndex + 12 ] = suvs ? suvs[    	  uvCompIndex + 1 ] : 0;
			}

			return interleavedBuffer;
		}
	}
}
