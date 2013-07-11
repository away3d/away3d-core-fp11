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
	import away3d.materials.compilation.ShaderCompiler;
	import away3d.materials.compilation.SuperShaderCompiler;
	import away3d.materials.methods.ColorTransformMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.MethodVOSet;
	
	import flash.display3D.Context3D;
	
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * SuperShaderPass is a shader pass that uses shader methods to compile a complete program. It includes all methods
	 * associated with a material.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */
	public class SuperShaderPass extends CompiledPass
	{
		private var _includeCasters:Boolean = true;
		private var _ignoreLights:Boolean;
		
		/**
		 * Creates a new SuperShaderPass objects.
		 *
		 * @param material The material to which this material belongs.
		 */
		public function SuperShaderPass(material:MaterialBase)
		{
			super(material);
			_needFragmentAnimation = true;
		}

		/**
		 * @inheritDoc
		 */
		override protected function createCompiler(profile:String):ShaderCompiler
		{
			return new SuperShaderCompiler(profile);
		}

		/**
		 * Indicates whether lights that cast shadows should be included in the pass.
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
		 * The ColorTransform object to transform the colour of the material with. Defaults to null.
		 */
		public function get colorTransform():ColorTransform
		{
			return _methodSetup.colorTransformMethod? _methodSetup._colorTransformMethod.colorTransform : null;
		}
		
		public function set colorTransform(value:ColorTransform):void
		{
			if (value) {
				colorTransformMethod ||= new ColorTransformMethod();
				_methodSetup._colorTransformMethod.colorTransform = value;
			} else if (!value) {
				if (_methodSetup._colorTransformMethod)
					colorTransformMethod = null;
				colorTransformMethod = _methodSetup._colorTransformMethod = null;
			}
		}

		/**
		 * The ColorTransformMethod object to transform the colour of the material with. Defaults to null.
		 */
		public function get colorTransformMethod():ColorTransformMethod
		{
			return _methodSetup.colorTransformMethod;
		}
		
		public function set colorTransformMethod(value:ColorTransformMethod):void
		{
			_methodSetup.colorTransformMethod = value;
		}

		/**
		 * Appends an "effect" shading method to the shader. Effect methods are those that do not influence the lighting
		 * but modulate the shaded colour, used for fog, outlines, etc. The method will be applied to the result of the
		 * methods added prior.
		 */
		public function addMethod(method:EffectMethodBase):void
		{
			_methodSetup.addMethod(method);
		}

		/**
		 * The number of "effect" methods added to the material.
		 */
		public function get numMethods():int
		{
			return _methodSetup.numMethods;
		}

		/**
		 * Queries whether a given effect method was added to the material.
		 *
		 * @param method The method to be queried.
		 * @return true if the method was added to the material, false otherwise.
		 */
		public function hasMethod(method:EffectMethodBase):Boolean
		{
			return _methodSetup.hasMethod(method);
		}

		/**
		 * Returns the method added at the given index.
		 * @param index The index of the method to retrieve.
		 * @return The method at the given index.
		 */
		public function getMethodAt(index:int):EffectMethodBase
		{
			return _methodSetup.getMethodAt(index);
		}

		/**
		 * Adds an effect method at the specified index amongst the methods already added to the material. Effect
		 * methods are those that do not influence the lighting but modulate the shaded colour, used for fog, outlines,
		 * etc. The method will be applied to the result of the methods with a lower index.
		 */
		public function addMethodAt(method:EffectMethodBase, index:int):void
		{
			_methodSetup.addMethodAt(method, index);
		}

		/**
		 * Removes an effect method from the material.
		 * @param method The method to be removed.
		 */
		public function removeMethod(method:EffectMethodBase):void
		{
			_methodSetup.removeMethod(method);
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateLights():void
		{
			//			super.updateLights();
			if (_lightPicker && !_ignoreLights) {
				_numPointLights = _lightPicker.numPointLights;
				_numDirectionalLights = _lightPicker.numDirectionalLights;
				_numLightProbes = _lightPicker.numLightProbes;
				
				if (_includeCasters) {
					_numPointLights += _lightPicker.numCastingPointLights;
					_numDirectionalLights += _lightPicker.numCastingDirectionalLights;
				}
			} else {
				_numPointLights = 0;
				_numDirectionalLights = 0;
				_numLightProbes = 0;
			}
			
			invalidateShaderProgram();
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			super.activate(stage3DProxy, camera);
			
			if (_methodSetup._colorTransformMethod)
				_methodSetup._colorTransformMethod.activate(_methodSetup._colorTransformMethodVO, stage3DProxy);
			
			var methods:Vector.<MethodVOSet> = _methodSetup._methods;
			var len:uint = methods.length;
			for (var i:int = 0; i < len; ++i) {
				var set:MethodVOSet = methods[i];
				set.method.activate(set.data, stage3DProxy);
			}
			
			if (_cameraPositionIndex >= 0) {
				var pos:Vector3D = camera.scenePosition;
				_vertexConstantData[_cameraPositionIndex] = pos.x;
				_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
				_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(stage3DProxy:Stage3DProxy):void
		{
			super.deactivate(stage3DProxy);
			
			if (_methodSetup._colorTransformMethod)
				_methodSetup._colorTransformMethod.deactivate(_methodSetup._colorTransformMethodVO, stage3DProxy);
			
			var set:MethodVOSet;
			var methods:Vector.<MethodVOSet> = _methodSetup._methods;
			var len:uint = methods.length;
			for (var i:uint = 0; i < len; ++i) {
				set = methods[i];
				set.method.deactivate(set.data, stage3DProxy);
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function addPassesFromMethods():void
		{
			super.addPassesFromMethods();
			
			if (_methodSetup._colorTransformMethod)
				addPasses(_methodSetup._colorTransformMethod.passes);
			
			var methods:Vector.<MethodVOSet> = _methodSetup._methods;
			for (var i:uint = 0; i < methods.length; ++i)
				addPasses(methods[i].method.passes);
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
		override protected function updateMethodConstants():void
		{
			super.updateMethodConstants();
			if (_methodSetup._colorTransformMethod)
				_methodSetup._colorTransformMethod.initConstants(_methodSetup._colorTransformMethodVO);
			
			var methods:Vector.<MethodVOSet> = _methodSetup._methods;
			var len:uint = methods.length;
			for (var i:uint = 0; i < len; ++i)
				methods[i].method.initConstants(methods[i].data);
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateLightConstants():void
		{
			// first dirs, then points
			var dirLight:DirectionalLight;
			var pointLight:PointLight;
			var i:uint, k:uint;
			var len:int;
			var dirPos:Vector3D;
			var total:uint = 0;
			var numLightTypes:uint = _includeCasters? 2 : 1;
			
			k = _lightFragmentConstantIndex;
			
			for (var cast:int = 0; cast < numLightTypes; ++cast) {
				var dirLights:Vector.<DirectionalLight> = cast? _lightPicker.castingDirectionalLights : _lightPicker.directionalLights;
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
				i = k + (_numDirectionalLights - total)*12;
				while (k < i)
					_fragmentConstantData[k++] = 0;
			}
			
			total = 0;
			for (cast = 0; cast < numLightTypes; ++cast) {
				var pointLights:Vector.<PointLight> = cast? _lightPicker.castingPointLights : _lightPicker.pointLights;
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
					_fragmentConstantData[k++] = pointLight._radius*pointLight._radius;
					
					_fragmentConstantData[k++] = pointLight._specularR;
					_fragmentConstantData[k++] = pointLight._specularG;
					_fragmentConstantData[k++] = pointLight._specularB;
					_fragmentConstantData[k++] = pointLight._fallOffFactor;
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
			var probe:LightProbe;
			var lightProbes:Vector.<LightProbe> = _lightPicker.lightProbes;
			var weights:Vector.<Number> = _lightPicker.lightProbeWeights;
			var len:int = lightProbes.length;
			var addDiff:Boolean = usesProbesForDiffuse();
			var addSpec:Boolean = Boolean(_methodSetup._specularMethod && usesProbesForSpecular());
			var context:Context3D = stage3DProxy._context3D;
			
			if (!(addDiff || addSpec))
				return;
			
			for (var i:uint = 0; i < len; ++i) {
				probe = lightProbes[i];
				
				if (addDiff)
					context.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
				if (addSpec)
					context.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
			}
			
			_fragmentConstantData[_probeWeightsIndex] = weights[0];
			_fragmentConstantData[_probeWeightsIndex + 1] = weights[1];
			_fragmentConstantData[_probeWeightsIndex + 2] = weights[2];
			_fragmentConstantData[_probeWeightsIndex + 3] = weights[3];
		}

		/**
		 * Indicates whether lights should be ignored in this pass. This is used when only effect methods are rendered in
		 * a multipass material.
		 */
		arcane function set ignoreLights(ignoreLights:Boolean):void
		{
			_ignoreLights = ignoreLights;
		}
		
		arcane function get ignoreLights():Boolean
		{
			return _ignoreLights;
		}
	}
}
