package away3d.tools.helpers
{
	import away3d.core.base.ParticleGeometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.base.data.ParticleData;
	import away3d.core.base.Geometry;
	import away3d.tools.helpers.data.ParticleGeometryTransform;
	
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 */
	public class ParticleGeometryHelper
	{
		public static const MAX_VERTEX:int = 65535;
		
		public static function generateGeometry(geometries:Vector.<Geometry>, transforms:Vector.<ParticleGeometryTransform> = null):ParticleGeometry
		{
			var verticesVector:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indicesVector:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			var vertexCounters:Vector.<uint> = new Vector.<uint>();
			var particles:Vector.<ParticleData> = new Vector.<ParticleData>();
			var subGeometries:Vector.<TriangleSubGeometry> = new Vector.<TriangleSubGeometry>();
			var numParticles:uint = geometries.length;
			
			var sourceSubGeometries:Vector.<SubGeometryBase>;
			var sourceSubGeometry:SubGeometryBase;
			var numSubGeometries:uint;
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var vertexCounter:uint;
			var subGeometry:TriangleSubGeometry;
			var i:int;
			var j:int;
			var sub2SubMap:Vector.<int> = new Vector.<int>;
			
			var tempVertex:Vector3D = new Vector3D;
			var tempNormal:Vector3D = new Vector3D;
			var tempTangents:Vector3D = new Vector3D;
			var tempUV:Point = new Point;
			var tempSecondaryUV:Point = new Point;

			for (i = 0; i < numParticles; i++) {
				sourceSubGeometries = geometries[i].subGeometries;
				numSubGeometries = sourceSubGeometries.length;
				for (var srcIndex:int = 0; srcIndex < numSubGeometries; srcIndex++) {
					//create a different particle subgeometry group for each source subgeometry in a particle.
					if (sub2SubMap.length <= srcIndex) {
						sub2SubMap.push(subGeometries.length);
						verticesVector.push(new Vector.<Number>);
						indicesVector.push(new Vector.<uint>);
						subGeometries.push(new TriangleSubGeometry(true));
						vertexCounters.push(0);
					}
					
					sourceSubGeometry = sourceSubGeometries[srcIndex];
					
					//add a new particle subgeometry if this source subgeometry will take us over the maxvertex limit
					if (sourceSubGeometry.numVertices + vertexCounters[sub2SubMap[srcIndex]] > MAX_VERTEX) {
						//update submap and add new subgeom vectors
						sub2SubMap[srcIndex] = subGeometries.length;
						verticesVector.push(new Vector.<Number>);
						indicesVector.push(new Vector.<uint>);
						subGeometries.push(new TriangleSubGeometry(true));
						vertexCounters.push(0);
					}
					
					j = sub2SubMap[srcIndex];
					
					//select the correct vector
					vertices = verticesVector[j];
					indices = indicesVector[j];
					vertexCounter = vertexCounters[j];
					subGeometry = subGeometries[j];
					
					var particleData:ParticleData = new ParticleData();
					particleData.numVertices = sourceSubGeometry.numVertices;
					particleData.startVertexIndex = vertexCounter;
					particleData.particleIndex = i;
					particleData.subGeometry = subGeometry;
					particles.push(particleData);
					
					vertexCounters[j] += sourceSubGeometry.numVertices;
					
					var k:int;
					var tempLen:int;
					var product:uint;
					var sourceVertices:Vector.<Number>;
					
					if (sourceSubGeometry && sourceSubGeometry.concatenateArrays) {
						tempLen = sourceSubGeometry.numVertices;
						sourceSubGeometry.numTriangles;
						sourceVertices = sourceSubGeometry.vertices;

						if (transforms) {
							var particleGeometryTransform:ParticleGeometryTransform = transforms[i];
							var vertexTransform:Matrix3D = particleGeometryTransform.vertexTransform;
							var invVertexTransform:Matrix3D = particleGeometryTransform.invVertexTransform;
							var UVTransform:Matrix = particleGeometryTransform.UVTransform;
							var stride:uint = sourceSubGeometry.getStride(TriangleSubGeometry.POSITION_DATA);

							for (k = 0; k < tempLen; k++) {
								/*
								 * 0 - 2: vertex position X, Y, Z
								 * 3 - 5: normal X, Y, Z
								 * 6 - 8: tangent X, Y, Z
								 * 9 - 10: U V
								 * 11 - 12: Secondary U V*/
								product = k*stride;

								tempVertex.x = sourceVertices[product];
								tempVertex.y = sourceVertices[product + 1];
								tempVertex.z = sourceVertices[product + 2];
								tempNormal.x = sourceVertices[product + 3];
								tempNormal.y = sourceVertices[product + 4];
								tempNormal.z = sourceVertices[product + 5];
								tempTangents.x = sourceVertices[product + 6];
								tempTangents.y = sourceVertices[product + 7];
								tempTangents.z = sourceVertices[product + 8];
								tempUV.x = sourceVertices[product + 9];
								tempUV.y = sourceVertices[product + 10];

								if(stride>11) {
									tempSecondaryUV.x = sourceVertices[product + 11];
									tempSecondaryUV.y = sourceVertices[product + 12];
								}

								if (vertexTransform) {
									tempVertex = vertexTransform.transformVector(tempVertex);
									tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
									tempTangents = invVertexTransform.deltaTransformVector(tempNormal);
								}
								if (UVTransform) {
									tempUV = UVTransform.transformPoint(tempUV);
								}
								//this is faster than that only push one data
								vertices.push(tempVertex.x, tempVertex.y, tempVertex.z, tempNormal.x,
									tempNormal.y, tempNormal.z, tempTangents.x, tempTangents.y,
									tempTangents.z, tempUV.x, tempUV.y);

								if(stride > 11) {
									vertices.push(tempSecondaryUV.x, tempSecondaryUV.y);
								}
							}
						} else {
							for (k = 0; k < tempLen; k++) {
								product = k*13;
								//this is faster than that only push one data
								vertices.push(sourceVertices[product], sourceVertices[product + 1], sourceVertices[product + 2], sourceVertices[product + 3],
									sourceVertices[product + 4], sourceVertices[product + 5], sourceVertices[product + 6], sourceVertices[product + 7],
									sourceVertices[product + 8], sourceVertices[product + 9], sourceVertices[product + 10], sourceVertices[product + 11],
									sourceVertices[product + 12]);
							}
						}
					} else {
						//Todo
					}
					
					var sourceIndices:Vector.<uint> = sourceSubGeometry.indices;
					tempLen = sourceSubGeometry.numTriangles;

					for (k = 0; k < tempLen; k++) {
						product = k*3;
						indices.push(sourceIndices[product] + vertexCounter, sourceIndices[product + 1] + vertexCounter, sourceIndices[product + 2] + vertexCounter);
					}
				}
			}
			
			var particleGeometry:ParticleGeometry = new ParticleGeometry();
			particleGeometry.particles = particles;
			particleGeometry.numParticles = numParticles;
			/** 0 - 2: vertex position X, Y, Z
			 * 3 - 5: normal X, Y, Z
			 * 6 - 8: tangent X, Y, Z
			 * 9 - 10: U V
			 * 11 - 12: Secondary U V*/
			numParticles = subGeometries.length;
			for (i = 0; i < numParticles; i++) {
				vertices = verticesVector[i];
				subGeometry = subGeometries[i];
				subGeometry.updateIndices(indicesVector[i]);
				subGeometry.updateData(TriangleSubGeometry.POSITION_DATA, vertices, 0, subGeometry.getStride(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
				subGeometry.updateData(TriangleSubGeometry.NORMAL_DATA, vertices, 3, subGeometry.getStride(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
				subGeometry.updateData(TriangleSubGeometry.TANGENT_DATA, vertices, 6, subGeometry.getStride(TriangleSubGeometry.TANGENT_DATA), TriangleSubGeometry.TANGENT_FORMAT);
				subGeometry.updateData(TriangleSubGeometry.UV_DATA, vertices, 9, subGeometry.getStride(TriangleSubGeometry.UV_DATA), TriangleSubGeometry.UV_FORMAT);
				subGeometry.updateData(TriangleSubGeometry.SECONDARY_UV_DATA, vertices, 11, subGeometry.getStride(TriangleSubGeometry.SECONDARY_UV_DATA), TriangleSubGeometry.SECONDARY_UV_FORMAT);
				particleGeometry.addSubGeometry(subGeometry);
			}
			
			return particleGeometry;
		}
	}

}
