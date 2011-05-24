package away3d.materials.utils
{
	/**
	 * RegisterPool is used by the shader compilation process to keep track of which registers of a certain type are
	 * currently used. Either entire registers can be requested and locked, or single components (x, y, z, w) of a
	 * single register.
	 */
	internal class RegisterPool
	{
		private var _regName : String;
		private var _vectorRegisters : Vector.<ShaderRegisterElement>;
		private var _registerComponents : Array;
		private var _usedSingleCount : Array;
		private var _usedVectorCount : Vector.<uint>;
		private var _regCount : int;

		private var _persistent : Boolean;

		private static const COMPONENTS : Array = ["x", "y", "z", "w"];

		/**
		 * Creates a new RegisterPool object.
		 * @param regName The base name of the register type.
		 * @param regCount The amount of available registers of this type.
		 * @param persistent Whether or not registers, once reserved, can be freed again.
		 */
		public function RegisterPool(regName : String, regCount : int, persistent : Boolean = true)
		{
			_regName = regName;
			_regCount = regCount;
			_persistent = persistent;
			initRegisters(regName, regCount);
		}

		/**
		 * Retrieve an entire vector register that's still available.
		 */
		public function requestFreeVectorReg() : ShaderRegisterElement
		{
			for (var i : int = 0; i < _regCount; ++i)
				if (!isRegisterUsed(i)) {
					if (_persistent) addUsage(_vectorRegisters[i], 1);
					return _vectorRegisters[i];
				}

			throw new Error("Register overflow!");
		}

		/**
		 * Retrieve a single vector component that's still available.
		 */
		public function requestFreeRegComponent() : ShaderRegisterElement
		{
			var comp : String;
			for (var i : int = 0; i < _regCount; ++i) {
				if (_usedVectorCount[i] > 0) continue;
				for (var j : int = 0; j < 4; ++j) {
					comp = COMPONENTS[j];
					if (_usedSingleCount[comp][i] == 0) {
						if (_persistent) addUsage(_usedSingleCount[comp][i], 1);
						return _registerComponents[comp][i];
					}
				}
			}

			throw new Error("Register overflow!");
		}

		/**
		 * Marks a register as used, so it cannot be retrieved.
		 * @param register The register to mark as used.
		 * @param usageCount The amount of usages to add.
		 */
		public function addUsage(register : ShaderRegisterElement, usageCount : int) : void
		{
			if (register.component) {
				_usedSingleCount[register.component][register.index] += usageCount;
			}
			else {
				_usedVectorCount[register.index] += usageCount;
			}
		}

		/**
		 * Removes a usage from a register. When usages reach 0, the register is freed again.
		 * @param register The register for which to remove a usage.
		 */
		public function removeUsage(register : ShaderRegisterElement) : void
		{
			if (register.component) {
				if (--_usedSingleCount[register.component][register.index] < 0) {
					throw new Error("More usages removed than exist!");
				}
			}
			else {
				if (--_usedVectorCount[register.index] < 0) {
					throw new Error("More usages removed than exist!");
				}
			}
		}

		/**
		 * Indicates whether or not any registers are in use.
		 */
		public function hasRegisteredRegs() : Boolean
		{
			for (var i : int = 0; i < _regCount; ++i)
				if (isRegisterUsed(i)) return true;

			return false;
		}

		/**
		 * Initializes all registers
		 */
		private function initRegisters(regName : String, regCount : int) : void
		{
			var comp : String;

			_vectorRegisters = new Vector.<ShaderRegisterElement>(regCount, true);
			_registerComponents = [];
			_usedVectorCount = new Vector.<uint>(regCount, true);
			_usedSingleCount = [];

			for (var i : int = 0; i < regCount; ++i) {
				_vectorRegisters[i] = new ShaderRegisterElement(regName, i);
				_usedVectorCount[i] = 0;

				for (var j : int = 0; j < 4; ++j) {
					comp = COMPONENTS[j];
					_registerComponents[comp] ||= [];
					_usedSingleCount[comp] ||= [];
					_registerComponents[comp][i] = new ShaderRegisterElement(regName, i, comp);
					_usedSingleCount[comp][i] = 0;
				}
			}
		}

		/**
		 * Check if the temp register is either used for single or vector use
		 */
		private function isRegisterUsed(index : int) : Boolean
		{
			if (_usedVectorCount[index] > 0) return true;
			for (var i : int = 0; i < 4; ++i)
				if (_usedSingleCount[COMPONENTS[i]][index] > 0) return true;

			return false;
		}
	}
}
