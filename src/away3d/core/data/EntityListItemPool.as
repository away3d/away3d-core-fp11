package away3d.core.data
{
	
	public class EntityListItemPool
	{
		private var _pool:Vector.<EntityListItem>;
		private var _index:int;
		private var _poolSize:int;
		
		public function EntityListItemPool()
		{
			_pool = new Vector.<EntityListItem>();
		}
		
		public function getItem():EntityListItem
		{
			var item:EntityListItem;
			if (_index == _poolSize) {
				item = new EntityListItem();
				_pool[_index++] = item;
				++_poolSize;
			} else
				item = _pool[_index++];
			return item;
		}
		
		public function freeAll():void
		{
			_index = 0;
		}
		
		public function dispose():void
		{
			_pool.length = 0;
		}
	}
}
