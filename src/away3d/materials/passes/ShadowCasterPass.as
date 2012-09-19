package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.lights.DirectionalLight;
	import away3d.lights.PointLight;
	import away3d.materials.LightSources;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.SuperShaderCompiler;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicNormalMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.ShaderMethodSetup;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */

	public class ShadowCasterPass extends CompiledPass
	{

		/**
		 * Creates a new DefaultScreenPass objects.
		 */
		public function ShadowCasterPass(material : MaterialBase)
		{
			super();
			_material = material;

			init();
		}

		private function init() : void
		{
			_methodSetup = new ShaderMethodSetup();
			_methodSetup.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
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

		override protected function updateLights() : void
		{
			_numPointLights = _lightPicker.numCastingPointLights > 0? 1 : 0;
			_numDirectionalLights = _lightPicker.numCastingDirectionalLights > 0? 1 : 0;
			_numLightProbes = 0;
			if (_numPointLights == _numDirectionalLights) throw new Error("Must have exactly one light!");

			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(animatorCode : String) : String
		{
			return animatorCode + _vertexCode;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			return _fragmentCode;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			if (_usesNormals) _methodSetup._normalMethod.activate(_methodSetup._normalMethodVO, stage3DProxy);
			_methodSetup._ambientMethod.activate(_methodSetup._ambientMethodVO, stage3DProxy);
			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.activate(_methodSetup._shadowMethodVO, stage3DProxy);
			_methodSetup._diffuseMethod.activate(_methodSetup._diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod) _methodSetup._specularMethod.activate(_methodSetup._specularMethodVO, stage3DProxy);

			if (_cameraPositionIndex >= 0) {
				var pos : Vector3D = camera.scenePosition;
				_vertexConstantData[_cameraPositionIndex] = pos.x;
				_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
				_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
			}
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

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var i : uint;
			var context : Context3D = stage3DProxy._context3D;
			if (_uvBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_uvBufferIndex, renderable.getUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2, renderable.UVBufferOffset);
			if (_secondaryUVBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_secondaryUVBufferIndex, renderable.getSecondaryUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2, renderable.secondaryUVBufferOffset);
			if (_normalBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_normalBufferIndex, renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.normalBufferOffset);
			if (_tangentBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_tangentBufferIndex, renderable.getVertexTangentBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.tangentBufferOffset);

			var uvTransform : Matrix;
			if (_animateUVs) {
				uvTransform = renderable.uvTransform;
				if (uvTransform) {
					_vertexConstantData[_uvTransformIndex] = uvTransform.a;
					_vertexConstantData[_uvTransformIndex + 1] = uvTransform.b;
					_vertexConstantData[_uvTransformIndex + 3] = uvTransform.tx;
					_vertexConstantData[_uvTransformIndex + 4] = uvTransform.c;
					_vertexConstantData[_uvTransformIndex + 5] = uvTransform.d;
					_vertexConstantData[_uvTransformIndex + 7] = uvTransform.ty;
				}
				else {
					trace("Warning: animateUVs is set to true with an IRenderable without a uvTransform. Identity matrix assumed.");
					_vertexConstantData[_uvTransformIndex] = 1;
					_vertexConstantData[_uvTransformIndex + 1] = 0;
					_vertexConstantData[_uvTransformIndex + 3] = 0;
					_vertexConstantData[_uvTransformIndex + 4] = 0;
					_vertexConstantData[_uvTransformIndex + 5] = 1;
					_vertexConstantData[_uvTransformIndex + 7] = 0;
				}
			}

			_ambientLightR = _ambientLightG = _ambientLightB = 0;

			updateLightConstants();

			if (_sceneMatrixIndex >= 0)
				renderable.sceneTransform.copyRawDataTo(_vertexConstantData, _sceneMatrixIndex, true);

			if (_sceneNormalMatrixIndex >= 0)
				renderable.inverseSceneTransform.copyRawDataTo(_vertexConstantData, _sceneNormalMatrixIndex, false);

			if (_usesNormals)
				_methodSetup._normalMethod.setRenderState(_methodSetup._normalMethodVO, renderable, stage3DProxy, camera);

			var ambientMethod : BasicAmbientMethod = _methodSetup._ambientMethod;
			ambientMethod.setRenderState(_methodSetup._ambientMethodVO, renderable, stage3DProxy, camera);
			ambientMethod._lightAmbientR = _ambientLightR;
			ambientMethod._lightAmbientG = _ambientLightG;
			ambientMethod._lightAmbientB = _ambientLightB;

			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.setRenderState(_methodSetup._shadowMethodVO, renderable, stage3DProxy, camera);
			_methodSetup._diffuseMethod.setRenderState(_methodSetup._diffuseMethodVO, renderable, stage3DProxy, camera);
			if (_usingSpecularMethod) _methodSetup._specularMethod.setRenderState(_methodSetup._specularMethodVO, renderable, stage3DProxy, camera);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _vertexConstantsOffset, _vertexConstantData, _numUsedVertexConstants - _vertexConstantsOffset);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentConstantData, _numUsedFragmentConstants);

			super.render(renderable, stage3DProxy, camera);
		}


		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		arcane override function invalidateShaderProgram(updateMaterial : Boolean = true) : void
		{
			super.invalidateShaderProgram(updateMaterial);
			addPassesFromMethods();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function updateProgram(stage3DProxy : Stage3DProxy) : void
		{
			reset();

			super.updateProgram(stage3DProxy);
		}

		/**
		 * Resets the compilation state.
		 */
		private function reset() : void
		{
			_compiler = new SuperShaderCompiler();
			initCompiler();
			updateShaderProperties();
			initConstantData();
			cleanUp();
		}

		private function initCompiler() : void
		{
			_compiler.numPointLights = _numPointLights;
			_compiler.numDirectionalLights = _numDirectionalLights;
			_compiler.numLightProbes = _numLightProbes;
			_compiler.methodSetup = _methodSetup;
			_compiler.diffuseLightSources = LightSources.LIGHTS;
			_compiler.specularLightSources = LightSources.LIGHTS;
			_compiler.setTextureSampling(_smooth, _repeat, _mipmap);
			_compiler.setConstantDataBuffers(_vertexConstantData, _fragmentConstantData);
			_compiler.animateUVs = _animateUVs;
			_compiler.alphaPremultiplied = _alphaPremultiplied;
			_compiler.preserveAlpha = _preserveAlpha;
			_compiler.compile();
		}

		private function updateShaderProperties() : void
		{
			_animatableAttributes = _compiler.animatableAttributes;
			_animationTargetRegisters = _compiler.animationTargetRegisters;
			_vertexCode = _compiler.vertexCode;
			_fragmentCode = _compiler.fragmentCode;
			_usingSpecularMethod = _compiler.usingSpecularMethod;
			_usesNormals = _compiler.usesNormals;

			updateRegisterIndices();
			updateUsedOffsets();
		}

		private function updateRegisterIndices() : void
		{
			_vertexConstantsOffset = _compiler.vertexConstantsOffset;
			_uvBufferIndex = _compiler.uvBufferIndex;
			_uvTransformIndex = _compiler.uvTransformIndex;
			_secondaryUVBufferIndex = _compiler.secondaryUVBufferIndex;
			_normalBufferIndex = _compiler.normalBufferIndex;
			_tangentBufferIndex = _compiler.tangentBufferIndex;
			_lightDataIndex = _compiler.lightDataIndex;
			_cameraPositionIndex = _compiler.cameraPositionIndex;
			_commonsDataIndex = _compiler.commonsDataIndex;
			_sceneMatrixIndex = _compiler.sceneMatrixIndex;
			_sceneNormalMatrixIndex = _compiler.sceneNormalMatrixIndex;
			_probeWeightsIndex = _compiler.probeWeightsIndex;
			_lightProbeDiffuseIndices = _compiler.lightProbeDiffuseIndices;
			_lightProbeSpecularIndices = _compiler.lightProbeSpecularIndices;
		}

		private function updateUsedOffsets() : void
		{
			_numUsedVertexConstants = _compiler.numUsedVertexConstants;
			_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
			_numUsedStreams = _compiler.numUsedStreams;
			_numUsedTextures = _compiler.numUsedTextures;
		}

		private function initConstantData() : void
		{
			_vertexConstantData.length = (_numUsedVertexConstants - _vertexConstantsOffset) * 4;
			_fragmentConstantData.length = _numUsedFragmentConstants * 4;

			initCommonsData();
			if (_uvTransformIndex >= 0)
				initUVTransformData();
			if (_cameraPositionIndex >= 0)
				_vertexConstantData[_cameraPositionIndex + 3] = 1;

			updateMethodConstants();
		}

		private function updateMethodConstants() : void
		{
			if (_methodSetup._normalMethod) _methodSetup._normalMethod.initConstants(_methodSetup._normalMethodVO);
			if (_methodSetup._diffuseMethod) _methodSetup._diffuseMethod.initConstants(_methodSetup._diffuseMethodVO);
			if (_methodSetup._ambientMethod) _methodSetup._ambientMethod.initConstants(_methodSetup._ambientMethodVO);
			if (_usingSpecularMethod) _methodSetup._specularMethod.initConstants(_methodSetup._specularMethodVO);
			if (_methodSetup._shadowMethod) _methodSetup._shadowMethod.initConstants(_methodSetup._shadowMethodVO);
		}

		private function initUVTransformData() : void
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

		// TODO: Probably should let the compiler init this, since only it knows what it's for
		private function initCommonsData() : void
		{
			_fragmentConstantData[_commonsDataIndex] = .5;
			_fragmentConstantData[_commonsDataIndex + 1] = 0;
			_fragmentConstantData[_commonsDataIndex + 2] = 1 / 255;
			_fragmentConstantData[_commonsDataIndex + 3] = 1;
		}

		private function cleanUp() : void
		{
			_compiler.dispose();
			_compiler = null;
		}


		/**
		 * Updates the lights data for the render state.
		 * @param lights The lights selected to shade the current object.
		 * @param numLights The amount of lights available.
		 * @param maxLights The maximum amount of lights supported.
		 */
		private function updateLightConstants() : void
		{
			// first dirs, then points
			var dirLight : DirectionalLight;
			var pointLight : PointLight;
			var i : uint, k : uint;
			var dirPos : Vector3D;

			k = _lightDataIndex;

			if (_numDirectionalLights > 0) {
				dirLight = _lightPicker.castingDirectionalLights[0];
				dirPos = dirLight.sceneDirection;

				_ambientLightR += dirLight._ambientR;
				_ambientLightG += dirLight._ambientG;
				_ambientLightB += dirLight._ambientB;

				_fragmentConstantData[k++] = -dirPos.x;
				_fragmentConstantData[k++] = -dirPos.y;
				_fragmentConstantData[k++] = -dirPos.z;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = dirLight._diffuseR;
				_fragmentConstantData[k++] = dirLight._diffuseG;
				_fragmentConstantData[k++] = dirLight._diffuseB;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = dirLight._specularR;
				_fragmentConstantData[k++] = dirLight._specularG;
				_fragmentConstantData[k++] = dirLight._specularB;
				_fragmentConstantData[k++] = 1;
				return;
			}

			if (_numPointLights > 0) {
				pointLight = _lightPicker.castingPointLights[i];
				dirPos = pointLight.scenePosition;

				_ambientLightR += pointLight._ambientR;
				_ambientLightG += pointLight._ambientG;
				_ambientLightB += pointLight._ambientB;

				_fragmentConstantData[k++] = dirPos.x;
				_fragmentConstantData[k++] = dirPos.y;
				_fragmentConstantData[k++] = dirPos.z;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = pointLight._diffuseR;
				_fragmentConstantData[k++] = pointLight._diffuseG;
				_fragmentConstantData[k++] = pointLight._diffuseB;
				_fragmentConstantData[k++] = pointLight._radius;

				_fragmentConstantData[k++] = pointLight._specularR;
				_fragmentConstantData[k++] = pointLight._specularG;
				_fragmentConstantData[k++] = pointLight._specularB;
				_fragmentConstantData[k++] = pointLight._fallOffFactor;
			}
		}

		private function updateProbes(stage3DProxy : Stage3DProxy) : void
		{

		}

		private function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}
	}
}