package away3d.tools.helpers
{
	import away3d.core.base.CompactParticleSubGeometry;
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
		
		public static function generateCompactGeometry(geometries:Vector.<Geometry>):Geometry
		{
			var _vertexDatas:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;
			var _indicesVector:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>;
			var _vertexCounters:Vector.<uint> = new Vector.<uint>;
			var _particleDatasVector:Vector.<Vector.<ParticleData>> = new Vector.<Vector.<ParticleData>>;
			var len:uint = geometries.length;
			
			var sourceGeometry:Geometry;
			var sourceSubGeometries:Vector.<ISubGeometry>;
			var sourceSubGeomerty:ISubGeometry;
			var numSub:uint;
			var vertexData:Vector.<Number>;
			var _indices:Vector.<uint>;
			var vertexCounter:uint;
			var i:int;
			
			for (i = 0; i < len; i++)
			{
				sourceSubGeometries = geometries[i].subGeometries;
				numSub = sourceSubGeometries.length;
				for (var j:int = 0; j < numSub; j++)
				{
					sourceSubGeomerty = sourceSubGeometries[j];
					if (_vertexDatas.length <= j)
					{
						_vertexDatas.push(new Vector.<Number>);
						_indicesVector.push(new Vector.<uint>);
						_particleDatasVector.push(new Vector.<ParticleData>);
						_vertexCounters.push(0);
					}
					vertexData = _vertexDatas[j];
					_indices = _indicesVector[j];
					_particleDatasVector[j];
					vertexCounter = _vertexCounters[j];
					var particleData:ParticleData = new ParticleData;
					particleData.numVertices = sourceSubGeomerty.numVertices;
					particleData.numTriangles = sourceSubGeomerty.numTriangles;
					particleData.startVertexIndex = vertexCounter;
					particleData.particleIndex = i;
					_particleDatasVector[j].push(particleData);
					
					_vertexCounters[j] += particleData.numVertices;
					
					var k:int;
					var tempLen:int;
					var compact:CompactSubGeometry = sourceSubGeomerty as CompactSubGeometry;
					var product:uint;
					var sourceVertexData:Vector.<Number>;
					if (compact)
					{
						tempLen = compact.numVertices;
						compact.numTriangles
						sourceVertexData = compact.vertexData;
						for (k = 0; k < tempLen; k++)
						{
							product = k * 13;
							//this is faster than that only push one data
							vertexData.push(sourceVertexData[product], sourceVertexData[product + 1], sourceVertexData[product + 2], sourceVertexData[product + 3],
											sourceVertexData[product + 4], sourceVertexData[product + 5], sourceVertexData[product + 6], sourceVertexData[product + 7],
											sourceVertexData[product + 8], sourceVertexData[product + 9], sourceVertexData[product + 10], sourceVertexData[product + 11],
											sourceVertexData[product + 12]);
						}
					}
					else
					{
						//Todo
					}
					
					var sourceIndexices:Vector.<uint> = sourceSubGeomerty.indexData;
					tempLen = sourceSubGeomerty.numTriangles;
					for (k = 0; k < tempLen; k++)
					{
						product = k * 3;
						_indices.push(sourceIndexices[product] + vertexCounter, sourceIndexices[product + 1] + vertexCounter, sourceIndexices[product + 2] + vertexCounter);
					}
				}
			}
			
			var result:Geometry = new Geometry();
			var particleSubGeometry:CompactParticleSubGeometry;
			len = _vertexDatas.length;
			for (i = 0; i < len; i++)
			{
				particleSubGeometry = new CompactParticleSubGeometry();
				particleSubGeometry.particles = _particleDatasVector[i];
				particleSubGeometry.updateData(_vertexDatas[i]);
				particleSubGeometry.updateIndexData(_indicesVector[i]);
				result.addSubGeometry(particleSubGeometry);
			}
			return result;
		}
		
		//for performance, don't combine it with generateCompactGeometry
		public static function generateCompactGeometryWithTransform(geometries:Vector.<Geometry>,transforms:Vector.<ParticleGeometryTransform>):Geometry
		{
			var _vertexDatas:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;
			var _indicesVector:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>;
			var _vertexCounters:Vector.<uint> = new Vector.<uint>;
			var _particleDatasVector:Vector.<Vector.<ParticleData>> = new Vector.<Vector.<ParticleData>>;
			var len:uint = geometries.length;
			
			var sourceGeometry:Geometry;
			var sourceSubGeometries:Vector.<ISubGeometry>;
			var sourceSubGeomerty:ISubGeometry;
			var numSub:uint;
			var vertexData:Vector.<Number>;
			var _indices:Vector.<uint>;
			var vertexCounter:uint;
			var i:int;
			
			var tempVertex:Vector3D = new Vector3D;
			var tempNormal:Vector3D = new Vector3D;
			var tempTangents:Vector3D = new Vector3D;
			var tempUV:Point = new Point;
			
			for (i = 0; i < len; i++)
			{
				sourceSubGeometries = geometries[i].subGeometries;
				numSub = sourceSubGeometries.length;
				for (var j:int = 0; j < numSub; j++)
				{
					sourceSubGeomerty = sourceSubGeometries[j];
					if (_vertexDatas.length <= j)
					{
						_vertexDatas.push(new Vector.<Number>);
						_indicesVector.push(new Vector.<uint>);
						_particleDatasVector.push(new Vector.<ParticleData>);
						_vertexCounters.push(0);
					}
					vertexData = _vertexDatas[j];
					_indices = _indicesVector[j];
					_particleDatasVector[j];
					vertexCounter = _vertexCounters[j];
					var particleData:ParticleData = new ParticleData;
					particleData.numVertices = sourceSubGeomerty.numVertices;
					particleData.numTriangles = sourceSubGeomerty.numTriangles;
					particleData.startVertexIndex = vertexCounter;
					particleData.particleIndex = i;
					_particleDatasVector[j].push(particleData);
					
					_vertexCounters[j] += particleData.numVertices;
					
					var k:int;
					var tempLen:int;
					var compact:CompactSubGeometry = sourceSubGeomerty as CompactSubGeometry;
					var product:uint;
					var sourceVertexData:Vector.<Number>;
					
					var particleGeometryTransform:ParticleGeometryTransform = transforms[i];
					var vertexTransform:Matrix3D = particleGeometryTransform.getSubVertexTransform(j);
					var invVertexTransform:Matrix3D = particleGeometryTransform.getSubInvVertexTransform(j);
					var UVTransform:Matrix = particleGeometryTransform.getSubUVTransform(j);
					
					if (compact)
					{
						tempLen = compact.numVertices;
						compact.numTriangles
						sourceVertexData = compact.vertexData;
						for (k = 0; k < tempLen; k++)
						{
							/*
							* 0 - 2: vertex position X, Y, Z
							 * 3 - 5: normal X, Y, Z
							 * 6 - 8: tangent X, Y, Z
							 * 9 - 10: U V
							 * 11 - 12: Secondary U V*/
							product = k * 13;
							tempVertex.x = sourceVertexData[product];
							tempVertex.y = sourceVertexData[product + 1];
							tempVertex.z = sourceVertexData[product + 2];
							tempNormal.x = sourceVertexData[product + 3];
							tempNormal.y = sourceVertexData[product + 4];
							tempNormal.z = sourceVertexData[product + 5];
							tempTangents.x = sourceVertexData[product + 6];
							tempTangents.y = sourceVertexData[product + 7];
							tempTangents.z = sourceVertexData[product + 8];
							tempUV.x = sourceVertexData[product + 9];
							tempUV.y = sourceVertexData[product + 10];
							if (vertexTransform)
							{
								tempVertex = vertexTransform.transformVector(tempVertex);
								tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
								tempTangents = invVertexTransform.deltaTransformVector(tempNormal);
							}
							if (UVTransform)
							{
								tempUV = UVTransform.transformPoint(tempUV);
							}
							//this is faster than that only push one data
							vertexData.push(tempVertex.x, tempVertex.y, tempVertex.z, tempNormal.x,
											tempNormal.y, tempNormal.z, tempTangents.x, tempTangents.y,
											tempTangents.z, tempUV.x, tempUV.y, sourceVertexData[product + 11],
											sourceVertexData[product + 12]);
						}
					}
					else
					{
						//Todo
					}
					
					var sourceIndexices:Vector.<uint> = sourceSubGeomerty.indexData;
					tempLen = sourceSubGeomerty.numTriangles;
					for (k = 0; k < tempLen; k++)
					{
						product = k * 3;
						_indices.push(sourceIndexices[product] + vertexCounter, sourceIndexices[product + 1] + vertexCounter, sourceIndexices[product + 2] + vertexCounter);
					}
				}
			}
			
			var result:Geometry = new Geometry();
			var particleSubGeometry:CompactParticleSubGeometry;
			len = _vertexDatas.length;
			for (i = 0; i < len; i++)
			{
				particleSubGeometry = new CompactParticleSubGeometry();
				particleSubGeometry.particles = _particleDatasVector[i];
				particleSubGeometry.updateData(_vertexDatas[i]);
				particleSubGeometry.updateIndexData(_indicesVector[i]);
				result.addSubGeometry(particleSubGeometry);
			}
			return result;
		}
		
		public static function generateGeometry(geometries:Vector.<Geometry>):Geometry
		{
			//TODO
			return null;
		}
	}

}