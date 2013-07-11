package away3d.tools.utils
{
	import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubMesh;
	
	use namespace arcane;
	
	public class GeomUtil
	{
		/**
		 * Build a list of sub-geometries from raw data vectors, splitting them up in
		 * such a way that they won't exceed buffer length limits.
		 */
		public static function fromVectors(verts:Vector.<Number>, indices:Vector.<uint>, uvs:Vector.<Number>, normals:Vector.<Number>, tangents:Vector.<Number>, weights:Vector.<Number>, jointIndices:Vector.<Number>, triangleOffset:int = 0):Vector.<ISubGeometry>
		{
			const LIMIT_VERTS:uint = 3*0xffff;
			const LIMIT_INDICES:uint = 15*0xffff;
			
			var subs:Vector.<ISubGeometry> = new Vector.<ISubGeometry>();
			
			if (uvs && !uvs.length)
				uvs = null;
			
			if (normals && !normals.length)
				normals = null;
			
			if (tangents && !tangents.length)
				tangents = null;
			
			if (weights && !weights.length)
				weights = null;
			
			if (jointIndices && !jointIndices.length)
				jointIndices = null;
			
			if ((indices.length >= LIMIT_INDICES) || (verts.length >= LIMIT_VERTS)) {
				var i:uint, len:uint, outIndex:uint, j:uint;
				var splitVerts:Vector.<Number> = new Vector.<Number>();
				var splitIndices:Vector.<uint> = new Vector.<uint>();
				var splitUvs:Vector.<Number> = (uvs != null)? new Vector.<Number>() : null;
				var splitNormals:Vector.<Number> = (normals != null)? new Vector.<Number>() : null;
				var splitTangents:Vector.<Number> = (tangents != null)? new Vector.<Number>() : null;
				var splitWeights:Vector.<Number> = (weights != null)? new Vector.<Number>() : null;
				var splitJointIndices:Vector.<Number> = (jointIndices != null)? new Vector.<Number>() : null;
				
				var mappings:Vector.<int> = new Vector.<int>(verts.length/3, true);
				i = mappings.length;
				while (i-- > 0)
					mappings[i] = -1;
				
				var originalIndex:uint;
				var splitIndex:uint;
				var o0:uint, o1:uint, o2:uint, s0:uint, s1:uint, s2:uint,
					su:uint, ou:uint, sv:uint, ov:uint;
				// Loop over all triangles
				outIndex = 0;
				len = indices.length;
				
				for (i = 0; i < len; i += 3) {
					splitIndex = splitVerts.length + 6;
					
					if (( (outIndex + 2) >= LIMIT_INDICES) || (splitIndex >= LIMIT_VERTS)) {
						subs.push(constructSubGeometry(splitVerts, splitIndices, splitUvs, splitNormals, splitTangents, splitWeights, splitJointIndices, triangleOffset));
						splitVerts = new Vector.<Number>();
						splitIndices = new Vector.<uint>();
						splitUvs = (uvs != null)? new Vector.<Number>() : null;
						splitNormals = (normals != null)? new Vector.<Number>() : null;
						splitTangents = (tangents != null)? new Vector.<Number>() : null;
						splitWeights = (weights != null)? new Vector.<Number>() : null;
						splitJointIndices = (jointIndices != null)? new Vector.<Number>() : null;
						splitIndex = 0;
						j = mappings.length;
						while (j-- > 0)
							mappings[j] = -1;
						
						outIndex = 0;
					}
					
					// Loop over all vertices in triangle
					for (j = 0; j < 3; j++) {
						
						originalIndex = indices[i + j];
						
						if (mappings[originalIndex] >= 0)
							splitIndex = mappings[originalIndex];
						
						else {
							
							o0 = originalIndex*3 + 0;
							o1 = originalIndex*3 + 1;
							o2 = originalIndex*3 + 2;
							
							// This vertex does not yet exist in the split list and
							// needs to be copied from the long list.
							splitIndex = splitVerts.length/3;
							
							s0 = splitIndex*3 + 0;
							s1 = splitIndex*3 + 1;
							s2 = splitIndex*3 + 2;
							
							splitVerts[s0] = verts[o0];
							splitVerts[s1] = verts[o1];
							splitVerts[s2] = verts[o2];
							
							if (uvs) {
								su = splitIndex*2 + 0;
								sv = splitIndex*2 + 1;
								ou = originalIndex*2 + 0;
								ov = originalIndex*2 + 1;
								
								splitUvs[su] = uvs[ou];
								splitUvs[sv] = uvs[ov];
							}
							
							if (normals) {
								splitNormals[s0] = normals[o0];
								splitNormals[s1] = normals[o1];
								splitNormals[s2] = normals[o2];
							}
							
							if (tangents) {
								splitTangents[s0] = tangents[o0];
								splitTangents[s1] = tangents[o1];
								splitTangents[s2] = tangents[o2];
							}
							
							if (weights) {
								splitWeights[s0] = weights[o0];
								splitWeights[s1] = weights[o1];
								splitWeights[s2] = weights[o2];
							}
							
							if (jointIndices) {
								splitJointIndices[s0] = jointIndices[o0];
								splitJointIndices[s1] = jointIndices[o1];
								splitJointIndices[s2] = jointIndices[o2];
							}
							
							mappings[originalIndex] = splitIndex;
						}
						
						// Store new index, which may have come from the mapping look-up,
						// or from copying a new set of vertex data from the original vector
						splitIndices[outIndex + j] = splitIndex;
					}
					
					outIndex += 3;
				}
				
				if (splitVerts.length > 0) {
					// More was added in the last iteration of the loop.
					subs.push(constructSubGeometry(splitVerts, splitIndices, splitUvs, splitNormals, splitTangents, splitWeights, splitJointIndices, triangleOffset));
				}
				
			} else
				subs.push(constructSubGeometry(verts, indices, uvs, normals, tangents, weights, jointIndices, triangleOffset));
			
			return subs;
		}
		
		/**
		 * Build a sub-geometry from data vectors.
		 */
		public static function constructSubGeometry(verts:Vector.<Number>, indices:Vector.<uint>, uvs:Vector.<Number>, normals:Vector.<Number>, tangents:Vector.<Number>, weights:Vector.<Number>, jointIndices:Vector.<Number>, triangleOffset:int):CompactSubGeometry
		{
			var sub:CompactSubGeometry;
			
			if (weights && jointIndices) {
				// If there were weights and joint indices defined, this
				// is a skinned mesh and needs to be built from skinned
				// sub-geometries.
				sub = new SkinnedSubGeometry(weights.length/(verts.length/3));
				SkinnedSubGeometry(sub).updateJointWeightsData(weights);
				SkinnedSubGeometry(sub).updateJointIndexData(jointIndices);
				
			} else
				sub = new CompactSubGeometry();
			
			sub.updateIndexData(indices);
			sub.fromVectors(verts, uvs, normals, tangents);
			return sub;
		}
		
		/*
		 * Combines a set of separate raw buffers into an interleaved one, compatible
		 * with CompactSubGeometry. SubGeometry uses separate buffers, whereas CompactSubGeometry
		 * uses a single, combined buffer.
		 * */
		public static function interleaveBuffers(numVertices:uint, vertices:Vector.<Number> = null, normals:Vector.<Number> = null, tangents:Vector.<Number> = null, uvs:Vector.<Number> = null, suvs:Vector.<Number> = null):Vector.<Number>
		{
			
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
			for (i = 0; i < numVertices; ++i) {
				uvCompIndex = i*2;
				compIndex = i*3;
				interleavedCompIndex = i*13;
				interleavedBuffer[ interleavedCompIndex     ] = vertices? vertices[ compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 1 ] = vertices? vertices[ compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 2 ] = vertices? vertices[ compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 3 ] = normals? normals[   compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 4 ] = normals? normals[   compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 5 ] = normals? normals[   compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 6 ] = tangents? tangents[ compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 7 ] = tangents? tangents[ compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 8 ] = tangents? tangents[ compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 9 ] = uvs? uvs[          uvCompIndex     ] : 0;
				interleavedBuffer[ interleavedCompIndex + 10 ] = uvs? uvs[          uvCompIndex + 1 ] : 0;
				interleavedBuffer[ interleavedCompIndex + 11 ] = suvs? suvs[          uvCompIndex      ] : 0;
				interleavedBuffer[ interleavedCompIndex + 12 ] = suvs? suvs[          uvCompIndex + 1 ] : 0;
			}
			
			return interleavedBuffer;
		}
		
		/*
		 * returns the subGeometry index in its parent mesh subgeometries vector
		 */
		public static function getMeshSubgeometryIndex(subGeometry:ISubGeometry):uint
		{
			var index:uint;
			var subGeometries:Vector.<ISubGeometry> = subGeometry.parentGeometry.subGeometries;
			for (var i:uint = 0; i < subGeometries.length; ++i) {
				if (subGeometries[i] == subGeometry) {
					index = i;
					break;
				}
			}
			
			return index;
		}
		
		/*
		 * returns the subMesh index in its parent mesh subMeshes vector
		 */
		public static function getMeshSubMeshIndex(subMesh:SubMesh):uint
		{
			var index:uint;
			var subMeshes:Vector.<SubMesh> = subMesh.parentMesh.subMeshes;
			for (var i:uint = 0; i < subMeshes.length; ++i) {
				if (subMeshes[i] == subMesh) {
					index = i;
					break;
				}
			}
			
			return index;
		}
	}
}
