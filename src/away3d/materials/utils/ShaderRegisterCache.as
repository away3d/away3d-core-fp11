package away3d.materials.utils
{
	/**
	 * ShaderRegister Cache provides the usage management system for all registers during shading compilation.
	 */
	public class ShaderRegisterCache
	{
		private var _fragmentTempCache : RegisterPool;
		private var _vertexTempCache : RegisterPool;
		private var _varyingCache : RegisterPool;
		private var _fragmentConstantsCache : RegisterPool;
		private var _vertexConstantsCache : RegisterPool;
		private var _textureCache : RegisterPool;
		private var _vertexAttributesCache : RegisterPool;
		private var _vertexConstantOffset : uint;
		private var _vertexAttributesOffset : uint;

		private var _fragmentConstantsCount : uint;
		private var _vertexConstantsCount : uint;
		private var _vertexAttributeCount : uint;

		private var _fragmentOutputRegister : ShaderRegisterElement;
		private var _vertexOutputRegister : ShaderRegisterElement;
		private var _numUsedVertexConstants : uint;
		private var _numUsedStreams : uint;
		private var _numUsedTextures : uint;

		/**
		 * Create a new ShaderRegisterCache object.
		 */
		public function ShaderRegisterCache()
		{
		}

		/**
		 * Resets all registers.
		 */
		public function reset() : void
		{
			_fragmentTempCache = new RegisterPool("ft", 8, false);
			_vertexTempCache = new RegisterPool("vt", 8, false);
			_varyingCache = new RegisterPool("v", 8);
			_textureCache = new RegisterPool("fs", 8);
			_vertexAttributesCache = new RegisterPool("va", 8);
			_fragmentConstantsCache = new RegisterPool("fc", 28);
			_vertexConstantsCache = new RegisterPool("vc", 128);
			_fragmentOutputRegister = new ShaderRegisterElement("oc", -1);
			_vertexOutputRegister = new ShaderRegisterElement("op", -1);
			_numUsedVertexConstants = 0;
			_numUsedStreams = 0;
			_numUsedTextures = 0;
			var i : int;
			for (i = 0; i < _vertexAttributesOffset; ++i) getFreeVertexAttribute();
			for (i = 0; i < _vertexConstantOffset; ++i) getFreeVertexConstant();
		}

		/**
		 * Marks a fragment temporary register as used, so it cannot be retrieved.
		 * @param register The register to mark as used.
		 * @param usageCount The amount of usages to add.
		 */
		public function addFragmentTempUsages(register : ShaderRegisterElement, usageCount : uint) : void
		{
			_fragmentTempCache.addUsage(register, usageCount);
		}

		/**
		 * Removes a usage from a fragment temporary register. When usages reach 0, the register is freed again.
		 * @param register The register for which to remove a usage.
		 */
		public function removeFragmentTempUsage(register : ShaderRegisterElement) : void
		{
			_fragmentTempCache.removeUsage(register);
		}

		/**
		 * Marks a vertex temporary register as used, so it cannot be retrieved.
		 * @param register The register to mark as used.
		 * @param usageCount The amount of usages to add.
		 */
		public function addVertexTempUsages(register : ShaderRegisterElement, usageCount : uint) : void
		{
			_vertexTempCache.addUsage(register, usageCount);
		}

		/**
		 * Removes a usage from a vertex temporary register. When usages reach 0, the register is freed again.
		 * @param register The register for which to remove a usage.
		 */
		public function removeVertexTempUsage(register : ShaderRegisterElement) : void
		{
			_vertexTempCache.removeUsage(register);
		}

		/**
		 * Retrieve an entire fragment temporary register that's still available.
		 */
		public function getFreeFragmentVectorTemp() : ShaderRegisterElement
		{
			return _fragmentTempCache.requestFreeVectorReg();
		}

		/**
		 * Retrieve a single component from a fragment temporary register that's still available.
		 */
		public function getFreeFragmentSingleTemp() : ShaderRegisterElement
		{
			return _fragmentTempCache.requestFreeRegComponent();
		}

		/**
		 * Retrieve an available varying register
		 */
		public function getFreeVarying() : ShaderRegisterElement
		{
			return _varyingCache.requestFreeVectorReg();
		}

		/**
		 * Retrieve an available fragment constant register
		 */
		public function getFreeFragmentConstant() : ShaderRegisterElement
		{
			return _fragmentConstantsCache.requestFreeVectorReg();
		}

		/**
		 * Retrieve an available vertex constant register
		 */
		public function getFreeVertexConstant() : ShaderRegisterElement
		{
			++_numUsedVertexConstants;
			return _vertexConstantsCache.requestFreeVectorReg();
		}

		/**
		 * Retrieve an entire vertex temporary register that's still available.
		 */
		public function getFreeVertexVectorTemp() : ShaderRegisterElement
		{
			return _vertexTempCache.requestFreeVectorReg();
		}

		/**
		 * Retrieve a single component from a vertex temporary register that's still available.
		 */
		public function getFreeVertexSingleTemp() : ShaderRegisterElement
		{
			return _vertexTempCache.requestFreeRegComponent();
		}

		/**
		 * Retrieve an available vertex attribute register
		 */
		public function getFreeVertexAttribute() : ShaderRegisterElement
		{
			++_numUsedStreams;
			return _vertexAttributesCache.requestFreeVectorReg();
		}

		/**
		 * Retrieve an available texture register
		 */
		public function getFreeTextureReg() : ShaderRegisterElement
		{
			++_numUsedTextures;
			return _textureCache.requestFreeVectorReg();
		}

		/**
		 * Indicates the start index from which to retrieve vertex constants.
		 */
		public function get vertexConstantOffset() : uint
		{
			return _vertexConstantOffset;
		}

		public function set vertexConstantOffset(vertexConstantOffset : uint) : void
		{
			_vertexConstantOffset = vertexConstantOffset;
		}

		/**
		 * Indicates the start index from which to retrieve vertex attributes.
		 */
		public function get vertexAttributesOffset() : uint
		{
			return _vertexAttributesOffset;
		}

		public function set vertexAttributesOffset(value : uint) : void
		{
			_vertexAttributesOffset = value;
		}

		/**
		 * The amount of used fragment constant registers.
		 */
		public function get fragmentsConstantCount() : uint
		{
			return _fragmentConstantsCount;
		}

		/**
		 * The amount of used vertex constant registers.
		 */
		public function get vertexConstantCount() : uint
		{
			return _vertexConstantsCount;
		}

		/**
		 * The amount of used vertex attribute registers.
		 */
		public function get vertexAttributeCount() : uint
		{
			return _vertexAttributeCount;
		}

		/**
		 * The fragment output register.
		 */
		public function get fragmentOutputRegister() : ShaderRegisterElement
		{
			return _fragmentOutputRegister;
		}

		/**
		 * The amount of used vertex constant registers.
		 */
		public function get numUsedVertexConstants() : uint
		{
			return _numUsedVertexConstants;
		}

		/**
		 * The amount of used vertex streams.
		 */
		public function get numUsedStreams() : uint
		{
			return _numUsedStreams;
		}

		public function get numUsedTextures() : uint
		{
			return _numUsedTextures;
		}
	}
}