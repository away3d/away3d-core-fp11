package away3d.prefabs
{
	import away3d.arcane;
	import away3d.core.base.Object3D;
	import away3d.core.library.IAsset;
	import away3d.core.library.NamedAssetBase;
	import away3d.errors.AbstractMethodError;

	use namespace arcane;

	/**
	 * PrefabBase is an abstract base class for prefabs, which are prebuilt objects that allow easy cloning and updating
	 */
	public class PrefabBase extends NamedAssetBase implements IAsset
	{
		protected var _objects:Vector.<Object3D> = new Vector.<Object3D>();

		/**
		 * Creates a new PrefabBase object.
		 */
		public function PrefabBase()
		{
		}

		/**
		 * Returns a display object generated from this prefab
		 */
		public function getNewObject():Object3D
		{
			var object:Object3D = createObject();

			_objects.push(object);

			return object;
		}

		protected function createObject():Object3D
		{
			throw new AbstractMethodError();
		}

		arcane function validate():void
		{
			// To be overridden when necessary
		}
	}
}
