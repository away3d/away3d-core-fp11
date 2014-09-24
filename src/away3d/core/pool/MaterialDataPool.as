package away3d.core.pool
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
	import away3d.materials.MaterialBase;

	use namespace arcane;

	public class MaterialDataPool
	{
		private var _pool:Object = {};
		private var _context:Stage3DProxy;

		/**
		 * //TODO
		 *
		 * @param context
		 */
		public function MaterialDataPool(context:Stage3DProxy)
		{
			this._context = context;
		}

		/**
		 * //TODO
		 *
		 * @param material
		 * @returns ITexture
		 */
		public function getItem(material:MaterialBase):MaterialData
		{
			return (_pool[material.id] || (_pool[material.id] = material.addMaterialData(new MaterialData(this, _context, material))))
		}

		/**
		 * //TODO
		 *
		 * @param material
		 */
		public function disposeItem(material:MaterialBase):void
		{
			material.removeMaterialData(_pool[material.id]);
			_pool[material.id] = null;
		}
	}
}
