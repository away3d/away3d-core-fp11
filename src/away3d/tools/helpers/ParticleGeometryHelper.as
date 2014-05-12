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
			var indicesVector:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			var positionsVector:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var normalsVector:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var tangentsVector:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var uvsVector:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();

			var vertexCounters:Vector.<uint> = new Vector.<uint>();
			var particles:Vector.<ParticleData> = new Vector.<ParticleData>();
			var subGeometries:Vector.<TriangleSubGeometry> = new Vector.<TriangleSubGeometry>();
			var numParticles:uint = geometries.length;

			var sourceSubGeometries:Vector.<SubGeometryBase>;
			var sourceSubGeometry:SubGeometryBase;
			var numSubGeometries:uint;
			var indices:Vector.<uint>;
			var positions:Vector.<Number>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;
			var uvs:Vector.<Number>;
			var vertexCounter:uint;
			var subGeometry:TriangleSubGeometry;
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
						indicesVector.push(new Vector.<uint>);
						positionsVector.push(new Vector.<Number>());
						normalsVector.push(new Vector.<Number>());
						tangentsVector.push(new Vector.<Number>());
						uvsVector.push(new Vector.<Number>());
						subGeometries.push(new TriangleSubGeometry(true));
						vertexCounters.push(0);
					}

					sourceSubGeometry = sourceSubGeometries[srcIndex];

					//add a new particle subgeometry if this source subgeometry will take us over the maxvertex limit
					if (sourceSubGeometry.numVertices + vertexCounters[sub2SubMap[srcIndex]] > MAX_VERTEX) {
						//update submap and add new subgeom vectors
						sub2SubMap[srcIndex] = subGeometries.length;
						indicesVector.push(new Vector.<uint>);
						positionsVector.push(new Vector.<Number>());
						normalsVector.push(new Vector.<Number>());
						tangentsVector.push(new Vector.<Number>());
						uvsVector.push(new Vector.<Number>());
						subGeometries.push(new TriangleSubGeometry(true));
						vertexCounters.push(0);
					}

					j = sub2SubMap[srcIndex];

					//select the correct vector
					indices = indicesVector[j];
					positions = positionsVector[j];
					normals = normalsVector[j];
					tangents = tangentsVector[j];
					uvs = uvsVector[j];
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
					var compact:TriangleSubGeometry = sourceSubGeometry as TriangleSubGeometry;
					var product:uint;
					var sourcePositions:Vector.<Number>;
					var sourceNormals:Vector.<Number>;
					var sourceTangents:Vector.<Number>;
					var sourceUVs:Vector.<Number>;

					if (compact) {
						tempLen = compact.numVertices;
						compact.numTriangles;
						sourcePositions = compact.positions;
						sourceNormals = compact.vertexNormals;
						sourceTangents = compact.vertexTangents;
						sourceUVs = compact.uvs;
						var stride:uint = compact.getStride(SubGeometryBase.VERTEX_DATA);

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
								product = k*3;
								tempVertex.x = sourcePositions[product];
								tempVertex.y = sourcePositions[product + 1];
								tempVertex.z = sourcePositions[product + 2];
								tempNormal.x = sourceNormals[product];
								tempNormal.y = sourceNormals[product + 1];
								tempNormal.z = sourceNormals[product + 2];
								tempTangents.x = sourceTangents[product];
								tempTangents.y = sourceTangents[product + 1];
								tempTangents.z = sourceTangents[product + 2];
								tempUV.x = sourceUVs[k*2];
								tempUV.y = sourceUVs[k*2 + 1];
								if (vertexTransform) {
									tempVertex = vertexTransform.transformVector(tempVertex);
									tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
									tempTangents = invVertexTransform.deltaTransformVector(tempNormal);
								}
								if (UVTransform)
									tempUV = UVTransform.transformPoint(tempUV);
								//this is faster than that only push one data
								sourcePositions.push(tempVertex.x, tempVertex.y, tempVertex.z);
								sourceNormals.push(tempNormal.x, tempNormal.y, tempNormal.z);
								sourceTangents.push(tempTangents.x, tempTangents.y, tempTangents.z);
								sourceUVs.push(tempUV.x, tempUV.y);
							}
						} else {
							for (k = 0; k < tempLen; k++) {
								product = k*3;
								//this is faster than that only push one data
								positions.push(sourcePositions[product], sourcePositions[product + 1], sourcePositions[product + 2]);
								normals.push(sourceNormals[product], sourceNormals[product + 1], sourceNormals[product + 2]);
								tangents.push(sourceTangents[product], sourceTangents[product + 1], sourceTangents[product + 2]);
								uvs.push(sourceUVs[k*2], sourceUVs[k*2 + 1]);
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

			numParticles = subGeometries.length;
			for (i = 0; i < numParticles; i++) {
				subGeometry = subGeometries[i];
				subGeometry.autoDeriveNormals = false;
				subGeometry.autoDeriveTangents = false;
				subGeometry.updateIndices(indicesVector[i]);
				subGeometry.updatePositions(positionsVector[i]);
				subGeometry.updateVertexNormals(normalsVector[i]);
				subGeometry.updateVertexTangents(tangentsVector[i]);
				subGeometry.updateUVs(uvsVector[i]);

				particleGeometry.addSubGeometry(subGeometry);
			}

			return particleGeometry;
		}
	}

}