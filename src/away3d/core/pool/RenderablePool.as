package away3d.core.pool
{
	import away3d.core.base.IMaterialOwner;

	import flash.utils.Dictionary;

	public class RenderablePool
	{
		private static const _pools:Object = {};

		private const _pool:Object = {};
		private var _renderableClass:Class;

		/**
		 * //TODO
		 *
		 * @param renderableClass
		 */
		public function RenderablePool(renderableClass:Class)
		{
			_renderableClass = renderableClass;
		}

		/**
		 * //TODO
		 *
		 * @param materialOwner
		 * @returns IRenderable
		 */
		public function getItem(materialOwner:IMaterialOwner):IRenderable
		{
			var renderable:IRenderable = _pool[materialOwner.id];
			if (!renderable) {
				renderable = materialOwner.addRenderable(new _renderableClass(this, materialOwner));
				_pool[materialOwner.id] = renderable;
			}
			return renderable;
		}

		/**
		 * //TODO
		 *
		 * @param materialOwner
		 */
		public function disposeItem(materialOwner:IMaterialOwner):void
		{
			materialOwner.removeRenderable(_pool[materialOwner.id]);
			_pool[materialOwner.id] = null;
		}

		/**
		 * //TODO
		 *
		 * @param renderableClass
		 * @returns RenderablePool
		 */
		public static function getPool(renderableClass:Class):RenderablePool
		{
			var pool:RenderablePool = _pools[renderableClass.id];
			if (!pool) {
				pool = _pools[renderableClass.id] = new RenderablePool(renderableClass);
			}
			return pool;
		}
	}
}
