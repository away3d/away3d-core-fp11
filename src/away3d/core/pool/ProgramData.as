package away3d.core.pool
{
	import away3d.managers.Stage3DProxy;

    import flash.display3D.Program3D;

    public class ProgramData
	{
		public static var PROGRAMDATA_ID_COUNT:int = 0;

		private var _pool:ProgramDataPool;
		private var _key:String;

		public var stage3DProxy:Stage3DProxy;

		public var usages:int = 0;

		public var program:Program3D;

		public var id:int;

		public function ProgramData(pool:ProgramDataPool, stage3DProxy:Stage3DProxy, key:String)
		{
			_pool = pool;
			_key = key;
			this.stage3DProxy = stage3DProxy;
			stage3DProxy.registerProgram(this);
		}

		/**
		 *
		 */
		public function dispose():void
		{
			this.usages--;

			if (!usages) {
				_pool.disposeItem(_key);

				stage3DProxy.unregisterProgram(this);

				if (program)
					program.dispose();
			}

			program = null;
		}
	}
}
