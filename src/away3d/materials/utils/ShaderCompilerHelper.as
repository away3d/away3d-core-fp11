package away3d.materials.utils {
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.textures.TextureProxyBase;

    import flash.display3D.Context3DTextureFormat;

    public class ShaderCompilerHelper {
        /**
         * A helper method that generates standard code for sampling from a texture using the normal uv coordinates.
         * @param vo The MethodVO object linking this method with the pass currently being compiled.
         * @param sharedReg The shared register object for the shader.
         * @param inputReg The texture stream register.
         * @param texture The texture which will be assigned to the given slot.
         * @param uvReg An optional uv register if coordinates different from the primary uv coordinates are to be used.
         * @param forceWrap If true, texture wrapping is enabled regardless of the material setting.
         * @return The fragment code that performs the sampling.
         *
         * @protected
         */
        public static function getTex2DSampleCode(targetReg:ShaderRegisterElement, sharedReg:ShaderRegisterData, inputReg:ShaderRegisterElement, texture:TextureProxyBase, smooth:Boolean, repeat:Boolean, mipmaps:Boolean, uvReg:ShaderRegisterElement = null, forceWrap:String = null):String
        {
            var wrap:String = forceWrap || (repeat ? "wrap" : "clamp");
            var format:String = ShaderCompilerHelper.getFormatStringForTexture(texture);
            var enableMipMaps:Boolean = mipmaps && texture.hasMipMaps;
            var filter:String = (smooth) ? (enableMipMaps ? "linear,miplinear" : "linear") : (enableMipMaps ? "nearest,mipnearest" : "nearest");

            if (uvReg == null)
                uvReg = sharedReg.uvVarying;

            return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <2d," + filter + "," + format + wrap + ">\n";
        }


        /**
         * A helper method that generates standard code for sampling from a cube texture.
         * @param vo The MethodVO object linking this method with the pass currently being compiled.
         * @param targetReg The register in which to store the sampled colour.
         * @param inputReg The texture stream register.
         * @param texture The cube map which will be assigned to the given slot.
         * @param uvReg The direction vector with which to sample the cube map.
         *
         * @protected
         */
        public static function getTexCubeSampleCode(targetReg:ShaderRegisterElement, inputReg:ShaderRegisterElement, texture:TextureProxyBase, smooth:Boolean, mipmaps:Boolean, uvReg:ShaderRegisterElement):String
        {
            var format:String = ShaderCompilerHelper.getFormatStringForTexture(texture);
            var enableMipMaps:Boolean = mipmaps && texture.hasMipMaps;
            var filter:String = (smooth) ? (enableMipMaps ? "linear,miplinear" : "linear") : (enableMipMaps ? "nearest,mipnearest" : "nearest");

            return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <cube," + format + filter + ">\n";
        }

        /**
         * Generates a texture format String for the sample instruction.
         * @param texture The texture for which to get the format String.
         * @return
         *
         * @protected
         */
        public static function getFormatStringForTexture(texture:TextureProxyBase):String
        {
            switch (texture.format) {
                case Context3DTextureFormat.COMPRESSED:
                    return "dxt1,";
                    break;
                case Context3DTextureFormat.COMPRESSED_ALPHA:
                    return "dxt5,";
                    break;
                default:
                    return "";
            }
        }
    }
}
