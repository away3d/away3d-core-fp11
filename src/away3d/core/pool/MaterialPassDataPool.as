package away3d.core.pool
{
	import away3d.arcane;
	import away3d.materials.MaterialBase;
	import away3d.materials.passes.MaterialPassBase;

	import flash.utils.Dictionary;

	use namespace arcane;

	public class MaterialPassDataPool
	{
		private var _pool:Object = {};
		private var _material:MaterialBase;

		/**
		 * //TODO
		 *
		 * @param material
		 */
		public function MaterialPassDataPool(material:MaterialBase)
		{
			_material = material;
		}

		/**
		 * //TODO
		 *
		 * @param materialPass
		 * @returns ITexture
		 */
		public function getItem(materialPass:MaterialPassBase):MaterialPassData
		{
			return (_pool[materialPass.id] || (_pool[materialPass.id] = _material.addMaterialPassData(materialPass.addMaterialPassData(new MaterialPassData(this, _material, materialPass)))));
		}

		/**
		 * //TODO
		 *
		 * @param materialPass
		 */
		public function disposeItem(materialPass:MaterialPassBase):void
		{
			materialPass.removeMaterialPassData(_pool[materialPass.id]);
			delete _pool[materialPass.id];
		}

		public function disposePool():void
		{
			for (var id:* in _pool) {
                var materialPassData:MaterialPassData = _pool[id] as MaterialPassData;
                (materialPassData.materialPass as MaterialPassBase).removeMaterialPassData(_pool[id]);
            }

			delete _pool[id];
		}
	}
}
