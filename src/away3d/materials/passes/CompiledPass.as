package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.materials.compilation.SuperShaderCompiler;
	import away3d.materials.methods.ShaderMethodSetup;

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

		public function CompiledPass()
		{
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

	}
}
