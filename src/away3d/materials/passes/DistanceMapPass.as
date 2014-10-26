package away3d.materials.passes {
    import away3d.arcane;
    import away3d.core.pool.MaterialPassData;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;

    import flash.display3D.Context3DMipFilter;
    import flash.display3D.Context3DTextureFilter;
    import flash.display3D.Context3DWrapMode;

    use namespace arcane;

    /**
     * DistanceMapPass is a pass that writes distance values to a depth map as a 32-bit value exploded over the 4 texture channels.
     * This is used to render omnidirectional shadow maps.
     */
    public class DistanceMapPass extends MaterialPassBase {
        private var _fragmentConstantsIndex:int;
        private var _texturesIndex:int;

        /**
         * Creates a new DistanceMapPass object.
         *
         * @param material The material to which this pass belongs.
         */
        public function DistanceMapPass()
        {
            super();
        }

        /**
         * Initializes the unchanging constant data for this material.
         */
        override public function initConstantData(shaderObject:ShaderObjectBase):void
        {
            super.initConstantData(shaderObject);

            var index:int = this._fragmentConstantsIndex;
            var data:Vector.<Number> = shaderObject.fragmentConstantData;
            data[index + 4] = 1.0 / 255.0;
            data[index + 5] = 1.0 / 255.0;
            data[index + 6] = 1.0 / 255.0;
            data[index + 7] = 0.0;
        }

        override public function includeDependencies(shaderObject:ShaderObjectBase):void
        {
            shaderObject.projectionDependencies++;
            shaderObject.viewDirDependencies++;

            if (shaderObject.alphaThreshold > 0)
                shaderObject.uvDependencies++;

            shaderObject.addWorldSpaceDependencies(false);
        }

        /**
         * @inheritDoc
         */
        override public function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String;
            var targetReg:ShaderRegisterElement = sharedRegisters.shadedTarget;
            var diffuseInputReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
            var dataReg1:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
            var dataReg2:ShaderRegisterElement = registerCache.getFreeFragmentConstant()

            this._fragmentConstantsIndex = dataReg1.index * 4;

            var temp1:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(temp1, 1);
            var temp2:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(temp2, 1);

            // squared distance to view
            code = "dp3 " + temp1 + ".z, " + sharedRegisters.viewDirVarying + ".xyz, " + sharedRegisters.viewDirVarying + ".xyz\n" +
                    "mul " + temp1 + ", " + dataReg1 + ", " + temp1 + ".z\n" +
                    "frc " + temp1 + ", " + temp1 + "\n" +
                    "mul " + temp2 + ", " + temp1 + ".yzww, " + dataReg2 + "\n";

            if (shaderObject.alphaThreshold > 0) {
                diffuseInputReg = registerCache.getFreeTextureReg();

                this._texturesIndex = diffuseInputReg.index;

                var albedo:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
                code += ShaderCompilerHelper.getTex2DSampleCode(albedo, sharedRegisters, diffuseInputReg, shaderObject.texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping);

                var cutOffReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();

                code += "sub " + albedo + ".w, " + albedo + ".w, " + cutOffReg + ".x\n" +
                        "kil " + albedo + ".w\n";
            }

            code += "sub " + targetReg + ", " + temp1 + ", " + temp2 + "\n";

            return code;
        }

        /**
         * @inheritDoc
         */
        arcane function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
        {
            super.activate(pass, stage, camera);

            var shaderObject:ShaderObjectBase = pass.shaderObject;

            var f:Number = camera.projection.far;

            f = 1 / (2 * f * f);
            // sqrt(f*f+f*f) is largest possible distance for any frustum, so we need to divide by it. Rarely a tight fit, but with 32 bits precision, it's enough.
            var index:Number = this._fragmentConstantsIndex;
            var data:Vector.<Number> = shaderObject.fragmentConstantData;
            data[index] = f;
            data[index + 1] = 255.0 * f;
            data[index + 2] = 65025.0 * f;
            data[index + 3] = 16581375.0 * f;

            if (shaderObject.alphaThreshold > 0) {
                stage.context3D.setSamplerStateAt(this._texturesIndex, shaderObject.repeatTextures ? Context3DWrapMode.REPEAT : Context3DWrapMode.CLAMP, shaderObject.useSmoothTextures ? Context3DTextureFilter.LINEAR : Context3DTextureFilter.NEAREST, shaderObject.useMipmapping ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
                stage.activateTexture(this._texturesIndex, shaderObject.texture);

                data[index + 8] = pass.shaderObject.alphaThreshold;
            }
        }
    }
}
