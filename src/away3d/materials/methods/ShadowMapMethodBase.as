package away3d.materials.methods {
    import away3d.*;
    import away3d.core.base.LightBase;
    import away3d.core.library.AssetType;
    import away3d.core.library.IAsset;
    import away3d.materials.shadowmappers.ShadowMapperBase;

    use namespace arcane;

    /**
     * ShadowMapMethodBase provides an abstract base method for shadow map methods.
     */
    public class ShadowMapMethodBase extends ShadingMethodBase implements IAsset {
        protected var _castingLight:LightBase;
        protected var _shadowMapper:ShadowMapperBase;

        protected var _epsilon:Number = .02;
        protected var _alpha:Number = 1;

        /**
         * Creates a new ShadowMapMethodBase object.
         * @param castingLight The light used to cast shadows.
         */
        public function ShadowMapMethodBase(castingLight:LightBase)
        {
            super();
            _castingLight = castingLight;
            castingLight.castsShadows = true;
            _shadowMapper = castingLight.shadowMapper;
        }

        /**
         * @inheritDoc
         */
        override public function get assetType():String
        {
            return AssetType.SHADOW_MAP_METHOD;
        }

        /**
         * The "transparency" of the shadows. This allows making shadows less strong.
         */
        public function get alpha():Number
        {
            return _alpha;
        }

        public function set alpha(value:Number):void
        {
            _alpha = value;
        }

        /**
         * The light casting the shadows.
         */
        public function get castingLight():LightBase
        {
            return _castingLight;
        }

        /**
         * A small value to counter floating point precision errors when comparing values in the shadow map with the
         * calculated depth value. Increase this if shadow banding occurs, decrease it if the shadow seems to be too detached.
         */
        public function get epsilon():Number
        {
            return _epsilon;
        }

        public function set epsilon(value:Number):void
        {
            _epsilon = value;
        }
    }
}
