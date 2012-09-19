package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.SuperShaderCompiler;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicNormalMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.ShaderMethodSetup;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.textures.Texture2DBase;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class CompiledPass extends MaterialPassBase
	{
		arcane var _passes : Vector.<MaterialPassBase>;
		arcane var _passesDirty : Boolean;

		protected var _vertexCode : String;
		protected var _fragmentCode : String;

		protected var _vertexConstantData : Vector.<Number> = new Vector.<Number>();
		protected var _fragmentConstantData : Vector.<Number> = new Vector.<Number>();
		protected var _commonsDataIndex : int;
		protected var _vertexConstantsOffset : uint;
		protected var _probeWeightsIndex : int;
		protected var _uvBufferIndex : int;
		protected var _secondaryUVBufferIndex : int;
		protected var _normalBufferIndex : int;
		protected var _tangentBufferIndex : int;
		protected var _sceneMatrixIndex : int;
		protected var _sceneNormalMatrixIndex : int;
		protected var _lightDataIndex : int;
		protected var _cameraPositionIndex : int;
		protected var _uvTransformIndex : int;
		protected var _lightProbeDiffuseIndices : Vector.<uint>;
		protected var _lightProbeSpecularIndices : Vector.<uint>;

		protected var _ambientLightR : Number;
		protected var _ambientLightG : Number;
		protected var _ambientLightB : Number;

		protected var _compiler : SuperShaderCompiler;

		protected var _methodSetup : ShaderMethodSetup;

		protected var _usingSpecularMethod : Boolean;
		protected var _usesNormals : Boolean;
		protected var _preserveAlpha : Boolean = true;
		protected var _animateUVs : Boolean;

		protected var _numPointLights : uint;
		protected var _numDirectionalLights : uint;
		protected var _numLightProbes : uint;

		public function CompiledPass(material : MaterialBase)
		{
			_material = material;

			init();
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
			super.invalidateShaderProgram(updateMaterial);
			addPassesFromMethods();
		}

		protected function addPassesFromMethods() : void
		{
			_passesDirty = true;
			_passes = new Vector.<MaterialPassBase>();
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

// RENDER LOOP

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
	}
}
