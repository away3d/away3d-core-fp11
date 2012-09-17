package away3d.materials.compilation
{
	import away3d.arcane;
	import away3d.materials.LightSources;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.methods.MethodVOSet;
	import away3d.materials.methods.ShaderMethodSetup;
	import away3d.materials.methods.ShadingMethodBase;

	public class SuperShaderCompiler
	{
		private var _sharedRegisters : ShaderRegisterData;
		private var _registerCache : ShaderRegisterCache;
		private var _methodSetup : ShaderMethodSetup;
		private var _vertexConstantsOffset : uint;
		public var _dependencyCounter : MethodDependencyCounter;

		private var _uvBufferIndex : int = -1;
		private var _uvTransformIndex : int = -1;
		private var _secondaryUVBufferIndex : int = -1;
		private var _normalBufferIndex : int = -1;
		private var _tangentBufferIndex : int = -1;
		private var _lightDataIndex : int = -1;
		private var _sceneMatrixIndex : int = -1;
		private var _sceneNormalMatrixIndex : int = -1;
		private var _cameraPositionIndex : int = -1;
		private var _commonsDataIndex : int = -1;
		private var _probeWeightsIndex : int = -1;
		private var _lightProbeDiffuseIndices : Vector.<uint>;
		private var _lightProbeSpecularIndices : Vector.<uint>;

		private var _vertexCode : String;
		private var _fragmentCode : String;

		private var _numLights : int;

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
		private var _smooth : Boolean;
		private var _repeat : Boolean;
		private var _mipmap : Boolean;
		private var _preserveAlpha : Boolean = true;
		private var _animateUVs : Boolean;
		private var _alphaPremultiplied : Boolean;
		private var _vertexConstantData : Vector.<Number>;
		private var _fragmentConstantData : Vector.<Number>;

		use namespace arcane;

		public function SuperShaderCompiler()
		{
			_sharedRegisters = new ShaderRegisterData();
			_dependencyCounter = new MethodDependencyCounter();
			initRegisterCache();
		}

		private function initRegisterCache() : void
		{
			_registerCache = new ShaderRegisterCache();
			_vertexConstantsOffset = _registerCache.vertexConstantOffset = 5;
			_registerCache.vertexAttributesOffset = 1;
			_registerCache.reset();
		}

		public function get animateUVs() : Boolean
		{
			return _animateUVs;
		}

		public function set animateUVs(value : Boolean) : void
		{
			_animateUVs = value;
		}

		public function get alphaPremultiplied() : Boolean
		{
			return _alphaPremultiplied;
		}

		public function set alphaPremultiplied(value : Boolean) : void
		{
			_alphaPremultiplied = value;
		}

		public function get preserveAlpha() : Boolean
		{
			return _preserveAlpha;
		}

		public function set preserveAlpha(value : Boolean) : void
		{
			_preserveAlpha = value;
		}

		public function setTextureSampling(smooth : Boolean, repeat : Boolean, mipmap : Boolean) : void
		{
			_smooth = smooth;
			_repeat = repeat;
			_mipmap = mipmap;
		}

		public function setConstantDataBuffers(vertexConstantData : Vector.<Number>, fragmentConstantData : Vector.<Number>) : void
		{
			_vertexConstantData = vertexConstantData;
			_fragmentConstantData = fragmentConstantData;
		}

		public function get methodSetup() : ShaderMethodSetup
		{
			return _methodSetup;
		}

		public function set methodSetup(value : ShaderMethodSetup) : void
		{
			_methodSetup = value;
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
			calculateDependencies();
			updateMethodRegisters();

			compileMethodsCode();
			compileProjectionCode();
			compileFragmentOutput();
		}

		private function compileFragmentOutput() : void
		{
			_fragmentCode += "mov " + _registerCache.fragmentOutputRegister + ", " + _sharedRegisters.shadedTarget + "\n";
			_registerCache.removeFragmentTempUsage(_sharedRegisters.shadedTarget);
		}

		private function compileProjectionCode() : void
		{
			var pos : String = _animationTargetRegisters[0];
			var projectedTarget : ShaderRegisterElement =  _sharedRegisters.projectedTarget;
			var code : String;

			// if we need projection somewhere
			if (projectedTarget) {
				code =	"m44 " + projectedTarget + ", " + pos + ", vc0		\n" +
						"mov vt7, " + projectedTarget + "\n" +
						"mul op, vt7, vc4\n";
			}
			else {
				code = 	"m44 vt7, " + pos + ", vc0		\n" +
						"mul op, vt7, vc4\n";	// 4x4 matrix transform from stream 0 to output clipspace
			}

			_vertexCode = code + _vertexCode;
		}

		private function compileMethodsCode() : void
		{
			if (_dependencyCounter.projectionDependencies > 0) compileProjCode();
			if (_dependencyCounter.uvDependencies > 0) compileUVCode();
			if (_dependencyCounter.secondaryUVDependencies > 0) compileSecondaryUVCode();
			if (_dependencyCounter.globalPosDependencies > 0) compileGlobalPositionCode();
			if (_dependencyCounter.normalDependencies > 0) compileNormalCode();
			if (_dependencyCounter.viewDirDependencies > 0) compileViewDirCode();
			compileLightingCode();
			compileMethods();
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

		/**
		 * Calculates register dependencies for commonly used data.
		 */
		private function calculateDependencies() : void
		{
			var methods : Vector.<MethodVOSet> = _methodSetup._methods;
			var len : uint;

			_dependencyCounter.reset();

			setupAndCountMethodDependencies(_methodSetup._diffuseMethod, _methodSetup._diffuseMethodVO);
			if (_methodSetup._shadowMethod) setupAndCountMethodDependencies(_methodSetup._shadowMethod, _methodSetup._shadowMethodVO);
			setupAndCountMethodDependencies(_methodSetup._ambientMethod, _methodSetup._ambientMethodVO);
			if (_usingSpecularMethod) setupAndCountMethodDependencies(_methodSetup._specularMethod, _methodSetup._specularMethodVO);
			if (_methodSetup._colorTransformMethod) setupAndCountMethodDependencies(_methodSetup._colorTransformMethod, _methodSetup._colorTransformMethodVO);

			len = methods.length;
			for (var i : uint = 0; i < len; ++i)
				setupAndCountMethodDependencies(methods[i].method, methods[i].data);

			if (usesNormals)
				setupAndCountMethodDependencies(_methodSetup._normalMethod, _methodSetup._normalMethodVO);

			// todo: add spotlights to count check
			_dependencyCounter.setPositionedLights(_numPointLights, _combinedLightSources);
		}

		private function setupAndCountMethodDependencies(method : ShadingMethodBase, methodVO : MethodVO) : void
		{
			setupMethod(method, methodVO);
			_dependencyCounter.includeMethodVO(methodVO);
		}

		private function setupMethod(method : ShadingMethodBase, methodVO : MethodVO) : void
		{
			method.reset();
			methodVO.reset();
			methodVO.vertexData = _vertexConstantData;
			methodVO.fragmentData = _fragmentConstantData;
			methodVO.vertexConstantsOffset = _vertexConstantsOffset;
			methodVO.useSmoothTextures = _smooth;
			methodVO.repeatTextures = _repeat;
			methodVO.useMipmapping = _mipmap;
			methodVO.numLights = _numLights + _numLightProbes;
			method.initVO(methodVO);
		}

		private function compileProjCode() : void
		{
			_sharedRegisters.projectionFragment = _registerCache.getFreeVarying();
			_sharedRegisters.projectedTarget = _registerCache.getFreeVertexVectorTemp();

			_vertexCode += "mov " + _sharedRegisters.projectionFragment + ", " + _sharedRegisters.projectedTarget + "\n";
		}

		private function compileUVCode() : void
		{
			var uvAttributeReg : ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
			_uvBufferIndex = uvAttributeReg.index;

			var varying : ShaderRegisterElement = _registerCache.getFreeVarying();

			_sharedRegisters.uvVarying = varying;

			if (animateUVs) {
				// a, b, 0, tx
				// c, d, 0, ty
				var uvTransform1 : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				var uvTransform2 : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				_uvTransformIndex = (uvTransform1.index - vertexConstantsOffset)*4;

				_vertexCode +=	"dp4 " + varying + ".x, " + uvAttributeReg + ", " + uvTransform1 + "\n" +
						"dp4 " + varying + ".y, " + uvAttributeReg + ", " + uvTransform2 + "\n" +
						"mov " + varying + ".zw, " + uvAttributeReg + ".zw \n";
			}
			else {
				_uvTransformIndex = -1;
				_vertexCode += "mov " + varying + ", " + uvAttributeReg + "\n";
			}
		}

		private function compileSecondaryUVCode() : void
		{
			var uvAttributeReg : ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
			_secondaryUVBufferIndex = uvAttributeReg.index;
			_sharedRegisters.secondaryUVVarying = _registerCache.getFreeVarying();
			_vertexCode += "mov " + _sharedRegisters.secondaryUVVarying + ", " + uvAttributeReg + "\n";
		}

		private function compileGlobalPositionCode() : void
		{
			var positionMatrixReg : ShaderRegisterElement;
			_sharedRegisters.globalPositionVertex = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.globalPositionVertex, _dependencyCounter.globalPosDependencies);

			positionMatrixReg = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneMatrixIndex = (positionMatrixReg.index - _vertexConstantsOffset)*4;

			_vertexCode += 	"m44 " + _sharedRegisters.globalPositionVertex + ".xyz, " + _sharedRegisters.localPosition + ", " + positionMatrixReg + "\n" +
							"mov " + _sharedRegisters.globalPositionVertex + ".w, " + _sharedRegisters.localPosition + ".w     \n";

			if (_dependencyCounter.usesGlobalPosFragment) {
				_sharedRegisters.globalPositionVarying = _registerCache.getFreeVarying();
				_vertexCode += "mov " + _sharedRegisters.globalPositionVarying + ", " + _sharedRegisters.globalPositionVertex + "\n";
			}
		}

		private function updateMethodRegisters() : void
		{
			_methodSetup._normalMethod.sharedRegisters = _sharedRegisters;
			_methodSetup._diffuseMethod.sharedRegisters = _sharedRegisters;
			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.sharedRegisters = _sharedRegisters;
			_methodSetup._ambientMethod.sharedRegisters = _sharedRegisters;
			if (_methodSetup._specularMethod) _methodSetup._specularMethod.sharedRegisters = _sharedRegisters;
			if (_methodSetup._colorTransformMethod) _methodSetup._colorTransformMethod.sharedRegisters = _sharedRegisters;

			var methods : Vector.<MethodVOSet> = _methodSetup._methods;
			var len : int = methods.length;
			for (var i : uint = 0; i < len; ++i)
				methods[i].method.sharedRegisters = _sharedRegisters;
		}

		private function compileNormalCode() : void
		{
			var normalMatrix : Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>(3, true);
			_sharedRegisters.animatedNormal = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.animatedNormal, 1);
			_sharedRegisters.normalFragment = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_sharedRegisters.normalFragment, _dependencyCounter.normalDependencies);

			if (_methodSetup._normalMethod.hasOutput && !_methodSetup._normalMethod.tangentSpace) {
				_vertexCode += _methodSetup._normalMethod.getVertexCode(_methodSetup._normalMethodVO, _registerCache);
				_fragmentCode += _methodSetup._normalMethod.getFragmentCode(_methodSetup._normalMethodVO, _registerCache, _sharedRegisters.normalFragment);
				return;
			}

			_sharedRegisters.normalInput = _registerCache.getFreeVertexAttribute();
			_normalBufferIndex = _sharedRegisters.normalInput.index;

			_sharedRegisters.normalVarying = _registerCache.getFreeVarying();

			_animatableAttributes.push(_sharedRegisters.normalInput.toString());
			_animationTargetRegisters.push(_sharedRegisters.animatedNormal.toString());

			normalMatrix[0] = _registerCache.getFreeVertexConstant();
			normalMatrix[1] = _registerCache.getFreeVertexConstant();
			normalMatrix[2] = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneNormalMatrixIndex = (normalMatrix[0].index-_vertexConstantsOffset)*4;

			if (_methodSetup._normalMethod.hasOutput) {
				// tangent stream required
				compileTangentVertexCode(normalMatrix);
				compileTangentNormalMapFragmentCode();
			}
			else {
				_vertexCode += "m33 " + _sharedRegisters.normalVarying + ".xyz, " + _sharedRegisters.animatedNormal + ".xyz, " + normalMatrix[0] + "\n" +
						"mov " + _sharedRegisters.normalVarying + ".w, " + _sharedRegisters.animatedNormal + ".w	\n";

				_fragmentCode += "nrm " + _sharedRegisters.normalFragment + ".xyz, " + _sharedRegisters.normalVarying + ".xyz	\n" +
						"mov " + _sharedRegisters.normalFragment + ".w, " + _sharedRegisters.normalVarying + ".w		\n";


				if (_dependencyCounter.tangentDependencies > 0) {
					_sharedRegisters.tangentInput = _registerCache.getFreeVertexAttribute();
					_tangentBufferIndex = _sharedRegisters.tangentInput.index;
					_sharedRegisters.tangentVarying = _registerCache.getFreeVarying();
					_vertexCode += "mov " + _sharedRegisters.tangentVarying + ", " + _sharedRegisters.tangentInput + "\n";
				}
			}

			_registerCache.removeVertexTempUsage(_sharedRegisters.animatedNormal);
		}

		private function compileTangentVertexCode(matrix : Vector.<ShaderRegisterElement>) : void
		{
			var normalTemp : ShaderRegisterElement;
			var tanTemp : ShaderRegisterElement;
			var bitanTemp1 : ShaderRegisterElement;
			var bitanTemp2 : ShaderRegisterElement;

			_sharedRegisters.tangentVarying = _registerCache.getFreeVarying();
			_sharedRegisters.bitangentVarying = _registerCache.getFreeVarying();

			_sharedRegisters.tangentInput = _registerCache.getFreeVertexAttribute();
			_tangentBufferIndex = _sharedRegisters.tangentInput.index;

			_sharedRegisters.animatedTangent = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.animatedTangent, 1);
			_animatableAttributes.push(_sharedRegisters.tangentInput.toString());
			_animationTargetRegisters.push(_sharedRegisters.animatedTangent.toString());

			normalTemp = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(normalTemp, 1);

			_vertexCode += 	"m33 " + normalTemp + ".xyz, " + _sharedRegisters.animatedNormal + ".xyz, " + matrix[0].toString() + "\n" +
					"nrm " + normalTemp + ".xyz, " + normalTemp + ".xyz	\n";

			tanTemp = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(tanTemp, 1);

			_vertexCode += 	"m33 " + tanTemp + ".xyz, " + _sharedRegisters.animatedTangent + ".xyz, " + matrix[0].toString() + "\n" +
					"nrm " + tanTemp + ".xyz, " + tanTemp + ".xyz	\n";

			bitanTemp1 = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(bitanTemp1, 1);
			bitanTemp2 = _registerCache.getFreeVertexVectorTemp();

			_vertexCode += "mul " + bitanTemp1 + ".xyz, " + normalTemp + ".yzx, " + tanTemp + ".zxy	\n" +
					"mul " + bitanTemp2 + ".xyz, " + normalTemp + ".zxy, " + tanTemp + ".yzx	\n" +
					"sub " + bitanTemp2 + ".xyz, " + bitanTemp1 + ".xyz, " + bitanTemp2 + ".xyz	\n" +

					"mov " + _sharedRegisters.tangentVarying + ".x, " + tanTemp + ".x	\n" +
					"mov " + _sharedRegisters.tangentVarying + ".y, " + bitanTemp2 + ".x	\n" +
					"mov " + _sharedRegisters.tangentVarying + ".z, " + normalTemp + ".x	\n" +
					"mov " + _sharedRegisters.tangentVarying + ".w, " + _sharedRegisters.normalInput + ".w	\n" +
					"mov " + _sharedRegisters.bitangentVarying + ".x, " + tanTemp + ".y	\n" +
					"mov " + _sharedRegisters.bitangentVarying + ".y, " + bitanTemp2 + ".y	\n" +
					"mov " + _sharedRegisters.bitangentVarying + ".z, " + normalTemp + ".y	\n" +
					"mov " + _sharedRegisters.bitangentVarying + ".w, " + _sharedRegisters.normalInput + ".w	\n" +
					"mov " + _sharedRegisters.normalVarying + ".x, " + tanTemp + ".z	\n" +
					"mov " + _sharedRegisters.normalVarying + ".y, " + bitanTemp2 + ".z	\n" +
					"mov " + _sharedRegisters.normalVarying + ".z, " + normalTemp + ".z	\n" +
					"mov " + _sharedRegisters.normalVarying + ".w, " + _sharedRegisters.normalInput + ".w	\n";

			_registerCache.removeVertexTempUsage(normalTemp);
			_registerCache.removeVertexTempUsage(tanTemp);
			_registerCache.removeVertexTempUsage(bitanTemp1);
			_registerCache.removeVertexTempUsage(_sharedRegisters.animatedTangent);
		}

		private function compileTangentNormalMapFragmentCode() : void
		{
			var t : ShaderRegisterElement;
			var b : ShaderRegisterElement;
			var n : ShaderRegisterElement;

			t = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(t, 1);
			b = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(b, 1);
			n = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(n, 1);

			_fragmentCode += 	"nrm " + t + ".xyz, " + _sharedRegisters.tangentVarying + ".xyz	\n" +
					"mov " + t + ".w, " + _sharedRegisters.tangentVarying + ".w	\n" +
					"nrm " + b + ".xyz, " + _sharedRegisters.bitangentVarying + ".xyz	\n" +
					"nrm " + n + ".xyz, " + _sharedRegisters.normalVarying + ".xyz	\n";

			var temp : ShaderRegisterElement = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(temp, 1);
			_fragmentCode += _methodSetup._normalMethod.getFragmentCode(_methodSetup._normalMethodVO, _registerCache, temp) +
					"sub " + temp + ".xyz, " + temp + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" +
					"nrm " + temp + ".xyz, " + temp + ".xyz							\n" +
					"m33 " + _sharedRegisters.normalFragment + ".xyz, " + temp + ".xyz, " + t + "	\n" +
					"mov " + _sharedRegisters.normalFragment + ".w,   " + _sharedRegisters.normalVarying + ".w			\n";

			_registerCache.removeFragmentTempUsage(temp);

			if (_methodSetup._normalMethodVO.needsView) _registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
			if (_methodSetup._normalMethodVO.needsGlobalPos) _registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
			_registerCache.removeFragmentTempUsage(b);
			_registerCache.removeFragmentTempUsage(t);
			_registerCache.removeFragmentTempUsage(n);
		}

		private function compileViewDirCode() : void
		{
			var cameraPositionReg : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
			_sharedRegisters.viewDirVarying = _registerCache.getFreeVarying();
			_sharedRegisters.viewDirFragment = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_sharedRegisters.viewDirFragment, _dependencyCounter.viewDirDependencies);

			_cameraPositionIndex = (cameraPositionReg.index-_vertexConstantsOffset)*4;

			_vertexCode += "sub " + _sharedRegisters.viewDirVarying + ", " + cameraPositionReg + ", " + _sharedRegisters.globalPositionVertex + "\n";
			_fragmentCode += 	"nrm " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.viewDirVarying + ".xyz		\n" +
								"mov " + _sharedRegisters.viewDirFragment + ".w,   " + _sharedRegisters.viewDirVarying + ".w 		\n";

			_registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
		}

		private function compileLightingCode() : void
		{
			var shadowReg : ShaderRegisterElement;

			_sharedRegisters.shadedTarget = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_sharedRegisters.shadedTarget, 1);

			_vertexCode += _methodSetup._diffuseMethod.getVertexCode(_methodSetup._diffuseMethodVO, _registerCache);
			_fragmentCode += _methodSetup._diffuseMethod.getFragmentPreLightingCode(_methodSetup._diffuseMethodVO, _registerCache);

			if (_usingSpecularMethod) {
				_vertexCode += _methodSetup._specularMethod.getVertexCode(_methodSetup._specularMethodVO, _registerCache);
				_fragmentCode += _methodSetup._specularMethod.getFragmentPreLightingCode(_methodSetup._specularMethodVO, _registerCache);
			}

			if (usesLights()) {
				initLightRegisters();
				compileDirectionalLightCode();
				compilePointLightCode();
			}

			if (usesProbes())
				compileLightProbeCode();

			// only need to create and reserve _shadedTargetReg here, no earlier?
			_vertexCode += _methodSetup._ambientMethod.getVertexCode(_methodSetup._ambientMethodVO, _registerCache);
			_fragmentCode += _methodSetup._ambientMethod.getFragmentCode(_methodSetup._ambientMethodVO, _registerCache, _sharedRegisters.shadedTarget);
			if (_methodSetup._ambientMethodVO.needsNormals) _registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
			if (_methodSetup._ambientMethodVO.needsView) _registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);


			if (_methodSetup._shadowMethod) {
				_vertexCode += _methodSetup._shadowMethod.getVertexCode(_methodSetup._shadowMethodVO, _registerCache);
				// using normal to contain shadow data if available is perhaps risky :s
				// todo: improve compilation with lifetime analysis so this isn't necessary?
				if (_dependencyCounter.normalDependencies == 0) {
					shadowReg = _registerCache.getFreeFragmentVectorTemp();
					_registerCache.addFragmentTempUsages(shadowReg, 1);
				}
				else
					shadowReg = _sharedRegisters.normalFragment;

				_methodSetup._diffuseMethod.shadowRegister = shadowReg;
				_fragmentCode += _methodSetup._shadowMethod.getFragmentCode(_methodSetup._shadowMethodVO, _registerCache, shadowReg);
			}
			_fragmentCode += _methodSetup._diffuseMethod.getFragmentPostLightingCode(_methodSetup._diffuseMethodVO, _registerCache, _sharedRegisters.shadedTarget);

			if (_alphaPremultiplied) {
				_fragmentCode += "add " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.commons + ".z\n" +
						"div " + _sharedRegisters.shadedTarget + ".xyz, " + _sharedRegisters.shadedTarget + ".xyz, " + _sharedRegisters.shadedTarget + ".w\n" +
						"sub " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.commons + ".z\n" +
						"sat " + _sharedRegisters.shadedTarget + ".xyz, " + _sharedRegisters.shadedTarget + ".xyz\n";
			}

			// resolve other dependencies as well?
			if (_methodSetup._diffuseMethodVO.needsNormals) _registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
			if (_methodSetup._diffuseMethodVO.needsView) _registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);

			if (_usingSpecularMethod) {
				_methodSetup._specularMethod.shadowRegister = shadowReg;
				_fragmentCode += _methodSetup._specularMethod.getFragmentPostLightingCode(_methodSetup._specularMethodVO, _registerCache, _sharedRegisters.shadedTarget);
				if (_methodSetup._specularMethodVO.needsNormals) _registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
				if (_methodSetup._specularMethodVO.needsView) _registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
			}
		}


		private function initLightRegisters() : void
		{
			// init these first so we're sure they're in sequence
			var i : uint, len : uint;

			len = _dirLightRegisters.length;
			for (i = 0; i < len; ++i) {
				_dirLightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (_lightDataIndex == -1) _lightDataIndex = _dirLightRegisters[i].index*4;
			}

			len = _pointLightRegisters.length;
			for (i = 0; i < len; ++i) {
				_pointLightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (_lightDataIndex == -1) _lightDataIndex = _pointLightRegisters[i].index*4;
			}
		}

		private function compileDirectionalLightCode() : void
		{
			var diffuseColorReg : ShaderRegisterElement;
			var specularColorReg : ShaderRegisterElement;
			var lightDirReg : ShaderRegisterElement;
			var regIndex : int;
			var addSpec : Boolean = _usingSpecularMethod && usesLightsForSpecular();
			var addDiff : Boolean = usesLightsForDiffuse();

			if (!(addSpec || addDiff)) return;

			for (var i : uint = 0; i < _numDirectionalLights; ++i) {
				lightDirReg = _dirLightRegisters[regIndex++];
				diffuseColorReg = _dirLightRegisters[regIndex++];
				specularColorReg = _dirLightRegisters[regIndex++];
				if (addDiff)
					_fragmentCode += _methodSetup._diffuseMethod.getFragmentCodePerLight(_methodSetup._diffuseMethodVO, lightDirReg, diffuseColorReg, _registerCache);
				if (addSpec)
					_fragmentCode += _methodSetup._specularMethod.getFragmentCodePerLight(_methodSetup._specularMethodVO, lightDirReg, specularColorReg, _registerCache);
			}
		}

		private function compilePointLightCode() : void
		{
			var diffuseColorReg : ShaderRegisterElement;
			var specularColorReg : ShaderRegisterElement;
			var lightPosReg : ShaderRegisterElement;
			var lightDirReg : ShaderRegisterElement;
			var regIndex : int;
			var addSpec : Boolean = _usingSpecularMethod && usesLightsForSpecular();
			var addDiff : Boolean = usesLightsForDiffuse();

			if (!(addSpec || addDiff)) return;

			for (var i : uint = 0; i < _numPointLights; ++i) {
				lightPosReg = _pointLightRegisters[regIndex++];
				diffuseColorReg = _pointLightRegisters[regIndex++];
				specularColorReg = _pointLightRegisters[regIndex++];
				lightDirReg = _registerCache.getFreeFragmentVectorTemp();
				_registerCache.addFragmentTempUsages(lightDirReg, 1);

				// calculate direction
				_fragmentCode += "sub " + lightDirReg + ", " + lightPosReg + ", " + _sharedRegisters.globalPositionVarying + "\n" +
					// attenuate
						"dp3 " + lightDirReg + ".w, " + lightDirReg + ".xyz, " + lightDirReg + ".xyz\n" +
						"sqt " + lightDirReg + ".w, " + lightDirReg + ".w\n" +
					// w = d - radis
						"sub " + lightDirReg + ".w, " + lightDirReg + ".w, " + diffuseColorReg + ".w\n" +
					// w = (d - radius)/(max-min)
						"mul " + lightDirReg + ".w, " + lightDirReg + ".w, " + specularColorReg + ".w\n" +
					// w = clamp(w, 0, 1)
						"sat " + lightDirReg + ".w, " + lightDirReg + ".w\n" +
					// w = 1-w
						"sub " + lightDirReg + ".w, " + lightPosReg + ".w, " + lightDirReg + ".w\n" +
					// normalize
						"nrm " + lightDirReg + ".xyz, " + lightDirReg + ".xyz	\n";

				if (_lightDataIndex == -1) _lightDataIndex = lightPosReg.index*4;

				if (addDiff)
					_fragmentCode += _methodSetup._diffuseMethod.getFragmentCodePerLight(_methodSetup._diffuseMethodVO, lightDirReg, diffuseColorReg, _registerCache);

				if (addSpec)
					_fragmentCode += _methodSetup._specularMethod.getFragmentCodePerLight(_methodSetup._specularMethodVO, lightDirReg, specularColorReg, _registerCache);

				_registerCache.removeFragmentTempUsage(lightDirReg);
			}
		}

		private function compileLightProbeCode() : void
		{
			var weightReg : String;
			var weightComponents : Array = [ ".x", ".y", ".z", ".w" ];
			var weightRegisters : Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>();
			var i : uint;
			var texReg : ShaderRegisterElement;
			var addSpec : Boolean = _usingSpecularMethod && usesProbesForSpecular();
			var addDiff : Boolean = usesProbesForDiffuse();

			if (!(addSpec || addDiff)) return;

			if (addDiff)
				_lightProbeDiffuseIndices = new Vector.<uint>();
			if (addSpec)
				_lightProbeSpecularIndices = new Vector.<uint>();

			for (i = 0; i < _numProbeRegisters; ++i) {
				weightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (i == 0) _probeWeightsIndex = weightRegisters[i].index*4;
			}

			for (i = 0; i < _numLightProbes; ++i) {
				weightReg = weightRegisters[Math.floor(i/4)].toString() + weightComponents[i % 4];

				if (addDiff) {
					texReg = _registerCache.getFreeTextureReg();
					_lightProbeDiffuseIndices[i] = texReg.index;
					_fragmentCode += _methodSetup._diffuseMethod.getFragmentCodePerProbe(_methodSetup._diffuseMethodVO, texReg, weightReg, _registerCache);
				}

				if (addSpec) {
					texReg = _registerCache.getFreeTextureReg();
					_lightProbeSpecularIndices[i] = texReg.index;
					_fragmentCode += _methodSetup._specularMethod.getFragmentCodePerProbe(_methodSetup._specularMethodVO, texReg, weightReg, _registerCache);
				}
			}
		}

		private function compileMethods() : void
		{
			var methods : Vector.<MethodVOSet> = _methodSetup._methods;
			var numMethods : uint = methods.length;
			var method : EffectMethodBase;
			var data : MethodVO;
			var alphaReg : ShaderRegisterElement;

			if (_preserveAlpha) {
				alphaReg = _registerCache.getFreeFragmentSingleTemp();
				_registerCache.addFragmentTempUsages(alphaReg, 1);
				_fragmentCode += "mov " + alphaReg + ", " + _sharedRegisters.shadedTarget + ".w\n";
			}

			for (var i : uint = 0; i < numMethods; ++i) {
				method = methods[i].method;
				data = methods[i].data;
				_vertexCode += method.getVertexCode(data, _registerCache);
				if (data.needsGlobalPos) _registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);

				_fragmentCode += method.getFragmentCode(data, _registerCache, _sharedRegisters.shadedTarget);
				if (data.needsNormals) _registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
				if (data.needsView) _registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
			}

			if (_preserveAlpha) {
				_fragmentCode += "mov " + _sharedRegisters.shadedTarget + ".w, " + alphaReg + "\n";
				_registerCache.removeFragmentTempUsage(alphaReg);
			}

			if (_methodSetup._colorTransformMethod) {
				_vertexCode += _methodSetup._colorTransformMethod.getVertexCode(_methodSetup._colorTransformMethodVO, _registerCache);
				_fragmentCode += _methodSetup._colorTransformMethod.getFragmentCode(_methodSetup._colorTransformMethodVO, _registerCache, _sharedRegisters.shadedTarget);
			}
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

		public function get usesNormals() : Boolean
		{
			return _dependencyCounter.normalDependencies > 0 && _methodSetup._normalMethod.hasOutput;
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

		public function get lightProbeDiffuseIndices() : Vector.<uint>
		{
			return _lightProbeDiffuseIndices;
		}

		public function get lightProbeSpecularIndices() : Vector.<uint>
		{
			return _lightProbeSpecularIndices;
		}

		public function get numUsedVertexConstants() : uint
		{
			return _registerCache.numUsedVertexConstants;
		}

		public function get numUsedFragmentConstants() : uint
		{
			return _registerCache.numUsedFragmentConstants;
		}

		public function get numUsedStreams() : uint
		{
			return _registerCache.numUsedStreams;
		}

		public function get numUsedTextures() : uint
		{
			return _registerCache.numUsedTextures;
		}

		public function dispose() : void
		{
			cleanUpMethods();
			_registerCache.dispose();
			_registerCache = null;
			_sharedRegisters = null;
		}

		private function cleanUpMethods() : void
		{
			if (_methodSetup._normalMethod) _methodSetup._normalMethod.cleanCompilationData();
			if (_methodSetup._diffuseMethod) _methodSetup._diffuseMethod.cleanCompilationData();
			if (_methodSetup._ambientMethod) _methodSetup._ambientMethod.cleanCompilationData();
			if (_methodSetup._specularMethod) _methodSetup._specularMethod.cleanCompilationData();
			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.cleanCompilationData();
			if (_methodSetup._colorTransformMethod) _methodSetup._colorTransformMethod.cleanCompilationData();

			var methods : Vector.<MethodVOSet> = _methodSetup._methods;
			var len : uint = methods.length;
			for (var i : uint = 0; i < len; ++i)
				methods[i].method.cleanCompilationData();
		}
	}
}