package away3d.core.data
{
	public class RenderableListItemPool
	{
		private var _pool : Vector.<RenderableListItem>;
		private var _index : int;
		private var _poolSize : int;

		public function RenderableListItemPool()
		{
			_pool = new Vector.<RenderableListItem>();
		}

		public function getItem() : RenderableListItem
		{
			if (_index == _poolSize) {
				var item : RenderableListItem = new RenderableListItem();
				_pool[_index++] = item;
				++_poolSize;
				return item;
			}
			else return _pool[_index++];
		}

		public function freeAll() : void
		{
			_index = 0;
		}

		public function dispose() : void
		{
			_pool.length = 0;
		}
	}
}
