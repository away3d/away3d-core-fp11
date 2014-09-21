package away3d.materials.lightpickers
{
	import flash.events.Event;

	import away3d.events.LightEvent;
	import away3d.entities.DirectionalLight;
	import away3d.core.base.LightBase;
	import away3d.entities.LightProbe;
	import away3d.entities.PointLight;

	import flash.geom.Point;

	/**
	 * StaticLightPicker is a light picker that provides a static set of lights. The lights can be reassigned, but
	 * if the configuration changes (number of directional lights, point lights, etc), a material recompilation may
	 * occur.
	 */
	public class StaticLightPicker extends LightPickerBase
	{
		private var _lights:Array;

		/**
		 * Creates a new StaticLightPicker object.
		 * @param lights The lights to be used for shading.
		 */
		public function StaticLightPicker(lights:Array)
		{
			this.lights = lights;
		}

		/**
		 * The lights used for shading.
		 */
		public function get lights():Array
		{
			return _lights;
		}

		public function set lights(value:Array):void
		{
			var numPointLights:uint = 0;
			var numDirectionalLights:uint = 0;
			var numCastingPointLights:uint = 0;
			var numCastingDirectionalLights:uint = 0;
			var numLightProbes:uint = 0;
			var numDeferredDirectionalLights:uint = 0;
			var numDeferredPointLights:uint = 0;
			var light:LightBase;

			if (_lights)
				clearListeners();

			_lights = value;
			_allPickedLights = Vector.<LightBase>(value);
			_pointLights = new Vector.<PointLight>();
			_castingPointLights = new Vector.<PointLight>();
			_directionalLights = new Vector.<DirectionalLight>();
			_castingDirectionalLights = new Vector.<DirectionalLight>();
			_deferredDirectionalLights = new Vector.<DirectionalLight>();
			_deferredPointLights = new Vector.<PointLight>();
			_lightProbes = new Vector.<LightProbe>();

			var len:uint = value.length;
			for (var i:uint = 0; i < len; ++i) {
				light = value[i];
				light.addEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
				light.addEventListener(LightEvent.DEFERRED_CHANGE, onDeferredChange);
				if (light is PointLight) {
					if (light.castsShadows) {
						_castingPointLights[numCastingPointLights++] = PointLight(light);
					} else if(light.deferred) {
						_deferredPointLights[numDeferredPointLights++] = PointLight(light);
					}else{
						_pointLights[numPointLights++] = PointLight(light);
					}
				} else if (light is DirectionalLight) {
					if (light.castsShadows) {
						_castingDirectionalLights[numCastingDirectionalLights++] = DirectionalLight(light);
					} else if(light.deferred) {
						_deferredDirectionalLights[numDeferredDirectionalLights++] = DirectionalLight(light);
					} else {
						_directionalLights[numDirectionalLights++] = DirectionalLight(light);
					}
				} else if (light is LightProbe)
					_lightProbes[numLightProbes++] = LightProbe(light);
			}

			if (_numDirectionalLights == numDirectionalLights && _numPointLights == numPointLights && _numLightProbes == numLightProbes &&
				_numCastingPointLights == numCastingPointLights && _numCastingDirectionalLights == numCastingDirectionalLights &&
					_numDeferredDirectionalLights == numDeferredDirectionalLights && _numDeferredPointLights == numDeferredPointLights) {
				return;
			}

			_numDirectionalLights = numDirectionalLights;
			_numCastingDirectionalLights = numCastingDirectionalLights;
			_numPointLights = numPointLights;
			_numCastingPointLights = numCastingPointLights;
			_numLightProbes = numLightProbes;
			_numDeferredDirectionalLights = numDeferredDirectionalLights;
			_numDeferredPointLights = numDeferredPointLights;

			// MUST HAVE MULTIPLE OF 4 ELEMENTS!
			_lightProbeWeights = new Vector.<Number>(Math.ceil(numLightProbes/4)*4, true);

			// notify material lights have changed
			dispatchEvent(new Event(Event.CHANGE));
		}

		/**
		 * Remove configuration change listeners on the lights.
		 */
		private function clearListeners():void
		{
			var len:uint = _lights.length;
			for (var i:int = 0; i < len; ++i) {
				var light:LightBase = _lights[i];
				light.removeEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
				light.removeEventListener(LightEvent.DEFERRED_CHANGE, onDeferredChange);
			}
		}

		private function onDeferredChange(event:LightEvent):void {
			var light:LightBase = LightBase(event.target);
			if(!light.castsShadows && light.deferred) {
				enableDeferredLight(light)
			}else{
				disableDeferredLight(light);
			}
			dispatchEvent(new Event(Event.CHANGE));
		}

		/**
		 * Notifies the material of a configuration change.
		 */
		private function onCastShadowChange(event:LightEvent):void
		{
			// TODO: Assign to special caster collections, just append it to the lights in SinglePass
			// But keep seperated in multipass

			var light:LightBase = LightBase(event.target);

			if (light is PointLight)
				updatePointCasting(light as PointLight);
			else if (light is DirectionalLight)
				updateDirectionalCasting(light as DirectionalLight);

			dispatchEvent(new Event(Event.CHANGE));
		}

		/**
		 * Called when a directional light's shadow casting configuration changes.
		 */
		private function updateDirectionalCasting(light:DirectionalLight):void
		{
			if (light.castsShadows) {
				if(light.deferred) {
					--_numDeferredDirectionalLights;
					_deferredDirectionalLights.splice(_deferredDirectionalLights.indexOf(light as DirectionalLight), 1);
				}else{
					--_numDirectionalLights;
					_directionalLights.splice(_directionalLights.indexOf(light as DirectionalLight), 1);
				}
				++_numCastingDirectionalLights;
				_castingDirectionalLights.push(light);
			} else {
				if(light.deferred) {
					++_numDeferredDirectionalLights;
					_deferredDirectionalLights.push(light);
				}else{
					++_numDirectionalLights;
					_directionalLights.push(light);
				}
				--_numCastingDirectionalLights;
				_castingDirectionalLights.splice(_castingDirectionalLights.indexOf(light as DirectionalLight), 1);
			}
		}

		/**
		 * Called when a point light's shadow casting configuration changes.
		 */
		private function updatePointCasting(light:PointLight):void
		{
			if (light.castsShadows) {
				if(light.deferred) {
					--_numDeferredPointLights;
					_deferredPointLights.splice(_deferredPointLights.indexOf(light as PointLight), 1);
				}else{
					--_numPointLights;
					_pointLights.splice(_pointLights.indexOf(light as PointLight), 1);
				}

				++_numCastingPointLights;
				_castingPointLights.push(light);
			} else {
				if(light.deferred) {
					++_numDeferredPointLights;
					_deferredPointLights.push(light);
				}else{
					++_numPointLights;
					_pointLights.push(light);
				}
				--_numCastingPointLights;
				_castingPointLights.splice(_castingPointLights.indexOf(light as PointLight), 1);
			}
		}

		private function disableDeferredLight(light:LightBase):void
		{
			var index:int;
			var pointLight:PointLight = light as PointLight;
			var directionalLight:DirectionalLight = light as DirectionalLight;

			if (pointLight) {
				index = _deferredPointLights.indexOf(pointLight);
				if(index>-1) {
					_numDeferredPointLights--;
					_deferredPointLights.splice(index,1);
				}

				if (pointLight.castsShadows && _castingPointLights.indexOf(pointLight) == -1) {
					_castingPointLights[_numCastingPointLights++] = pointLight;
				} else if (!pointLight.castsShadows && _pointLights.indexOf(pointLight) == -1) {
					_pointLights[_numPointLights++] = pointLight;
				}

			}else if(directionalLight) {
				index = _deferredDirectionalLights.indexOf(directionalLight);
				if(index>-1) {
					_numDeferredDirectionalLights--;
					_deferredDirectionalLights.splice(index,1);
				}

				if (directionalLight.castsShadows && _castingDirectionalLights.indexOf(directionalLight) == -1) {
					_castingDirectionalLights[_numCastingDirectionalLights++] = directionalLight;
				} else if (!directionalLight.castsShadows && _directionalLights.indexOf(directionalLight) == -1) {
					_directionalLights[_numDirectionalLights++] = directionalLight;
				}
			}
		}

		private function enableDeferredLight(light:LightBase):void
		{
			var index:int;
			var pointLight:PointLight = light as PointLight;
			var directionalLight:DirectionalLight = light as DirectionalLight;

			if(pointLight) {
				index = _pointLights.indexOf(pointLight);
				if(index>-1) {
					_numPointLights--;
					_pointLights.splice(index,1);
				}

				if(_deferredPointLights.indexOf(pointLight) == -1) {
					_deferredPointLights[_numDeferredPointLights++] = pointLight;
				}
			}else if(directionalLight) {
				index = _directionalLights.indexOf(directionalLight);
				if(index>-1) {
					_numDirectionalLights--;
					_directionalLights.splice(index,1);
				}

				if(_deferredDirectionalLights.indexOf(directionalLight) == -1) {
					_deferredDirectionalLights[_numDeferredDirectionalLights++] = directionalLight;
				}
			}
		}
	}
}
