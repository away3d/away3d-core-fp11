package away3d.tools.helpers
{
	import away3d.core.base.CompactParticleSubGeometry;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.data.ParticleData;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
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
		
		public static function generateGeometry(geometries:Vector.<Geometry>):Geometry
		{
			//TODO
			return null;
		}
	}

}