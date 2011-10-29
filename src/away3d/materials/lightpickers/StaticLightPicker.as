package away3d.materials.lightpickers
{
	import away3d.core.base.IRenderable;
	import away3d.core.traverse.EntityCollector;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.lights.PointLight;

	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class StaticLightPicker extends EventDispatcher implements ILightPicker
	{
		private var _lights : Array;
		private var _allPickedLights : Vector.<LightBase>;
		private var _pointLights : Vector.<PointLight>;
		private var _directionalLights : Vector.<DirectionalLight>;
		private var _numPointLights : uint;
		private var _numDirectionalLights : uint;

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
			var light : LightBase;

			_lights = value;
			_allPickedLights = Vector.<LightBase>(value);
			_pointLights = new Vector.<PointLight>();
			_directionalLights = new Vector.<DirectionalLight>();

			var len : uint = value.length;
			for (var i : uint = 0; i < len; ++i) {
				light = value[i];
				if (light is PointLight)
					_pointLights[numPointLights++] = PointLight(light);
				else if (light is DirectionalLight)
					_directionalLights[numDirectionalLights++] = DirectionalLight(light);
			}

			if (_numDirectionalLights == numDirectionalLights && _numPointLights == numPointLights)
				return;

			_numDirectionalLights = numDirectionalLights;
			_numPointLights = numPointLights;

			// notify material lights have changed
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function get numPointLights() : uint
		{
			return _numPointLights;
		}

		public function get numDirectionalLights() : uint
		{
			return _numDirectionalLights;
		}

		public function collectLights(renderable : IRenderable, entityCollector : EntityCollector) : void
		{

		}

		public function get pointLights() : Vector.<PointLight>
		{
			return _pointLights;
		}

		public function get directionalLights() : Vector.<DirectionalLight>
		{
			return _directionalLights;
		}

		public function get allPickedLights() : Vector.<LightBase>
		{
			return _allPickedLights;
		}
	}
}
