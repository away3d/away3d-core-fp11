package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.IEntity;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;

    import flash.geom.Point;

    use namespace arcane;
	
	/**
	 * The EntityCollector class is a traverser for scene partitions that collects all scene graph entities that are
	 * considered potientially visible.
	 *
	 * @see away3d.partition.Partition3D
	 * @see away3d.partition.Entity
	 */
	public class EntityCollector extends CollectorBase
	{
		protected var _skybox:RenderableBase;
		protected var _deferredDirectionalLights:Vector.<DirectionalLight>;
        protected var _deferredPointLights:Vector.<PointLight>;
		private var _directionalLights:Vector.<DirectionalLight>;
		private var _pointLights:Vector.<PointLight>;
		private var _lightProbes:Vector.<LightProbe>;

		private var _numDeferredDirectionalLights:Number = 0;
		private var _numDeferredPointLights:Number = 0;
        //if one of the light has colored specular, there will be created additional buffer for deffered lighting
        private var _coloredSpecularDeferredLights:Boolean = false;
        private var _hasSpecularDeferredLights:Boolean = false;
        private var _hasDiffuseDeferredLights:Boolean = false;
		private var _numDirectionalLights:Number = 0;
		private var _numPointLights:Number = 0;
		private var _numLightProbes:Number = 0;

		/**
		 *
		 */
		public function get directionalLights():Vector.<DirectionalLight>
		{
			return _directionalLights;
		}

		/**
		 *
		 */
		public function get lightProbes():Vector.<LightProbe>
		{
			return _lightProbes;
		}

		/**
		 *
		 */
		public function get deferredDirectionalLights():Vector.<DirectionalLight>
		{
			return _deferredDirectionalLights;
		}

		/**
		 *
		 */
		public function get pointLights():Vector.<PointLight>
		{
			return _pointLights;
		}

		/**
		 *
		 */
		public function get skyBox():RenderableBase
		{
			return _skybox;
		}

		public function EntityCollector()
		{
			super();

			_deferredDirectionalLights = new Vector.<DirectionalLight>();
			_deferredPointLights = new Vector.<PointLight>();
			_directionalLights = new Vector.<DirectionalLight>();
			_pointLights = new Vector.<PointLight>();
			_lightProbes = new Vector.<LightProbe>();
		}

		/**
		 *
		 * @param entity
		 */
		override public function applyDirectionalLight(entity:IEntity):void
		{
            var directionalLight:DirectionalLight = entity as DirectionalLight;
			_directionalLights[ _numDirectionalLights++ ] = directionalLight;
			if(directionalLight.deferred) {
				_deferredDirectionalLights[ _numDeferredDirectionalLights++ ] = directionalLight;
                updateDeferredData(directionalLight);
			}
		}

		/**
		 *
		 * @param entity
		 */
		override public function applyLightProbe(entity:IEntity):void
		{
			_lightProbes[ _numLightProbes++ ] = entity as LightProbe;
		}

		/**
		 *
		 * @param entity
		 */
		override public function applyPointLight(entity:IEntity):void
		{
            var pointLight:PointLight = entity as PointLight;
			_pointLights[ _numPointLights++ ] = pointLight;
			if(pointLight.deferred) {
				_deferredPointLights[ _numDeferredPointLights++ ] = pointLight;
                updateDeferredData(pointLight);
			}
		}

        private function updateDeferredData(light:LightBase):void {
            if(light.isColoredSpecular()) {
                _coloredSpecularDeferredLights = true;
            }
            if(light.hasSpecularEmission()) {
                _hasSpecularDeferredLights = true;
            }

            if(light.hasDiffuseEmission()) {
                _hasDiffuseDeferredLights = true;
            }
        }

        /**
		 *
		 */
		override public function clear():void
		{
			super.clear();
			_skybox = null;

            _coloredSpecularDeferredLights = false;
			_numDeferredDirectionalLights = 0;
			_numDeferredPointLights = 0;
			_deferredDirectionalLights.length = 0;
            _deferredPointLights.length = 0;

			if (_numDirectionalLights > 0)
				_directionalLights.length = _numDirectionalLights = 0;

			if (_numPointLights > 0)
				_pointLights.length = _numPointLights = 0;

			if (_numLightProbes > 0)
				_lightProbes.length = _numLightProbes = 0;
		}

		public function get numDeferredDirectionalLights():Number {
			return _numDeferredDirectionalLights;
		}

		public function get numDeferredPointLights():Number {
			return _numDeferredPointLights;
		}

        public function get deferredPointLights():Vector.<PointLight> {
            return _deferredPointLights;
        }
    }
}
