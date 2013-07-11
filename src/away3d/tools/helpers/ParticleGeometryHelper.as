package away3d.tools.helpers
{
	import away3d.core.base.ParticleGeometry;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.data.ParticleData;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
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
			var subGeometries:Vector.<CompactSubGeometry> = new Vector.<CompactSubGeometry>();
			var numParticles:uint = geometries.length;
			
			var sourceSubGeometries:Vector.<ISubGeometry>;
			var sourceSubGeometry:ISubGeometry;
			var numSubGeometries:uint;
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var vertexCounter:uint;
			var subGeometry:CompactSubGeometry;
			var i:int;
			var j:int;
			var sub2SubMap:Vector.<int> = new Vector.<int>;
			
			var tempVertex:Vector3D = new Vector3D;
			var tempNormal:Vector3D = new Vector3D;
			var tempTangents:Vector3D = new Vector3D;
			var tempUV:Point = new Point;
			
			for (i = 0; i < numParticles; i++) {
				sourceSubGeometries = geometries[i].subGeometries;
				numSubGeometries = sourceSubGeometries.length;
				for (var srcIndex:int = 0; srcIndex < numSubGeometries; srcIndex++) {
					//create a different particle subgeometry group for each source subgeometry in a particle.
					if (sub2SubMap.length <= srcIndex) {
						sub2SubMap.push(subGeometries.length);
						verticesVector.push(new Vector.<Number>);
						indicesVector.push(new Vector.<uint>);
						subGeometries.push(new CompactSubGeometry());
						vertexCounters.push(0);
					}
					
					sourceSubGeometry = sourceSubGeometries[srcIndex];
					
					//add a new particle subgeometry if this source subgeometry will take us over the maxvertex limit
					if (sourceSubGeometry.numVertices + vertexCounters[sub2SubMap[srcIndex]] > MAX_VERTEX) {
						//update submap and add new subgeom vectors
						sub2SubMap[srcIndex] = subGeometries.length;
						verticesVector.push(new Vector.<Number>);
						indicesVector.push(new Vector.<uint>);
						subGeometries.push(new CompactSubGeometry());
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
					var compact:CompactSubGeometry = sourceSubGeometry as CompactSubGeometry;
					var product:uint;
					var sourceVertices:Vector.<Number>;
					
					if (compact) {
						tempLen = compact.numVertices;
						compact.numTriangles;
						sourceVertices = compact.vertexData;
						
						if (transforms) {
							var particleGeometryTransform:ParticleGeometryTransform = transforms[i];
							var vertexTransform:Matrix3D = particleGeometryTransform.vertexTransform;
							var invVertexTransform:Matrix3D = particleGeometryTransform.invVertexTransform;
							var UVTransform:Matrix = particleGeometryTransform.UVTransform;
							
							for (k = 0; k < tempLen; k++) {
								/*
								 * 0 - 2: vertex position X, Y, Z
								 * 3 - 5: normal X, Y, Z
								 * 6 - 8: tangent X, Y, Z
								 * 9 - 10: U V
								 * 11 - 12: Secondary U V*/
								product = k*13;
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
								if (vertexTransform) {
									tempVertex = vertexTransform.transformVector(tempVertex);
									tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
									tempTangents = invVertexTransform.deltaTransformVector(tempNormal);
								}
								if (UVTransform)
									tempUV = UVTransform.transformPoint(tempUV);
								//this is faster than that only push one data
								vertices.push(tempVertex.x, tempVertex.y, tempVertex.z, tempNormal.x,
									tempNormal.y, tempNormal.z, tempTangents.x, tempTangents.y,
									tempTangents.z, tempUV.x, tempUV.y, sourceVertices[product + 11],
									sourceVertices[product + 12]);
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
					
					var sourceIndices:Vector.<uint> = sourceSubGeometry.indexData;
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
			
			numParticles = subGeometries.length;
			for (i = 0; i < numParticles; i++) {
				subGeometry = subGeometries[i];
				subGeometry.updateData(verticesVector[i]);
				subGeometry.updateIndexData(indicesVector[i]);
				particleGeometry.addSubGeometry(subGeometry);
			}
			
			return particleGeometry;
		}
	}

}
