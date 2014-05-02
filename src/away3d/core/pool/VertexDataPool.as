package away3d.core.pool {
	import away3d.core.base.SubGeometryBase;

	public class VertexDataPool {
		private static const _pool:Object = {};

		public function VertexDataPool() {
		}

		public static function getItem(subGeometry:SubGeometryBase, indexData:IndexData, dataType:String):VertexData {
			if (subGeometry.concatenateArrays)
				dataType = SubGeometryBase.VERTEX_DATA;

			var subGeometryDictionary:Object = VertexDataPool._pool[subGeometry.id] || (VertexDataPool._pool[subGeometry.id] = {});
			var subGeometryData:Vector.<VertexData> = (subGeometryDictionary[dataType] || (subGeometryDictionary[dataType] = new Vector.<VertexData>()));

			var vertexData:VertexData = subGeometryData[indexData.level] || (subGeometryData[indexData.level] = new VertexData(subGeometry, dataType));
			vertexData.updateData(indexData.originalIndices, indexData.indexMappings);

			return vertexData;
		}

		public static function disposeItem(subGeometry:SubGeometryBase, level:Number, dataType:String):void {
			var subGeometryDictionary:Object = _pool[subGeometry.id];
			var subGeometryData:Vector.<VertexData> = subGeometryDictionary[dataType];
			subGeometryData[level].dispose();
			subGeometryData[level] = null;
		}

		public static function disposeData(subGeometry:SubGeometryBase):void {
			var subGeometryDictionary:Object = _pool[subGeometry.id];

			for (var key:* in subGeometryDictionary) {
				var subGeometryData:Vector.<VertexData> = subGeometryDictionary[key];

				var len:uint = subGeometryData.length;
				for (var i:uint = 0; i < len; i++) {
					subGeometryData[i].dispose();
					subGeometryData[i] = null;
				}
			}

			_pool[subGeometry.id] = null;
		}
	}
}
