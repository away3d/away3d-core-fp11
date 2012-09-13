package away3d.materials.compilation
{
	public class SuperShaderCompiler
	{
		private var _sharedRegisters : ShaderRegisterData;
		private var _registerCache : ShaderRegisterCache;
		private var _vertexConstantsOffset : uint;


		// TODO: CHANGE BACK TO PRIVATE!
		public var _uvBufferIndex : int = -1;
		public var _uvTransformIndex : int = -1;
		public var _secondaryUVBufferIndex : int = -1;
		public var _normalBufferIndex : int = -1;
		public var _tangentBufferIndex : int = -1;
		public var _lightDataIndex : int = -1;
		public var _sceneMatrixIndex : int = -1;
		public var _sceneNormalMatrixIndex : int = -1;
		public var _cameraPositionIndex : int = -1;
		public var _commonsDataIndex : int = -1;
		public var _probeWeightsIndex : int = -1;

		public var _vertexCode : String;
		public var _fragmentCode : String;

		public var _numLights : int;

		private var _numLightProbes : uint;
		private var _numPointLights : uint;
		private var _numDirectionalLights : uint;
		public var _numProbeRegisters : Number;


		public function SuperShaderCompiler()
		{
			_sharedRegisters = new ShaderRegisterData();
			initRegisterCache();
		}

		private function initRegisterCache() : void
		{
			_registerCache = new ShaderRegisterCache();
			_vertexConstantsOffset = _registerCache.vertexConstantOffset = 5;
			_registerCache.vertexAttributesOffset = 1;
			_registerCache.reset();
		}

		// TODO: REMOVE
		public function get sharedRegisters() : ShaderRegisterData
		{
			return _sharedRegisters;
		}

		// TODO: REMOVE
		public function get registerCache() : ShaderRegisterCache
		{
			return _registerCache;
		}


		public function get vertexConstantsOffset() : uint
		{
			return _vertexConstantsOffset;
		}


		public function compile() : void
		{
			initRegisterIndices();
			initLightData();
		}


		private function initRegisterIndices() : void
		{
			_cameraPositionIndex = -1;
			_commonsDataIndex = -1;
			_uvBufferIndex = -1;
			_uvTransformIndex = -1;
			_secondaryUVBufferIndex = -1;
			_normalBufferIndex = -1;
			_tangentBufferIndex = -1;
			_lightDataIndex = -1;
			_sceneMatrixIndex = -1;
			_sceneNormalMatrixIndex = -1;
			_probeWeightsIndex = -1;
		}

		private function initLightData() : void
		{
			_numLights = _numPointLights + _numDirectionalLights;
			_numProbeRegisters = Math.ceil(_numLightProbes/4);
		}

		public function get uvBufferIndex() : int
		{
			return _uvBufferIndex;
		}

		public function get uvTransformIndex() : int
		{
			return _uvTransformIndex;
		}

		public function get secondaryUVBufferIndex() : int
		{
			return _secondaryUVBufferIndex;
		}

		public function get normalBufferIndex() : int
		{
			return _normalBufferIndex;
		}

		public function get tangentBufferIndex() : int
		{
			return _tangentBufferIndex;
		}

		public function get lightDataIndex() : int
		{
			return _lightDataIndex;
		}

		public function get cameraPositionIndex() : int
		{
			return _cameraPositionIndex;
		}

		public function get commonsDataIndex() : int
		{
			return _commonsDataIndex;
		}

		public function get sceneMatrixIndex() : int
		{
			return _sceneMatrixIndex;
		}

		public function get sceneNormalMatrixIndex() : int
		{
			return _sceneNormalMatrixIndex;
		}

		public function get probeWeightsIndex() : int
		{
			return _probeWeightsIndex;
		}

		public function get vertexCode() : String
		{
			return _vertexCode;
		}

		public function get fragmentCode() : String
		{
			return _fragmentCode;
		}


		public function get numPointLights() : uint
		{
			return _numPointLights;
		}

		public function set numPointLights(numPointLights : uint) : void
		{
			_numPointLights = numPointLights;
		}


		public function get numDirectionalLights() : uint
		{
			return _numDirectionalLights;
		}

		public function set numDirectionalLights(value : uint) : void
		{
			_numDirectionalLights = value;
		}


		public function get numLightProbes() : uint
		{
			return _numLightProbes;
		}

		public function set numLightProbes(value : uint) : void
		{
			_numLightProbes = value;
		}

		/*private function usesLights() : Boolean
		{
			return (_numLights > 0) && (_combinedLightSources & LightSources.LIGHTS) != 0;
		} */
	}
}
