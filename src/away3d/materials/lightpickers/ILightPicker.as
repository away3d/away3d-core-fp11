package away3d.materials.lightpickers
{
	import away3d.core.base.IRenderable;
	import away3d.core.traverse.EntityCollector;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;

	import flash.events.IEventDispatcher;

	public interface ILightPicker extends IEventDispatcher
	{
		/**
		 * The maximum amount of point lights that will be provided
		 */
		function get numPointLights() : uint;

		/**
		 * The maximum amount of directional lights that will be provided
		 */
		function get numDirectionalLights() : uint;

		/**
		 * Updates set of lights for a given renderable and EntityCollector
		 */
		function collectLights(renderable : IRenderable, entityCollector : EntityCollector) : void;

		function get pointLights() : Vector.<PointLight>;
		function get directionalLights() : Vector.<DirectionalLight>;
		function get allPickedLights() : Vector.<LightBase>;
	}
}
