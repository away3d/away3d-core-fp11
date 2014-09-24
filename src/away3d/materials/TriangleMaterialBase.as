package away3d.materials {
    import away3d.arcane;
    import away3d.core.base.TriangleSubGeometry;
    import away3d.core.geom.Matrix3DUtils;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;

    import flash.geom.Matrix3D;

    use namespace arcane;

    public class TriangleMaterialBase extends MaterialBase {
        override arcane function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";

            //get the projection coordinates
            var position:ShaderRegisterElement = (shaderObject.globalPosDependencies > 0) ? sharedRegisters.globalPositionVertex : sharedRegisters.localPosition;

            //reserving vertex constants for projection matrix
            var viewMatrixReg:ShaderRegisterElement = registerCache.getFreeVertexConstant();
            registerCache.getFreeVertexConstant();
            registerCache.getFreeVertexConstant();
            registerCache.getFreeVertexConstant();
            shaderObject.viewMatrixIndex = viewMatrixReg.index * 4;

            if (shaderObject.projectionDependencies > 0) {
                sharedRegisters.projectionFragment = registerCache.getFreeVarying();
                var temp:ShaderRegisterElement = registerCache.getFreeVertexVectorTemp();
                code += "m44 " + temp + ", " + position + ", " + viewMatrixReg + "\n" +
                        "mov " + sharedRegisters.projectionFragment + ", " + temp + "\n" +
                        "mov op, " + temp + "\n";
            } else {
                code += "m44 op, " + position + ", " + viewMatrixReg + "\n";
            }

            return code;
        }

        /**
         * @inheritDoc
         */
        override arcane function renderPass(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
        {
            super.renderPass(pass, renderable, stage, camera, viewProjection);

            var shaderObject:ShaderObjectBase = pass.shaderObject;

            if (shaderObject.sceneMatrixIndex >= 0) {
                renderable.sourceEntity.getRenderSceneTransform(camera).copyRawDataTo(shaderObject.vertexConstantData, shaderObject.sceneMatrixIndex, true);
                viewProjection.copyRawDataTo(shaderObject.vertexConstantData, shaderObject.viewMatrixIndex, true);
            } else {
                var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;

                matrix3D.copyFrom(renderable.sourceEntity.getRenderSceneTransform(camera));
                matrix3D.append(viewProjection);

                matrix3D.copyRawDataTo(shaderObject.vertexConstantData, shaderObject.viewMatrixIndex, true);
            }

            var context:Context3D = stage.context3D;

            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, shaderObject.vertexConstantData, shaderObject.numUsedVertexConstants);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, shaderObject.fragmentConstantData, shaderObject.numUsedFragmentConstants);

            stage.activateBuffer(0, renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
            context.drawTriangles(stage.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
        }
    }
}
