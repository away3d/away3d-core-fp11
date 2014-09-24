package away3d.core.pool
{
	import away3d.managers.Stage3DProxy;

	public class ProgramDataPool
	{
		private var _pool:Object = {};
		private var _context:Stage3DProxy;

		/**
		 * //TODO
		 *
		 * @param context
		 */
		public function ProgramDataPool(context:Stage3DProxy)
		{
			_context = context;
		}

		/**
		 * //TODO
		 *
		 * @param key
		 * @returns ITexture
		 */
		public function getItem(key:String):ProgramData
		{
			return _pool[key] || (_pool[key] = new ProgramData(this, _context, key));
		}

		/**
		 * //TODO
		 *
		 * @param key
		 */
		public function disposeItem(key:String):void
		{
			_pool[key] = null;
		}
	}
}
