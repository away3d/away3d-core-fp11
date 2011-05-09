package away3d.materials.utils
{
	/**
	 * A single register element (an entire register or a single register's component) used by the RegisterPool.
	 */
	public class ShaderRegisterElement
	{
		private var _regName : String;
		private var _index : int;
		private var _component : String;

		/**
		 * Creates a new ShaderRegisterElement object.
		 * @param regName The name of the register.
		 * @param index The index of the register.
		 * @param component The register's component, if not the entire register is represented.
		 */
		public function ShaderRegisterElement(regName : String, index : int, component : String = null)
		{
			_regName = regName;
			_index = index;
			_component = component;
		}

		/**
		 * Converts the register or the components AGAL string representation.
		 */
		public function toString() : String
		{
			if (_index >= 0)
				return _regName + _index + (_component? "."+_component : "");
			else
				return _regName + (_component? "."+_component : "");
		}

		/**
		 * The register's name.
		 */
		public function get regName() : String
		{
			return _regName;
		}

		/**
		 * The register's index.
		 */
		public function get index() : int
		{
			return _index;
		}

		/**
		 * The register's component, if not the entire register is represented.
		 */
		public function get component() : String
		{
			return _component;
		}
	}
}
