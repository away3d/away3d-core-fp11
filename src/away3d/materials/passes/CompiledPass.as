package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Matrix3DUtils;
	import away3d.errors.AbstractMethodError;
	import away3d.events.ShadingMethodEvent;
	import away3d.materials.LightSources;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.ShaderCompiler;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicNormalMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.MethodVOSet;
	import away3d.materials.methods.ShaderMethodSetup;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class CompiledPass extends MaterialPassBase
	{
		arcane var _passes : Vector.<MaterialPassBase>;
		arcane var _passesDirty : Boolean;

		protected var _specularLightSources : uint = 0x01;
		protected var _diffuseLightSources : uint = 0x03;

		protected var _vertexCode : String;
		protected var _fragmentLightCode : String;
		protected var _framentPostLightCode : String;

		protected var _vertexConstantData : Vector.<Number> = new Vector.<Number>();
		protected var _fragmentConstantData : Vector.<Number> = new Vector.<Number>();
		protected var _commonsDataIndex : int;
		protected var _probeWeightsIndex : int;
		protected var _uvBufferIndex : int;
		protected var _secondaryUVBufferIndex : int;
		protected var _normalBufferIndex : int;
		protected var _tangentBufferIndex : int;
		protected var _sceneMatrixIndex : int;
		protected var _sceneNormalMatrixIndex : int;
		protected var _lightFragmentConstantIndex : int;
		protected var _cameraPositionIndex : int;
		protected var _uvTransformIndex : int;
		protected var _lightProbeDiffuseIndices : Vector.<uint>;
		protected var _lightProbeSpecularIndices : Vector.<uint>;

		protected var _ambientLightR : Number;
		protected var _ambientLightG : Number;
		protected var _ambientLightB : Number;

		protected var _compiler : ShaderCompiler;

		protected var _methodSetup : ShaderMethodSetup;

		protected var _usingSpecularMethod : Boolean;
		protected var _usesNormals : Boolean;
		protected var _preserveAlpha : Boolean = true;
		protected var _animateUVs : Boolean;

		protected var _numPointLights : uint;
		protected var _numDirectionalLights : uint;
		protected var _numLightProbes : uint;

		protected var _enableLightFallOff : Boolean = true;

		private var _forceSeparateMVP : Boolean;

		public function CompiledPass(material : MaterialBase)
		{
			_material = material;

			init();
		}

		public function get enableLightFallOff() : Boolean
		{
			return _enableLightFallOff;
		}

		public function set enableLightFallOff(value : Boolean) : void
		{
			if (value != _enableLightFallOff) invalidateShaderProgram(true);
			_enableLightFallOff = value;
		}

		public function get forceSeparateMVP() : Boolean
		{
			return _forceSeparateMVP;
		}

		public function set forceSeparateMVP(value : Boolean) : void
		{
			_forceSeparateMVP = value;
		}

		arcane function get numPointLights() : uint
		{
			return _numPointLights;
		}

		arcane function get numDirectionalLights() : uint
		{
			return _numDirectionalLights;
		}

		arcane function get numLightProbes() : uint
		{
			return _numLightProbes;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function updateProgram(stage3DProxy : Stage3DProxy) : void
		{
			reset(stage3DProxy.profile);
			super.updateProgram(stage3DProxy);
		}

		/**
		 * Resets the compilation state.
		 */
		private function reset(profile : String) : void
		{
			initCompiler(profile);
			updateShaderProperties();
			initConstantData();
			cleanUp();
		}

		private function updateUsedOffsets() : void
		{
			_numUsedVertexConstants = _compiler.numUsedVertexConstants;
			_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
			_numUsedStreams = _compiler.numUsedStreams;
			_numUsedTextures = _compiler.numUsedTextures;
			_numUsedVaryings = _compiler.numUsedVaryings;
			_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
		}

		private function initConstantData() : void
		{
			_vertexConstantData.length = _numUsedVertexConstants * 4;
			_fragmentConstantData.length = _numUsedFragmentConstants * 4;

			initCommonsData();
			if (_uvTransformIndex >= 0)
				initUVTransformData();
			if (_cameraPositionIndex >= 0)
				_vertexConstantData[_cameraPositionIndex + 3] = 1;

			updateMethodConstants();
		}

		protected function initCompiler(profile : String) : void
		{
			_compiler = createCompiler(profile);
			_compiler.forceSeperateMVP = _forceSeparateMVP;
			_compiler.numPointLights = _numPointLights;
			_compiler.numDirectionalLights = _numDirectionalLights;
			_compiler.numLightProbes = _numLightProbes;
			_compiler.methodSetup = _methodSetup;
			_compiler.diffuseLightSources = _diffuseLightSources;
			_compiler.specularLightSources = _specularLightSources;
			_compiler.setTextureSampling(_smooth, _repeat, _mipmap);
			_compiler.setConstantDataBuffers(_vertexConstantData, _fragmentConstantData);
			_compiler.animateUVs = _animateUVs;
			_compiler.alphaPremultiplied = _alphaPremultiplied && _enableBlending;
			_compiler.preserveAlpha = _preserveAlpha && _enableBlending;
			_compiler.enableLightFallOff = _enableLightFallOff;
			_compiler.compile();
		}

		protected function createCompiler(profile : String) : ShaderCompiler
		{
			throw new AbstractMethodError();
		}

		protected function updateShaderProperties() : void
		{
			_animatableAttributes = _compiler.animatableAttributes;
			_animationTargetRegisters = _compiler.animationTargetRegisters;
			_vertexCode = _compiler.vertexCode;
			_fragmentLightCode = _compiler.fragmentLightCode;
			_framentPostLightCode = _compiler.fragmentPostLightCode;
			_shadedTarget = _compiler.shadedTarget;
			_usingSpecularMethod = _compiler.usingSpecularMethod;
			_usesNormals = _compiler.usesNormals;
			_needUVAnimation = _compiler.needUVAnimation;
			_UVSource = _compiler.UVSource;
			_UVTarget = _compiler.UVTarget;

			updateRegisterIndices();
			updateUsedOffsets();
		}

		protected function updateRegisterIndices() : void
		{
			_uvBufferIndex = _compiler.uvBufferIndex;
			_uvTransformIndex = _compiler.uvTransformIndex;
			_secondaryUVBufferIndex = _compiler.secondaryUVBufferIndex;
			_normalBufferIndex = _compiler.normalBufferIndex;
			_tangentBufferIndex = _compiler.tangentBufferIndex;
			_lightFragmentConstantIndex = _compiler.lightFragmentConstantIndex;
			_cameraPositionIndex = _compiler.cameraPositionIndex;
			_commonsDataIndex = _compiler.commonsDataIndex;
			_sceneMatrixIndex = _compiler.sceneMatrixIndex;
			_sceneNormalMatrixIndex = _compiler.sceneNormalMatrixIndex;
			_probeWeightsIndex = _compiler.probeWeightsIndex;
			_lightProbeDiffuseIndices = _compiler.lightProbeDiffuseIndices;
			_lightProbeSpecularIndices = _compiler.lightProbeSpecularIndices;
		}

		public function get preserveAlpha() : Boolean
		{
			return _preserveAlpha;
		}

		public function set preserveAlpha(value : Boolean) : void
		{
			if (_preserveAlpha == value) return;
			_preserveAlpha = value;
			invalidateShaderProgram();
		}

		public function get animateUVs() : Boolean
		{
			return _animateUVs;
		}

		public function set animateUVs(value : Boolean) : void
		{
			_animateUVs = value;
			if ((value && !_animateUVs) || (!value && _animateUVs)) invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override public function set mipmap(value : Boolean) : void
		{
			if (_mipmap == value) return;
			super.mipmap = value;
		}

		/**
		 * The tangent space normal map to influence the direction of the surface for each texel.
		 */
		public function get normalMap() : Texture2DBase
		{
			return _methodSetup._normalMethod.normalMap;
		}

		public function set normalMap(value : Texture2DBase) : void
		{
			_methodSetup._normalMethod.normalMap = value;
		}

		public function get normalMethod() : BasicNormalMethod
		{
			return _methodSetup.normalMethod;
		}

		public function set normalMethod(value : BasicNormalMethod) : void
		{
			_methodSetup.normalMethod = value;
		}

		public function get ambientMethod() : BasicAmbientMethod
		{
			return _methodSetup.ambientMethod;
		}

		public function set ambientMethod(value : BasicAmbientMethod) : void
		{
			_methodSetup.ambientMethod = value;
		}

		public function get shadowMethod() : ShadowMapMethodBase
		{
			return _methodSetup.shadowMethod;
		}

		public function set shadowMethod(value : ShadowMapMethodBase) : void
		{
			_methodSetup.shadowMethod = value;
		}

		public function get diffuseMethod() : BasicDiffuseMethod
		{
			return _methodSetup.diffuseMethod;
		}

		public function set diffuseMethod(value : BasicDiffuseMethod) : void
		{
			_methodSetup.diffuseMethod = value;
		}

		public function get specularMethod() : BasicSpecularMethod
		{
			return _methodSetup.specularMethod;
		}

		public function set specularMethod(value : BasicSpecularMethod) : void
		{
			_methodSetup.specularMethod = value;
		}

		private function init() : void
		{
			_methodSetup = new ShaderMethodSetup();
			_methodSetup.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			super.dispose();
			_methodSetup.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_methodSetup.dispose();
			_methodSetup = null;
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		arcane override function invalidateShaderProgram(updateMaterial : Boolean = true) : void
		{
			var oldPasses : Vector.<MaterialPassBase> = _passes;
			_passes = new Vector.<MaterialPassBase>();

			if (_methodSetup) addPassesFromMethods();

			if (!oldPasses || _passes.length != oldPasses.length) {
				_passesDirty = true;
				return;
			}

			for (var i : int = 0; i < _passes.length; ++i) {
				if (_passes[i] != oldPasses[i]) {
					_passesDirty = true;
					return;
				}
			}

			super.invalidateShaderProgram(updateMaterial);
		}

		protected function addPassesFromMethods() : void
		{
			if (_methodSetup._normalMethod && _methodSetup._normalMethod.hasOutput) addPasses(_methodSetup._normalMethod.passes);
			if (_methodSetup._ambientMethod) addPasses(_methodSetup._ambientMethod.passes);
			if (_methodSetup._shadowMethod) addPasses(_methodSetup._shadowMethod.passes);
			if (_methodSetup._diffuseMethod) addPasses(_methodSetup._diffuseMethod.passes);
			if (_methodSetup._specularMethod) addPasses(_methodSetup._specularMethod.passes);
		}

		/**
		 * Adds passes to the list.
		 */
		protected function addPasses(passes : Vector.<MaterialPassBase>) : void
		{
			if (!passes) return;

			var len : uint = passes.length;

			for (var i : uint = 0; i < len; ++i) {
				passes[i].material = material;
				passes[i].lightPicker = _lightPicker;
				_passes.push(passes[i]);
			}
		}

		protected function initUVTransformData() : void
		{
			_vertexConstantData[_uvTransformIndex] = 1;
			_vertexConstantData[_uvTransformIndex + 1] = 0;
			_vertexConstantData[_uvTransformIndex + 2] = 0;
			_vertexConstantData[_uvTransformIndex + 3] = 0;
			_vertexConstantData[_uvTransformIndex + 4] = 0;
			_vertexConstantData[_uvTransformIndex + 5] = 1;
			_vertexConstantData[_uvTransformIndex + 6] = 0;
			_vertexConstantData[_uvTransformIndex + 7] = 0;
		}

		protected function initCommonsData() : void
		{
			_fragmentConstantData[_commonsDataIndex] = .5;
			_fragmentConstantData[_commonsDataIndex + 1] = 0;
			_fragmentConstantData[_commonsDataIndex + 2] = 1 / 255;
			_fragmentConstantData[_commonsDataIndex + 3] = 1;
		}

		protected function cleanUp() : void
		{
			_compiler.dispose();
			_compiler = null;
		}

		protected function updateMethodConstants() : void
		{
			if (_methodSetup._normalMethod) _methodSetup._normalMethod.initConstants(_methodSetup._normalMethodVO);
			if (_methodSetup._diffuseMethod) _methodSetup._diffuseMethod.initConstants(_methodSetup._diffuseMethodVO);
			if (_methodSetup._ambientMethod) _methodSetup._ambientMethod.initConstants(_methodSetup._ambientMethodVO);
			if (_usingSpecularMethod) _methodSetup._specularMethod.initConstants(_methodSetup._specularMethodVO);
			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.initConstants(_methodSetup._shadowMethodVO);
		}

		protected function updateLightConstants() : void
		{

		}

		protected function updateProbes(stage3DProxy : Stage3DProxy) : void
		{

		}

		private function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}


		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			return _vertexCode;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(animatorCode : String) : String
		{
			return _fragmentLightCode + animatorCode + _framentPostLightCode;
		}

// RENDER LOOP

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			super.activate(stage3DProxy, camera);

			if (_usesNormals) _methodSetup._normalMethod.activate(_methodSetup._normalMethodVO, stage3DProxy);
			_methodSetup._ambientMethod.activate(_methodSetup._ambientMethodVO, stage3DProxy);
			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.activate(_methodSetup._shadowMethodVO, stage3DProxy);
			_methodSetup._diffuseMethod.activate(_methodSetup._diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod) _methodSetup._specularMethod.activate(_methodSetup._specularMethodVO, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, viewProjection : Matrix3D) : void
		{
			var i : uint;
			var context : Context3D = stage3DProxy._context3D;
			if (_uvBufferIndex >= 0) renderable.activateUVBuffer(_uvBufferIndex, stage3DProxy);
			if (_secondaryUVBufferIndex >= 0) renderable.activateSecondaryUVBuffer(_secondaryUVBufferIndex, stage3DProxy);
			if (_normalBufferIndex >= 0) renderable.activateVertexNormalBuffer(_normalBufferIndex, stage3DProxy);
			if (_tangentBufferIndex >= 0) renderable.activateVertexTangentBuffer(_tangentBufferIndex, stage3DProxy);

			if (_animateUVs) {
				var uvTransform : Matrix = renderable.uvTransform;
				if (uvTransform) {
					_vertexConstantData[_uvTransformIndex] = uvTransform.a;
					_vertexConstantData[_uvTransformIndex + 1] = uvTransform.b;
					_vertexConstantData[_uvTransformIndex + 3] = uvTransform.tx;
					_vertexConstantData[_uvTransformIndex + 4] = uvTransform.c;
					_vertexConstantData[_uvTransformIndex + 5] = uvTransform.d;
					_vertexConstantData[_uvTransformIndex + 7] = uvTransform.ty;
				}
				else {
					_vertexConstantData[_uvTransformIndex] = 1;
					_vertexConstantData[_uvTransformIndex + 1] = 0;
					_vertexConstantData[_uvTransformIndex + 3] = 0;
					_vertexConstantData[_uvTransformIndex + 4] = 0;
					_vertexConstantData[_uvTransformIndex + 5] = 1;
					_vertexConstantData[_uvTransformIndex + 7] = 0;
				}
			}

			_ambientLightR = _ambientLightG = _ambientLightB = 0;

			if (usesLights())
				updateLightConstants();

			if (usesProbes())
				updateProbes(stage3DProxy);

			if (_sceneMatrixIndex >= 0) {
				renderable.getRenderSceneTransform(camera).copyRawDataTo(_vertexConstantData, _sceneMatrixIndex, true);
				viewProjection.copyRawDataTo(_vertexConstantData, 0, true);
			}
			else {
				var matrix3D : Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
				matrix3D.copyFrom(renderable.getRenderSceneTransform(camera));
				matrix3D.append(viewProjection);
				matrix3D.copyRawDataTo(_vertexConstantData, 0, true);
			}

			if (_sceneNormalMatrixIndex >= 0)
				renderable.inverseSceneTransform.copyRawDataTo(_vertexConstantData, _sceneNormalMatrixIndex, false);

			if (_usesNormals)
				_methodSetup._normalMethod.setRenderState(_methodSetup._normalMethodVO, renderable, stage3DProxy, camera);

			var ambientMethod : BasicAmbientMethod = _methodSetup._ambientMethod;
			ambientMethod._lightAmbientR = _ambientLightR;
			ambientMethod._lightAmbientG = _ambientLightG;
			ambientMethod._lightAmbientB = _ambientLightB;
			ambientMethod.setRenderState(_methodSetup._ambientMethodVO, renderable, stage3DProxy, camera);

			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.setRenderState(_methodSetup._shadowMethodVO, renderable, stage3DProxy, camera);
			_methodSetup._diffuseMethod.setRenderState(_methodSetup._diffuseMethodVO, renderable, stage3DProxy, camera);
			if (_usingSpecularMethod) _methodSetup._specularMethod.setRenderState(_methodSetup._specularMethodVO, renderable, stage3DProxy, camera);
			if (_methodSetup._colorTransformMethod) _methodSetup._colorTransformMethod.setRenderState(_methodSetup._colorTransformMethodVO, renderable, stage3DProxy, camera);

			var methods : Vector.<MethodVOSet> = _methodSetup._methods;
			var len : uint = methods.length;
			for (i = 0; i < len; ++i) {
				var set : MethodVOSet = methods[i];
				set.method.setRenderState(set.data, renderable, stage3DProxy, camera);
			}

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexConstantData, _numUsedVertexConstants);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentConstantData, _numUsedFragmentConstants);

			renderable.activateVertexBuffer(0, stage3DProxy);
			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}

		protected function usesProbes() : Boolean
		{
			return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
		}

		protected function usesLights() : Boolean
		{
			return (_numPointLights > 0 || _numDirectionalLights > 0) && ((_diffuseLightSources | _specularLightSources) & LightSources.LIGHTS) != 0;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			super.deactivate(stage3DProxy);

			if (_usesNormals) _methodSetup._normalMethod.deactivate(_methodSetup._normalMethodVO, stage3DProxy);
			_methodSetup._ambientMethod.deactivate(_methodSetup._ambientMethodVO, stage3DProxy);
			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.deactivate(_methodSetup._shadowMethodVO, stage3DProxy);
			_methodSetup._diffuseMethod.deactivate(_methodSetup._diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod) _methodSetup._specularMethod.deactivate(_methodSetup._specularMethodVO, stage3DProxy);
		}

//		override protected function updateLights() : void
//		{
//			for (var i : int = 0; i < _passes.length; ++i)
//				_passes[i].lightPicker = _lightPicker;
//		}

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
	}
}
