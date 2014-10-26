package away3d.materials {
    import away3d.arcane;
    import away3d.core.base.TriangleSubGeometry;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.passes.SkyBoxPass;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.CubeTextureBase;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DMipFilter;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFilter;
    import flash.display3D.Context3DWrapMode;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    use namespace arcane;

    /**
     * SkyBoxMaterial is a material exclusively used to render skyboxes
     *
     * @see away3d.entities.SkyBox
     */
    public class SkyBoxMaterial extends MaterialBase {
        private var _vertexData:Vector.<Number>;
        private var _cubeMap:CubeTextureBase;
        private var _skyboxPass:SkyBoxPass;

        /**
         * Creates a new SkyboxMaterial object.
         * @param cubeMap The CubeMap to use as the skybox.
         */
        public function SkyBoxMaterial(cubeMap:CubeTextureBase, smooth:Boolean = true, repeat:Boolean = false, mipmap:Boolean = false)
        {

            super();

            _cubeMap = cubeMap;
            addScreenPass(this._skyboxPass = new SkyBoxPass());

            _vertexData = Vector.<Number>([0, 0, 0, 0, 1, 1, 1, 1]);
        }

        /**
         * The cube texture to use as the skybox.
         */
        public function get cubeMap():CubeTextureBase
        {
            return this._cubeMap;
        }

        public function  set cubeMap(value:CubeTextureBase):void
        {
            if (value && this._cubeMap && (value.hasMipMaps != _cubeMap.hasMipMaps || value.format != this._cubeMap.format))
                invalidatePasses();

            _cubeMap = value;
        }

        /**
         * @inheritDoc
         */
        override arcane function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "mul vt0, va0, vc5\n" +
                    "add vt0, vt0, vc4\n" +
                    "m44 op, vt0, vc0\n" +
                    "mov v0, va0\n";
        }

        /**
         * @inheritDoc
         */
        override arcane function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            //var cubeMapReg:ShaderRegisterElement = registerCache.getFreeTextureReg();

            //this._texturesIndex = cubeMapReg.index;

            //ShaderCompilerHelper.getTexCubeSampleCode(sharedRegisters.shadedTarget, cubeMapReg, this._cubeTexture, shaderObject.useSmoothTextures, shaderObject.useMipmapping);

            var mip:String = ",mipnone";

            if (_cubeMap.hasMipMaps)
                mip = ",miplinear";

            return "tex ft0, v0, fs0 <cube," + ShaderCompilerHelper.getFormatStringForTexture(this._cubeMap) + "linear,clamp" + mip + ">\n";
        }

        /**
         * @inheritDoc
         */
        override arcane function activatePass(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
        {
            super.activatePass(pass, stage, camera);

            var context:Context3D = stage.context3D;
            context.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.LINEAR, _cubeMap.hasMipMaps ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
            context.setDepthTest(false, Context3DCompareMode.LESS);
            stage.activateTexture(0, _cubeMap);
        }

        /**
         * @inheritDoc
         */
        override arcane function renderPass(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
        {
            super.renderPass(pass, renderable, stage, camera, viewProjection);

            var context:Context3D = stage.context3D;
            var pos:Vector3D = camera.scenePosition;
            _vertexData[0] = pos.x;
            _vertexData[1] = pos.y;
            _vertexData[2] = pos.z;
            _vertexData[4] = this._vertexData[5] = this._vertexData[6] = camera.projection.far / Math.sqrt(3);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, viewProjection, true);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, this._vertexData, 2);

            stage.activateBuffer(0, renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
            context.drawTriangles(stage.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
        }
    }
}
