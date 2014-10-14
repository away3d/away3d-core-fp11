package away3d.materials.passes {
    import away3d.arcane;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
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
    import flash.geom.Matrix3D;

    use namespace arcane;

    /**
     * DepthMapPass is a pass that writes depth values to a depth map as a 32-bit value exploded over the 4 texture channels.
     * This is used to render shadow maps, depth maps, etc.
     */
    public class DepthMapPass extends MaterialPassBase {
        private var _fragmentConstantsIndex:int;
        private var _texturesIndex:int;

        /**
         * Creates a new DepthMapPass object.
         *
         * @param material The material to which this pass belongs.
         */
        public function DepthMapPass()
        {
        }

        /**
         * Initializes the unchanging constant data for this material.
         */

        override public function initConstantData(shaderObject:ShaderObjectBase):void
        {
            super.initConstantData(shaderObject);

            var index:int = _fragmentConstantsIndex;
            var data:Vector.<Number> = shaderObject.fragmentConstantData;
            data[index] = 1.0;
            data[index + 1] = 255.0;
            data[index + 2] = 65025.0;
            data[index + 3] = 16581375.0;
            data[index + 4] = 1.0 / 255.0;
            data[index + 5] = 1.0 / 255.0;
            data[index + 6] = 1.0 / 255.0;
            data[index + 7] = 0.0;
        }

        override public function includeDependencies(shaderObject:ShaderObjectBase):void
        {
            shaderObject.projectionDependencies++;

            if (shaderObject.alphaThreshold > 0)
                shaderObject.uvDependencies++;
        }

        /**
         * @inheritDoc
         */
        override public function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";
            var targetReg:ShaderRegisterElement = sharedRegisters.shadedTarget;
            var diffuseInputReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
            var dataReg1:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
            var dataReg2:ShaderRegisterElement = registerCache.getFreeFragmentConstant();

            _fragmentConstantsIndex = dataReg1.index * 4;

            var temp1:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(temp1, 1);
            var temp2:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
            registerCache.addFragmentTempUsages(temp2, 1);

            code += "div " + temp1 + ", " + sharedRegisters.projectionFragment + ", " + sharedRegisters.projectionFragment + ".w\n" + //"sub ft2.z, fc0.x, ft2.z\n" +    //invert
                    "mul " + temp1 + ", " + dataReg1 + ", " + temp1 + ".z\n" +
                    "frc " + temp1 + ", " + temp1 + "\n" +
                    "mul " + temp2 + ", " + temp1 + ".yzww, " + dataReg2 + "\n";

            //codeF += "mov ft1.w, fc1.w	\n" +
            //    "mov ft0.w, fc0.x	\n";

            if (shaderObject.alphaThreshold > 0) {
                diffuseInputReg = registerCache.getFreeTextureReg();

                _texturesIndex = diffuseInputReg.index;

                var albedo:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
                code += ShaderCompilerHelper.getTex2DSampleCode(albedo, sharedRegisters, diffuseInputReg, shaderObject.texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping);

                var cutOffReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();

                code += "sub " + albedo + ".w, " + albedo + ".w, " + cutOffReg + ".x\n" +
                        "kil " + albedo + ".w\n";
            }

            code += "sub " + targetReg + ", " + temp1 + ", " + temp2 + "\n";

            registerCache.removeFragmentTempUsage(temp1);
            registerCache.removeFragmentTempUsage(temp2);

            return code;
        }

        arcane function render(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D)
        {
            //this.setRenderState(pass, renderable, stage, camera, viewProjection);
        }

        /**
         * @inheritDoc
         */
        arcane function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
        {
            super.activate(pass, stage, camera);


            var shaderObject:ShaderObjectBase = pass.shaderObject;

            if (shaderObject.alphaThreshold > 0) {
                stage.context3D.setSamplerStateAt(_texturesIndex, shaderObject.repeatTextures ? Context3DWrapMode.REPEAT : Context3DWrapMode.CLAMP, shaderObject.useSmoothTextures ? Context3DTextureFilter.LINEAR : Context3DTextureFilter.NEAREST, shaderObject.useMipmapping ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
                stage.activateTexture(_texturesIndex, shaderObject.texture);

                shaderObject.fragmentConstantData[_fragmentConstantsIndex + 8] = pass.shaderObject.alphaThreshold;
            }
        }
    }
}
