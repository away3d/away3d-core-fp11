package away3d.materials.lightpickers
{
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;

	import flash.events.Event;

	public class StaticLightPicker extends LightPickerBase
	{
		private var _lights : Array;

		public function StaticLightPicker(lights : Array)
		{
			this.lights = lights;
		}

		public function get lights() : Array
		{
			return _lights;
		}

		public function set lights(value : Array) : void
		{
			var numPointLights : uint;
			var numDirectionalLights : uint;
			var numLightProbes : uint;
			var light : LightBase;

			_lights = value;
			_allPickedLights = Vector.<LightBase>(value);
			_pointLights = new Vector.<PointLight>();
			_directionalLights = new Vector.<DirectionalLight>();
			_lightProbes = new Vector.<LightProbe>();

			var len : uint = value.length;
			for (var i : uint = 0; i < len; ++i) {
				light = value[i];
				if (light is PointLight)
					_pointLights[numPointLights++] = PointLight(light);
				else if (light is DirectionalLight)
					_directionalLights[numDirectionalLights++] = DirectionalLight(light);
				else if (light is LightProbe)
					_lightProbes[numLightProbes++] = LightProbe(light);
			}

			if (_numDirectionalLights == numDirectionalLights && _numPointLights == numPointLights && _numLightProbes == numLightProbes)
				return;

			_numDirectionalLights = numDirectionalLights;
			_numPointLights = numPointLights;
			_numLightProbes = numLightProbes;

			// MUST HAVE MULTIPLE OF 4 ELEMENTS!
			_lightProbeWeights = new Vector.<Number>(Math.ceil(numLightProbes/4)*4, true);

			// notify material lights have changed
			dispatchEvent(new Event(Event.CHANGE));
		}
	}
}
