package away3d.materials.compilation
{
	import away3d.arcane;

	public class SuperShaderCompiler extends ShaderCompiler
	{
		public var _pointLightRegisters : Vector.<ShaderRegisterElement>;
		public var _dirLightRegisters : Vector.<ShaderRegisterElement>;

		use namespace arcane;

		public function SuperShaderCompiler()
		{
			super();
		}

		override protected function initLightData() : void
		{
			super.initLightData();

			_pointLightRegisters = new Vector.<ShaderRegisterElement>(_numPointLights * 3, true);
			_dirLightRegisters = new Vector.<ShaderRegisterElement>(_numDirectionalLights * 3, true);
		}

		/**
		 * Calculates register dependencies for commonly used data.
		 */
		override protected function calculateDependencies() : void
		{
			super.calculateDependencies();
			_dependencyCounter.addWorldSpaceDependencies(true);
		}

		override protected function compileNormalCode() : void
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
					"m33 " + _sharedRegisters.normalFragment + ".xyz, " + temp + ".xyz, " + t + "	\n" +
					"mov " + _sharedRegisters.normalFragment + ".w,   " + _sharedRegisters.normalVarying + ".w			\n";

			_registerCache.removeFragmentTempUsage(temp);

			if (_methodSetup._normalMethodVO.needsView) _registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
			if (_methodSetup._normalMethodVO.needsGlobalVertexPos || _methodSetup._normalMethodVO.needsGlobalFragmentPos) _registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
			_registerCache.removeFragmentTempUsage(b);
			_registerCache.removeFragmentTempUsage(t);
			_registerCache.removeFragmentTempUsage(n);
		}

		override protected function compileViewDirCode() : void
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

		override protected function compileLightingCode() : void
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
				if (_lightFragmentConstantIndex == -1) _lightFragmentConstantIndex = _dirLightRegisters[i].index*4;
			}

			len = _pointLightRegisters.length;
			for (i = 0; i < len; ++i) {
				_pointLightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (_lightFragmentConstantIndex == -1) _lightFragmentConstantIndex = _pointLightRegisters[i].index*4;
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

				if (_lightFragmentConstantIndex == -1) _lightFragmentConstantIndex = lightPosReg.index*4;

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
	}
}