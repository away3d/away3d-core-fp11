package away3d.tools.utils
{
	import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SkinnedSubGeometry;
	
	use namespace arcane;

	public class GeomUtil
	{
		/**
		 * Build a list of sub-geometries from raw data vectors, splitting them up in 
		 * such a way that they won't exceed buffer length limits.
		*/
		public static function fromVectors(verts : Vector.<Number>, indices : Vector.<uint>, uvs : Vector.<Number>,
												normals : Vector.<Number>, tangents : Vector.<Number>,
												weights : Vector.<Number>, jointIndices : Vector.<Number>,
												triangleOffset : int = 0) : Vector.<ISubGeometry>
		{
			const LIMIT_VERTS : uint = 3 * 0xffff;
			const LIMIT_INDICES : uint = 3 * 0xffff; // could be set to (15 * 0xffff) +13 = results in fewer subgeometrys, but possible more memory;
			
			var subs : Vector.<ISubGeometry> = new Vector.<ISubGeometry>();
			
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
			
			if ((indices.length >= LIMIT_INDICES)||(verts.length>=LIMIT_VERTS)) {
				var i : uint, len : uint, outIndex : uint, j : uint;
				var splitVerts : Vector.<Number> = new Vector.<Number>();
				var splitIndices : Vector.<uint> = new Vector.<uint>();
				var splitUvs : Vector.<Number> = (uvs != null)? new Vector.<Number>() : null;
				var splitNormals : Vector.<Number> = (normals != null)? new Vector.<Number>() : null;
				var splitTangents : Vector.<Number> = (tangents != null)? new Vector.<Number>() : null;
				var splitWeights : Vector.<Number> = (weights != null)? new Vector.<Number>() : null;
				var splitJointIndices: Vector.<Number> = (jointIndices != null)? new Vector.<Number>() : null;
				
				var mappings : Vector.<int> = new Vector.<int>(verts.length/3, true);
				i = mappings.length;
				while (i-- > 0) 
					mappings[i] = -1;
				
				var originalIndex : uint;
				var splitIndex : uint;
				var o0 : uint, o1 : uint, o2 : uint, s0 : uint, s1 : uint, s2 : uint,
				su : uint, ou : uint, sv : uint, ov : uint;
				// Loop over all triangles
				outIndex = 0;
				len = indices.length;

				for (i=0; i<len; i+=3) {
					splitIndex = splitVerts.length + 6 ;

					if ( ( (outIndex+2) >= LIMIT_INDICES) || (splitIndex>=LIMIT_VERTS) ) {
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
					for (j=0; j<3; j++) {
						
						originalIndex = indices[i + j];
                        
						if (mappings[originalIndex] >= 0) {
							splitIndex = mappings[originalIndex];

						} else {
							
							o0 = originalIndex*3 + 0;
							o1 = originalIndex*3 + 1;
							o2 = originalIndex*3 + 2;
							
							// This vertex does not yet exist in the split list and
							// needs to be copied from the long list.
							splitIndex = splitVerts.length / 3;

							s0 = splitIndex*3+0;
							s1 = splitIndex*3+1;
							s2 = splitIndex*3+2;
							
							splitVerts[s0] = verts[o0];
							splitVerts[s1] = verts[o1];
							splitVerts[s2] = verts[o2];
							
							if (uvs) {
								su = splitIndex*2+0;
								sv = splitIndex*2+1;
								ou = originalIndex*2+0;
								ov = originalIndex*2+1;
								
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
						splitIndices[outIndex+j] = splitIndex;
					}
					
					outIndex += 3;
				}
				
				if (splitVerts.length > 0) {
					// More was added in the last iteration of the loop.
					subs.push(constructSubGeometry(splitVerts, splitIndices, splitUvs, splitNormals, splitTangents, splitWeights, splitJointIndices,triangleOffset));
				}

			} else {
				subs.push(constructSubGeometry(verts, indices, uvs, normals, tangents, weights, jointIndices, triangleOffset));
			}
			
			return subs;
		}
		
		/**
		* Build a sub-geometry from data vectors.
		*/
		public static function constructSubGeometry(	verts : Vector.<Number>, indices : Vector.<uint>, uvs : Vector.<Number>, 
										normals : Vector.<Number>, tangents : Vector.<Number>,
										weights : Vector.<Number>, jointIndices : Vector.<Number>,
										triangleOffset : int) : CompactSubGeometry
		{
			var sub : CompactSubGeometry;
			
			if (weights && jointIndices) {
				// If there were weights and joint indices defined, this
				// is a skinned mesh and needs to be built from skinned
				// sub-geometries.
				sub = new SkinnedSubGeometry(weights.length / (verts.length/3));
				SkinnedSubGeometry(sub).updateJointWeightsData(weights);
				SkinnedSubGeometry(sub).updateJointIndexData(jointIndices);

			} else {
				sub = new CompactSubGeometry();
			}
			
			sub.updateIndexData(indices);
			sub.fromVectors(verts, uvs, normals, tangents);
			return sub;
		}

	}
}