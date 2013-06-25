package away3d.materials.lightpickers
{
	import away3d.*;
	import away3d.core.base.*;
	import away3d.core.traverse.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	
	import flash.geom.*;
	
	use namespace arcane;

	/**
	 * LightPickerBase provides an abstract base clase for light picker classes. These classes are responsible for
	 * feeding materials with relevant lights. Usually, StaticLightPicker can be used, but LightPickerBase can be
	 * extended to provide more application-specific dynamic selection of lights.
	 *
	 * @see StaticLightPicker
	 */
	public class LightPickerBase extends NamedAssetBase implements IAsset
	{
		protected var _numPointLights:uint;
		protected var _numDirectionalLights:uint;
		protected var _numCastingPointLights:uint;
		protected var _numCastingDirectionalLights:uint;
		protected var _numLightProbes:uint;
		protected var _allPickedLights:Vector.<LightBase>;
		protected var _pointLights:Vector.<PointLight>;
		protected var _castingPointLights:Vector.<PointLight>;
		protected var _directionalLights:Vector.<DirectionalLight>;
		protected var _castingDirectionalLights:Vector.<DirectionalLight>;
		protected var _lightProbes:Vector.<LightProbe>;
		protected var _lightProbeWeights:Vector.<Number>;

		/**
		 * Creates a new LightPickerBase object.
		 */
		public function LightPickerBase()
		{
		
		}

		/**
		 * Disposes resources used by the light picker.
		 */
		public function dispose():void
		{
		}

		/**
		 * @inheritDoc
		 */
		public function get assetType():String
		{
			return AssetType.LIGHT_PICKER;
		}
		
		/**
		 * The maximum amount of directional lights that will be provided.
		 */
		public function get numDirectionalLights():uint
		{
			return _numDirectionalLights;
		}
		
		/**
		 * The maximum amount of point lights that will be provided.
		 */
		public function get numPointLights():uint
		{
			return _numPointLights;
		}
		
		/**
		 * The maximum amount of directional lights that cast shadows.
		 */
		public function get numCastingDirectionalLights():uint
		{
			return _numCastingDirectionalLights;
		}
		
		/**
		 * The amount of point lights that cast shadows.
		 */
		public function get numCastingPointLights():uint
		{
			return _numCastingPointLights;
		}
		
		/**
		 * The maximum amount of light probes that will be provided.
		 */
		public function get numLightProbes():uint
		{
			return _numLightProbes;
		}

		/**
		 * The collected point lights to be used for shading.
		 */
		public function get pointLights():Vector.<PointLight>
		{
			return _pointLights;
		}

		/**
		 * The collected directional lights to be used for shading.
		 */
		public function get directionalLights():Vector.<DirectionalLight>
		{
			return _directionalLights;
		}

		/**
		 * The collected point lights that cast shadows to be used for shading.
		 */
		public function get castingPointLights():Vector.<PointLight>
		{
			return _castingPointLights;
		}

		/**
		 * The collected directional lights that cast shadows to be used for shading.
		 */
		public function get castingDirectionalLights():Vector.<DirectionalLight>
		{
			return _castingDirectionalLights;
		}

		/**
		 * The collected light probes to be used for shading.
		 */
		public function get lightProbes():Vector.<LightProbe>
		{
			return _lightProbes;
		}

		/**
		 * The weights for each light probe, defining their influence on the object.
		 */
		public function get lightProbeWeights():Vector.<Number>
		{
			return _lightProbeWeights;
		}

		/**
		 * A collection of all the collected lights.
		 */
		public function get allPickedLights():Vector.<LightBase>
		{
			return _allPickedLights;
		}
		
		/**
		 * Updates set of lights for a given renderable and EntityCollector. Always call super.collectLights() after custom overridden code.
		 */
		public function collectLights(renderable:IRenderable, entityCollector:EntityCollector):void
		{
			updateProbeWeights(renderable);
		}

		/**
		 * Updates the weights for the light probes, based on the renderable's position relative to them.
		 * @param renderable The renderble for which to calculate the light probes' influence.
		 */
		private function updateProbeWeights(renderable:IRenderable):void
		{
			// todo: this will cause the same calculations to occur per SubMesh. See if this can be improved.
			var objectPos:Vector3D = renderable.sourceEntity.scenePosition;
			var lightPos:Vector3D;
			var rx:Number = objectPos.x, ry:Number = objectPos.y, rz:Number = objectPos.z;
			var dx:Number, dy:Number, dz:Number;
			var w:Number, total:Number = 0;
			var i:int;
			
			// calculates weights for probes
			for (i = 0; i < _numLightProbes; ++i) {
				lightPos = _lightProbes[i].scenePosition;
				dx = rx - lightPos.x;
				dy = ry - lightPos.y;
				dz = rz - lightPos.z;
				// weight is inversely proportional to square of distance
				w = dx*dx + dy*dy + dz*dz;
				
				// just... huge if at the same spot
				w = w > .00001? 1/w : 50000000;
				_lightProbeWeights[i] = w;
				total += w;
			}
			
			// normalize
			total = 1/total;
			for (i = 0; i < _numLightProbes; ++i)
				_lightProbeWeights[i] *= total;
		}
	
	}
}
