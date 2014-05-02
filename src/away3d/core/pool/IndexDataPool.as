package away3d.core.pool {
	public class IndexDataPool {
		private static const _pool:Object = {};

		public function IndexDataPool() {
		}

		public static function getItem(id:String, level:uint):IndexData {
			if (!_pool[id]) {
				_pool[id] = new Vector.<IndexData>();
			}

			var subGeometryData:Vector.<IndexData> = _pool[id];
			if (!subGeometryData[level]) subGeometryData[level] = new IndexData(level);
			return subGeometryData[level];
		}

		public static function disposeItem(id:String, level:Number):void {
			var subGeometryData:Vector.<IndexData> = _pool[id];
			subGeometryData[level].dispose();
			subGeometryData[level] = null;
		}

		public static function disposeData(id:String):void {
			var subGeometryData:Vector.<IndexData> = _pool[id];
			var len:uint = subGeometryData.length;
			for (var i:uint = 0; i < len; i++) {
				subGeometryData[i].dispose();
				subGeometryData[i] = null;
			}
			_pool[id] = null;
		}
	}

}