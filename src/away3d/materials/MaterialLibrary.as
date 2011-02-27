package away3d.materials
{
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;

	use namespace arcane;

	/**
	 * The MaterialLibrary singleton class provides a central access and management point for any materials in existence.
	 */
	public class MaterialLibrary
	{
		private static var _instance : MaterialLibrary;

		private var _highestId : uint;
		// materials by id:
		private var _materials : Vector.<MaterialBase> = new Vector.<MaterialBase>();
		private var _names : Vector.<String> = new Vector.<String>();

		/**
		 * Creates a new MaterialLibrary instance.
		 * @private
		 */
		public function MaterialLibrary(se : SingletonEnforcer)
		{

		}

		/**
		 * Retrieves the singleton MaterialLibrary instance.
		 */
		public static function getInstance() : MaterialLibrary
		{
			return _instance ||= new MaterialLibrary(new SingletonEnforcer());
		}

		/**
		 * Retrieves the material with the given id.
		 */
		public function getMaterialById(id : int) : MaterialBase
		{
			return _materials[id];
		}

		/**
		 * Retrieves the material with the given name and namespace.
		 * @param name The name of the material to retrieve.
		 * @param materialNamespace An optional namespace to which the material belongs.
		 * @return The material corresponding to the name an namespace
		 */
		public function getMaterial(name : String, materialNamespace : String = null) : MaterialBase
		{
			var totalName : String;
			var i : int;

			materialNamespace ||= "";
			totalName = materialNamespace + "/" + name;

			i = _names.indexOf(totalName);
			if (i >= 0) return _materials[i];
			else return null;
		}

		/**
		 * Replaces a material with a given name and namespace with a new material.
		 * @param name The name of the material to change.
		 * @param material The new material to assign.
		 * @param materialNamespace An optional namespace to which the material belongs.
		 */
		public function setMaterial(name : String, material : MaterialBase, materialNamespace : String = null) : void
		{
			materialNamespace ||= "";
			var oldMaterial : MaterialBase = getMaterial(name, materialNamespace);
			var owners : Vector.<IMaterialOwner> = oldMaterial.owners;
			var temp : String = material.name;

			unsetName(oldMaterial);

			while (owners.length > 0)
				owners[uint(0)].material = material;

			material.name = name;
			oldMaterial.name = temp;
		}

		/**
		 * Registers the material when created. Called by MaterialBase.
		 * @private
		 */
		arcane function registerMaterial(material : MaterialBase) : void
		{
			var uniqueName : String = getUniqueName(material);
			material.setUniqueId(_highestId);
			_materials[_highestId] = material;
			material._name = uniqueName;
			_names[_highestId] = material.materialNamespace + "/" + uniqueName;
			++_highestId;
		}

		/**
		 * Removes a material from the library when created. Called by MaterialBase.
		 * @private
		 */
		arcane function unregisterMaterial(material : MaterialBase) : void
		{
			var id : int = material.uniqueId;
			_names[id] = null;
			_materials[id] = null;
			material.setUniqueId(-1);
		}

		/**
		 * Releases a material's name.
		 * @private
		 */
		arcane function unsetName(material : MaterialBase) : void
		{
			var id : int = material.uniqueId;
			_names[id] = null;
			delete _names[id];
		}

		/**
		 * Registers a material's name.
		 * @private
		 */
		arcane function setName(material : MaterialBase) : void
		{
			material._name = getUniqueName(material);
			var id : int = material.uniqueId;
			_names[id] = material.materialNamespace + "/" + material.name;
		}

		/**
		 * Returns a unique name for a given material. The material's name is kept intact if it already is unique,
		 * or a unique number is appended.
		 */
		private function getUniqueName(material : MaterialBase) : String
		{
			var space : String = material.materialNamespace;
			var name : String = material.name;
			var tryName : String = name;
			var append : uint;
			var i : int;

			do {
				i = _names.indexOf(space+"/"+tryName);
				if (i >= 0)
					tryName = name+"_"+(append++);
				else
					return tryName;
			} while (true);

			// can't occur
			return null;
		}
	}
}

class SingletonEnforcer {}