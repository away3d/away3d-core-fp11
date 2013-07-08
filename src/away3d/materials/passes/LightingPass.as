package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;
	import away3d.materials.LightSources;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.LightingShaderCompiler;
	import away3d.materials.compilation.ShaderCompiler;
	
	import flash.display3D.Context3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * LightingPass is a shader pass that uses shader methods to compile a complete program. It only includes the lighting
	 * methods. It's used by multipass materials to accumulate lighting passes.
	 *
	 * @see away3d.materials.MultiPassMaterialBase
	 */
	
	public class LightingPass extends CompiledPass
	{
		private var _includeCasters:Boolean = true;
		private var _tangentSpace:Boolean;
		private var _lightVertexConstantIndex:int;
		private var _inverseSceneMatrix:Vector.<Number> = new Vector.<Number>();
		
		private var _directionalLightsOffset:uint;
		private var _pointLightsOffset:uint;
		private var _lightProbesOffset:uint;
		private var _maxLights:int = 3;
		
		/**
		 * Creates a new LightingPass objects.
		 *
		 * @param material The material to which this pass belongs.
		 */
		public function LightingPass(material:MaterialBase)
		{
			super(material);
		}

		/**
		 * Indicates the offset in the light picker's directional light vector for which to start including lights.
		 * This needs to be set before the light picker is assigned.
		 */
		public function get directionalLightsOffset():uint
		{
			return _directionalLightsOffset;
		}
		
		public function set directionalLightsOffset(value:uint):void
		{
			_directionalLightsOffset = value;
		}

		/**
		 * Indicates the offset in the light picker's point light vector for which to start including lights.
		 * This needs to be set before the light picker is assigned.
		 */
		public function get pointLightsOffset():uint
		{
			return _pointLightsOffset;
		}
		
		public function set pointLightsOffset(value:uint):void
		{
			_pointLightsOffset = value;
		}

		/**
		 * Indicates the offset in the light picker's light probes vector for which to start including lights.
		 * This needs to be set before the light picker is assigned.
		 */
		public function get lightProbesOffset():uint
		{
			return _lightProbesOffset;
		}
		
		public function set lightProbesOffset(value:uint):void
		{
			_lightProbesOffset = value;
		}

		/**
		 * @inheritDoc
		 */
		override protected function createCompiler(profile:String):ShaderCompiler
		{
			_maxLights = profile == "baselineConstrained"? 1 : 3;
			return new LightingShaderCompiler(profile);
		}

		/**
		 * Indicates whether or not shadow casting lights need to be included.
		 */
		public function get includeCasters():Boolean
		{
			return _includeCasters;
		}
		
		public function set includeCasters(value:Boolean):void
		{
			if (_includeCasters == value)
				return;
			_includeCasters = value;
			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateLights():void
		{
			super.updateLights();
			var numDirectionalLights:int;
			var numPointLights:int;
			var numLightProbes:int;
			
			if (_lightPicker) {
				numDirectionalLights = calculateNumDirectionalLights(_lightPicker.numDirectionalLights);
				numPointLights = calculateNumPointLights(_lightPicker.numPointLights);
				numLightProbes = calculateNumProbes(_lightPicker.numLightProbes);
				
				if (_includeCasters) {
					numPointLights += _lightPicker.numCastingPointLights;
					numDirectionalLights += _lightPicker.numCastingDirectionalLights;
				}
			} else {
				numDirectionalLights = 0;
				numPointLights = 0;
				numLightProbes = 0;
			}
			
			
			if (numPointLights != _numPointLights ||
				numDirectionalLights != _numDirectionalLights ||
				numLightProbes != _numLightProbes) {
				_numPointLights = numPointLights;
				_numDirectionalLights = numDirectionalLights;
				_numLightProbes = numLightProbes;
				invalidateShaderProgram();
			}
		
		}

		/**
		 * Calculates the amount of directional lights this material will support.
		 * @param numDirectionalLights The maximum amount of directional lights to support.
		 * @return The amount of directional lights this material will support, bounded by the amount necessary.
		 */
		private function calculateNumDirectionalLights(numDirectionalLights:uint):int
		{
			return Math.min(numDirectionalLights - _directionalLightsOffset, _maxLights);
		}

		/**
		 * Calculates the amount of point lights this material will support.
		 * @param numDirectionalLights The maximum amount of point lights to support.
		 * @return The amount of point lights this material will support, bounded by the amount necessary.
		 */
		private function calculateNumPointLights(numPointLights:uint):int
		{
			var numFree:int = _maxLights - _numDirectionalLights;
			return Math.min(numPointLights - _pointLightsOffset, numFree);
		}

		/**
		 * Calculates the amount of light probes this material will support.
		 * @param numDirectionalLights The maximum amount of light probes to support.
		 * @return The amount of light probes this material will support, bounded by the amount necessary.
		 */
		private function calculateNumProbes(numLightProbes:uint):int
		{
			var numChannels:int;
			if ((_specularLightSources & LightSources.PROBES) != 0)
				++numChannels;
			if ((_diffuseLightSources & LightSources.PROBES) != 0)
				++numChannels;
			
			// 4 channels available
			return Math.min(numLightProbes - _lightProbesOffset, int(4/numChannels));
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateShaderProperties():void
		{
			super.updateShaderProperties();
			_tangentSpace = LightingShaderCompiler(_compiler).tangentSpace;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateRegisterIndices():void
		{
			super.updateRegisterIndices();
			_lightVertexConstantIndex = LightingShaderCompiler(_compiler).lightVertexConstantIndex;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			renderable.inverseSceneTransform.copyRawDataTo(_inverseSceneMatrix);
			
			if (_tangentSpace && _cameraPositionIndex >= 0) {
				var pos:Vector3D = camera.scenePosition;
				var x:Number = pos.x;
				var y:Number = pos.y;
				var z:Number = pos.z;
				_vertexConstantData[_cameraPositionIndex] = _inverseSceneMatrix[0]*x + _inverseSceneMatrix[4]*y + _inverseSceneMatrix[8]*z + _inverseSceneMatrix[12];
				_vertexConstantData[_cameraPositionIndex + 1] = _inverseSceneMatrix[1]*x + _inverseSceneMatrix[5]*y + _inverseSceneMatrix[9]*z + _inverseSceneMatrix[13];
				_vertexConstantData[_cameraPositionIndex + 2] = _inverseSceneMatrix[2]*x + _inverseSceneMatrix[6]*y + _inverseSceneMatrix[10]*z + _inverseSceneMatrix[14];
			}
			
			super.render(renderable, stage3DProxy, camera, viewProjection);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			super.activate(stage3DProxy, camera);
			
			if (!_tangentSpace && _cameraPositionIndex >= 0) {
				var pos:Vector3D = camera.scenePosition;
				_vertexConstantData[_cameraPositionIndex] = pos.x;
				_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
				_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
			}
		}

		/**
		 * Indicates whether any light probes are used to contribute to the specular shading.
		 */
		private function usesProbesForSpecular():Boolean
		{
			return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
		}

		/**
		 * Indicates whether any light probes are used to contribute to the diffuse shading.
		 */
		private function usesProbesForDiffuse():Boolean
		{
			return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateLightConstants():void
		{
			var dirLight:DirectionalLight;
			var pointLight:PointLight;
			var i:uint, k:uint;
			var len:int;
			var dirPos:Vector3D;
			var total:uint = 0;
			var numLightTypes:uint = _includeCasters? 2 : 1;
			var l:int;
			var offset:int;
			
			l = _lightVertexConstantIndex;
			k = _lightFragmentConstantIndex;
			
			var cast:int = 0;
			var dirLights:Vector.<DirectionalLight> = _lightPicker.directionalLights;
			offset = _directionalLightsOffset;
			len = _lightPicker.directionalLights.length;
			if (offset > len) {
				cast = 1;
				offset -= len;
			}
			
			for (; cast < numLightTypes; ++cast) {
				if (cast)
					dirLights = _lightPicker.castingDirectionalLights;
				len = dirLights.length;
				if (len > _numDirectionalLights)
					len = _numDirectionalLights;
				for (i = 0; i < len; ++i) {
					dirLight = dirLights[offset + i];
					dirPos = dirLight.sceneDirection;
					
					_ambientLightR += dirLight._ambientR;
					_ambientLightG += dirLight._ambientG;
					_ambientLightB += dirLight._ambientB;
					
					if (_tangentSpace) {
						var x:Number = -dirPos.x;
						var y:Number = -dirPos.y;
						var z:Number = -dirPos.z;
						_vertexConstantData[l++] = _inverseSceneMatrix[0]*x + _inverseSceneMatrix[4]*y + _inverseSceneMatrix[8]*z;
						_vertexConstantData[l++] = _inverseSceneMatrix[1]*x + _inverseSceneMatrix[5]*y + _inverseSceneMatrix[9]*z;
						_vertexConstantData[l++] = _inverseSceneMatrix[2]*x + _inverseSceneMatrix[6]*y + _inverseSceneMatrix[10]*z;
						_vertexConstantData[l++] = 1;
					} else {
						_fragmentConstantData[k++] = -dirPos.x;
						_fragmentConstantData[k++] = -dirPos.y;
						_fragmentConstantData[k++] = -dirPos.z;
						_fragmentConstantData[k++] = 1;
					}
					
					_fragmentConstantData[k++] = dirLight._diffuseR;
					_fragmentConstantData[k++] = dirLight._diffuseG;
					_fragmentConstantData[k++] = dirLight._diffuseB;
					_fragmentConstantData[k++] = 1;
					
					_fragmentConstantData[k++] = dirLight._specularR;
					_fragmentConstantData[k++] = dirLight._specularG;
					_fragmentConstantData[k++] = dirLight._specularB;
					_fragmentConstantData[k++] = 1;
					
					if (++total == _numDirectionalLights) {
						// break loop
						i = len;
						cast = numLightTypes;
					}
				}
			}
			
			// more directional supported than currently picked, need to clamp all to 0
			if (_numDirectionalLights > total) {
				i = k + (_numDirectionalLights - total)*12;
				while (k < i)
					_fragmentConstantData[k++] = 0;
			}
			
			total = 0;
			
			var pointLights:Vector.<PointLight> = _lightPicker.pointLights;
			offset = _pointLightsOffset;
			len = _lightPicker.pointLights.length;
			if (offset > len) {
				cast = 1;
				offset -= len;
			} else
				cast = 0;
			for (; cast < numLightTypes; ++cast) {
				if (cast)
					pointLights = _lightPicker.castingPointLights;
				len = pointLights.length;
				for (i = 0; i < len; ++i) {
					pointLight = pointLights[offset + i];
					dirPos = pointLight.scenePosition;
					
					_ambientLightR += pointLight._ambientR;
					_ambientLightG += pointLight._ambientG;
					_ambientLightB += pointLight._ambientB;
					
					if (_tangentSpace) {
						x = dirPos.x;
						y = dirPos.y;
						z = dirPos.z;
						_vertexConstantData[l++] = _inverseSceneMatrix[0]*x + _inverseSceneMatrix[4]*y + _inverseSceneMatrix[8]*z + _inverseSceneMatrix[12];
						_vertexConstantData[l++] = _inverseSceneMatrix[1]*x + _inverseSceneMatrix[5]*y + _inverseSceneMatrix[9]*z + _inverseSceneMatrix[13];
						_vertexConstantData[l++] = _inverseSceneMatrix[2]*x + _inverseSceneMatrix[6]*y + _inverseSceneMatrix[10]*z + _inverseSceneMatrix[14];
					} else {
						_vertexConstantData[l++] = dirPos.x;
						_vertexConstantData[l++] = dirPos.y;
						_vertexConstantData[l++] = dirPos.z;
					}
					_vertexConstantData[l++] = 1;
					
					_fragmentConstantData[k++] = pointLight._diffuseR;
					_fragmentConstantData[k++] = pointLight._diffuseG;
					_fragmentConstantData[k++] = pointLight._diffuseB;
					var radius:Number = pointLight._radius;
					_fragmentConstantData[k++] = radius*radius;
					
					_fragmentConstantData[k++] = pointLight._specularR;
					_fragmentConstantData[k++] = pointLight._specularG;
					_fragmentConstantData[k++] = pointLight._specularB;
					_fragmentConstantData[k++] = pointLight._fallOffFactor;
					
					if (++total == _numPointLights) {
						// break loop
						i = len;
						cast = numLightTypes;
					}
				}
			}
			
			// more directional supported than currently picked, need to clamp all to 0
			if (_numPointLights > total) {
				i = k + (total - _numPointLights)*12;
				for (; k < i; ++k)
					_fragmentConstantData[k] = 0;
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateProbes(stage3DProxy:Stage3DProxy):void
		{
			var context:Context3D = stage3DProxy._context3D;
			var probe:LightProbe;
			var lightProbes:Vector.<LightProbe> = _lightPicker.lightProbes;
			var weights:Vector.<Number> = _lightPicker.lightProbeWeights;
			var len:int = lightProbes.length - _lightProbesOffset;
			var addDiff:Boolean = usesProbesForDiffuse();
			var addSpec:Boolean = Boolean(_methodSetup._specularMethod && usesProbesForSpecular());
			
			if (!(addDiff || addSpec))
				return;
			
			if (len > _numLightProbes)
				len = _numLightProbes;
			
			for (var i:uint = 0; i < len; ++i) {
				probe = lightProbes[_lightProbesOffset + i];
				
				if (addDiff)
					context.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
				if (addSpec)
					context.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
			}
			
			for (i = 0; i < len; ++i)
				_fragmentConstantData[_probeWeightsIndex + i] = weights[_lightProbesOffset + i];
		}
	}
}
