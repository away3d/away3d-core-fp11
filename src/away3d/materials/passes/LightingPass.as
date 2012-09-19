package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;
	import away3d.materials.LightSources;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.LightingShaderCompiler;
	import away3d.materials.compilation.ShaderCompiler;
	import away3d.materials.compilation.SuperShaderCompiler;
	import away3d.materials.methods.ColorTransformMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.MethodVOSet;

	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */

	public class LightingPass extends CompiledPass
	{
		private var _includeCasters : Boolean = true;

		/**
		 * Creates a new DefaultScreenPass objects.
		 */
		public function LightingPass(material : MaterialBase)
		{
			super(material);
		}

		override protected function createCompiler() : ShaderCompiler
		{
			return new LightingShaderCompiler();
		}

		public function get includeCasters() : Boolean
		{
			return _includeCasters;
		}

		public function set includeCasters(value : Boolean) : void
		{
			if (_includeCasters == value) return;
			_includeCasters = value;
			invalidateShaderProgram();
		}

		override protected function updateLights() : void
		{
			super.updateLights();
			_numPointLights = _lightPicker.numPointLights;
			_numDirectionalLights = _lightPicker.numDirectionalLights;
			_numLightProbes = _lightPicker.numLightProbes;

			if (_includeCasters) {
				_numPointLights += _lightPicker.numCastingPointLights;
				_numDirectionalLights += _lightPicker.numCastingDirectionalLights;
			}

			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			if (_cameraPositionIndex >= 0) {
				var pos : Vector3D = camera.scenePosition;
				_vertexConstantData[_cameraPositionIndex] = pos.x;
				_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
				_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
			}
		}

		private function usesProbesForSpecular() : Boolean
		{
			return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
		}

		private function usesProbesForDiffuse() : Boolean
		{
			return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
		}

		override protected function updateMethodConstants() : void
		{
			super.updateMethodConstants();
			if (_methodSetup._colorTransformMethod) _methodSetup._colorTransformMethod.initConstants(_methodSetup._colorTransformMethodVO);

			var methods : Vector.<MethodVOSet> = _methodSetup._methods;
			var len : uint = methods.length;
			for (var i : uint = 0; i < len; ++i) {
				methods[i].method.initConstants(methods[i].data);
			}
		}

		/**
		 * Updates the lights data for the render state.
		 * @param lights The lights selected to shade the current object.
		 * @param numLights The amount of lights available.
		 * @param maxLights The maximum amount of lights supported.
		 */
		override protected function updateLightConstants() : void
		{
			// first dirs, then points
			var dirLight : DirectionalLight;
			var pointLight : PointLight;
			var i : uint, k : uint;
			var len : int;
			var dirPos : Vector3D;
			var total : uint = 0;
			var numLightTypes : uint = _includeCasters ? 2 : 1;

			k = _lightFragmentConstantIndex;

			for (var cast : int = 0; cast < numLightTypes; ++cast) {
				var dirLights : Vector.<DirectionalLight> = cast ? _lightPicker.castingDirectionalLights : _lightPicker.directionalLights;
				len = dirLights.length;
				total += len;

				for (i = 0; i < len; ++i) {
					dirLight = dirLights[i];
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
				}
			}

			// more directional supported than currently picked, need to clamp all to 0
			if (_numDirectionalLights > total) {
				i = k + (_numDirectionalLights - total) * 12;
				while (k < i)
					_fragmentConstantData[k++] = 0;
			}

			total = 0;
			for (var cast : int = 0; cast < numLightTypes; ++cast) {
				var pointLights : Vector.<PointLight> = cast ? _lightPicker.castingPointLights : _lightPicker.pointLights;
				len = pointLights.length;
				for (i = 0; i < len; ++i) {
					pointLight = pointLights[i];
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

			// more directional supported than currently picked, need to clamp all to 0
			if (_numPointLights > total) {
				i = k + (total - _numPointLights) * 12;
				for (; k < i; ++k)
					_fragmentConstantData[k] = 0;
			}
		}

		override protected function updateProbes(stage3DProxy : Stage3DProxy) : void
		{
			var probe : LightProbe;
			var lightProbes : Vector.<LightProbe> = _lightPicker.lightProbes;
			var weights : Vector.<Number> = _lightPicker.lightProbeWeights;
			var len : int = lightProbes.length;
			var addDiff : Boolean = usesProbesForDiffuse();
			var addSpec : Boolean = _methodSetup._specularMethod && usesProbesForSpecular();

			if (!(addDiff || addSpec)) return;

			for (var i : uint = 0; i < len; ++i) {
				probe = lightProbes[i];

				if (addDiff)
					stage3DProxy.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
				if (addSpec)
					stage3DProxy.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
			}

			_fragmentConstantData[_probeWeightsIndex] = weights[0];
			_fragmentConstantData[_probeWeightsIndex + 1] = weights[1];
			_fragmentConstantData[_probeWeightsIndex + 2] = weights[2];
			_fragmentConstantData[_probeWeightsIndex + 3] = weights[3];
		}
	}
}