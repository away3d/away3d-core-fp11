package away3d.materials.compilation
{
	import flash.utils.Dictionary;
	/**
	 * RegisterPool is used by the shader compilation process to keep track of which registers of a certain type are
	 * currently used. Either entire registers can be requested and locked, or single components (x, y, z, w) of a
	 * single register.
	 */
	internal class RegisterPool
	{
		private static const _regPool : Dictionary = new Dictionary();
		private static const _regCompsPool : Dictionary = new Dictionary();
		
		
		private var _vectorRegisters : Vector.<ShaderRegisterElement>;
		private var _registerComponents : Array;
		
		private var _regName : String;
		private var _usedSingleCount : Vector.<Vector.<uint>>;
		private var _usedVectorCount : Vector.<uint>;
		private var _regCount : int;

		private var _persistent : Boolean;

		

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
					if (_persistent) _usedVectorCount[i]++;
					return _vectorRegisters[i];
				}

			throw new Error("Register overflow!");
		}

		/**
		 * Retrieve a single vector component that's still available.
		 */
		public function requestFreeRegComponent() : ShaderRegisterElement
		{
			for (var i : int = 0; i < _regCount; ++i) {
				if (_usedVectorCount[i] > 0) continue;
				for (var j : int = 0; j < 4; ++j) {
					if (_usedSingleCount[j][i] == 0) {
						if (_persistent) _usedSingleCount[j][i]++;
						return _registerComponents[j][i];
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
			if (register._component > -1 ) {
				_usedSingleCount[register._component][register.index] += usageCount;
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
			if (register._component > -1 ) {
				if (--_usedSingleCount[register._component][register.index] < 0) {
					throw new Error("More usages removed than exist!");
				}
			}
			else {
				if (--_usedVectorCount[register.index] < 0) {
					throw new Error("More usages removed than exist!");
				}
			}
		}

		public function dispose() : void
		{
			_vectorRegisters = null;
			_registerComponents = null;
			_usedSingleCount = null;
			_usedVectorCount = null;
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
			
			var hash : String = RegisterPool._initPool( regName, regCount );

			_vectorRegisters = RegisterPool._regPool[hash];
			_registerComponents = RegisterPool._regCompsPool[hash];
			
			_usedVectorCount = new Vector.<uint>(regCount, true);
			_usedSingleCount = new Vector.<Vector.<uint>>( 4, true );
			
			_usedSingleCount[0] = new Vector.<uint>( regCount, true );
			_usedSingleCount[1] = new Vector.<uint>( regCount, true );
			_usedSingleCount[2] = new Vector.<uint>( regCount, true );
			_usedSingleCount[3] = new Vector.<uint>( regCount, true );
			
		}

		private static function _initPool(regName : String, regCount : int) : String
		{
			var hash : String = regName+regCount;
			
			if( _regPool[hash] != undefined ) return hash;
			
			var vectorRegisters : Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>(regCount, true);
			_regPool[hash] = vectorRegisters;
			
			var registerComponents : Array = [[], [], [], []];
			_regCompsPool[hash] = registerComponents;
			
			for (var i : int = 0; i < regCount; ++i) {
				vectorRegisters[i] = new ShaderRegisterElement(regName, i);

				for (var j : int = 0; j < 4; ++j) {
					registerComponents[j][i] = new ShaderRegisterElement(regName, i, j);
				}
			}
			return hash;
		}

		/**
		 * Check if the temp register is either used for single or vector use
		 */
		private function isRegisterUsed(index : int) : Boolean
		{
			if (_usedVectorCount[index] > 0) return true;
			for (var i : int = 0; i < 4; ++i)
				if (_usedSingleCount[i][index] > 0) return true;

			return false;
		}
	}
}
