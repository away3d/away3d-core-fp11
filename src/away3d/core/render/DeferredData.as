package away3d.core.render {
    import away3d.textures.RenderTexture;
    import away3d.textures.Texture2DBase;

    public class DeferredData {

        private static const DRAW_DEPTH_BIT:uint = 0x1;
        private static const DRAW_WORLD_NORMAL_BIT:uint = 0x2;
        private static const DRAW_POSITION_BIT:uint = 0x4;
        private static const DRAW_ALBEDO_BIT:uint = 0x8;
        private static const DRAW_SPECULAR_BIT:uint = 0x10;
        private static const USE_SPECULAR_LIGHTING_BIT:uint = 0x20;
        private static const USE_DIFFUSE_LIGHTING_BIT:uint = 0x40;
        private static const USE_COLORED_SPECULAR_BIT:uint = 0x80;
        private static const MRT_BIT:uint = 0x100;

        public var drawDepth:Boolean = true;
        public var drawWorldNormal:Boolean = true;
        public var drawPosition:Boolean = false;
        public var drawAlbedo:Boolean = false;
        public var drawSpecular:Boolean = false;

        public var useSpecularLighting:Boolean = false;
        public var useDiffuseLighting:Boolean = false;
        public var useColoredSpecular:Boolean = false;
        public var useMRT:Boolean = true;

        //textures
        public var sceneDepthTexture:RenderTexture;
        public var sceneNormalTexture:RenderTexture;
        public var lightAccumulation:RenderTexture;
        public var lightAccumulationSpecular:RenderTexture;

        public function disposeLightBuffers():void {
            disposeLightBuffer();
            disposeLightSpecularBuffer();
        }

        public function disposeLightBuffer():void {
            if (lightAccumulation) {
                lightAccumulation.dispose();
                lightAccumulation = null;
            }
        }

        public function disposeLightSpecularBuffer():void {
            if (lightAccumulationSpecular) {
                lightAccumulationSpecular.dispose();
                lightAccumulationSpecular = null;
            }
        }

        public function disposeDepthTexture():void {
            if (sceneDepthTexture) {
                sceneDepthTexture.dispose();
                sceneDepthTexture = null;
            }
        }

        public function getHashForDeferredLighting():uint {
            var result:uint = 0;
            if (useSpecularLighting) {
                result += USE_SPECULAR_LIGHTING_BIT;
            }
            if (useColoredSpecular) {
                result += USE_COLORED_SPECULAR_BIT;
            }
            if (useDiffuseLighting) {
                result += USE_COLORED_SPECULAR_BIT;
            }
            if (useMRT) {
                result += MRT_BIT;
            }
            return result;
        }
    }
}