package away3d.materials.compilation
{
	import away3d.arcane;
	import away3d.materials.LightSources;
	import away3d.materials.methods.ShaderMethodSetup;

	public class SuperShaderCompiler
	{
		private var _sharedRegisters : ShaderRegisterData;
		private var _registerCache : ShaderRegisterCache;
		private var _methodSetup : ShaderMethodSetup;
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
		private var _specularLightSources : uint;
		private var _diffuseLightSources : uint;
		public var _combinedLightSources : uint;
		public var _usingSpecularMethod : Boolean;
		public var _pointLightRegisters : Vector.<ShaderRegisterElement>;
		public var _dirLightRegisters : Vector.<ShaderRegisterElement>;
		private var _animatableAttributes : Array;
		private var _animationTargetRegisters : Array;

		use namespace arcane;

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

		public function get methodSetup() : ShaderMethodSetup
		{
			return _methodSetup;
		}

		public function set methodSetup(value : ShaderMethodSetup) : void
		{
			_methodSetup = value;
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


		public function compile() : void
		{
			initRegisterIndices();
			initLightData();

			_animatableAttributes = ["va0"];
			_animationTargetRegisters = ["vt0"];
			_vertexCode = "";
			_fragmentCode = "";

			_sharedRegisters.localPosition = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.localPosition, 1);

			createCommons();
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

			if (_methodSetup._specularMethod)
				_combinedLightSources = _specularLightSources | _diffuseLightSources;
			else
				_combinedLightSources = _diffuseLightSources;

			_usingSpecularMethod = 	_methodSetup._specularMethod && (
									usesLightsForSpecular() ||
									usesProbesForSpecular());

			_pointLightRegisters = new Vector.<ShaderRegisterElement>(_numPointLights * 3, true);
			_dirLightRegisters = new Vector.<ShaderRegisterElement>(_numDirectionalLights * 3, true);
		}

		private function createCommons() : void
		{
			_sharedRegisters.commons = _registerCache.getFreeFragmentConstant();
			_commonsDataIndex = _sharedRegisters.commons.index*4;
		}


		public function get vertexConstantsOffset() : uint
		{
			return _vertexConstantsOffset;
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

		public function get specularLightSources() : uint
		{
			return _specularLightSources;
		}

		public function set specularLightSources(value : uint) : void
		{
			_specularLightSources = value;
		}

		public function get diffuseLightSources() : uint
		{
			return _diffuseLightSources;
		}

		public function set diffuseLightSources(value : uint) : void
		{
			_diffuseLightSources = value;
		}

		public function get usingSpecularMethod() : Boolean
		{
			return _usingSpecularMethod;
		}

		public function get animatableAttributes() : Array
		{
			return _animatableAttributes;
		}

		public function get animationTargetRegisters() : Array
		{
			return _animationTargetRegisters;
		}

		private function usesLights() : Boolean
		{
			return _numLights > 0 && (_combinedLightSources & LightSources.LIGHTS) != 0;
		}

		private function usesProbesForSpecular() : Boolean
		{
			return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
		}

		private function usesProbesForDiffuse() : Boolean
		{
			return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
		}

		private function usesProbes() : Boolean
		{
			return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
		}

		private function usesLightsForSpecular() : Boolean
		{
			return _numLights > 0 && (_specularLightSources & LightSources.LIGHTS) != 0;
		}

		private function usesLightsForDiffuse() : Boolean
		{
			return _numLights > 0 && (_diffuseLightSources & LightSources.LIGHTS) != 0;
		}
	}
}
