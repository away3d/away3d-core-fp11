package away3d.materials {
    import away3d.core.pool.MaterialPassData;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.passes.*;
    import away3d.arcane;
    import away3d.core.base.LineSubGeometry;
    import away3d.managers.RTTBufferManager;
    import away3d.managers.Stage3DProxy;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.geom.Matrix3D;

    use namespace arcane;

    /**
     * SegmentPass is a material pass that draws wireframe segments.
     */
    public class LineBasicMaterial extends MaterialBase {
        protected static const ONE_VECTOR:Vector.<Number> = Vector.<Number>([ 1, 1, 1, 1 ]);
        protected static const FRONT_VECTOR:Vector.<Number> = Vector.<Number>([ 0, 0, -1, 0 ]);

        private var _constants:Vector.<Number> = new Vector.<Number>(4, true);
        private var _calcMatrix:Matrix3D;
        private var _thickness:Number;

        private var _screenPass:LineBasicPass;

        /**
         * Creates a new SegmentPass object.
         *
         * @param thickness the thickness of the segments to be drawn.
         */
        public function LineBasicMaterial(thickness:Number = 1.25)
        {
            super();
            _thickness = thickness;

            bothSides = true;

            addScreenPass(_screenPass = new LineBasicPass());

            _calcMatrix = new Matrix3D();

            _constants[1] = 1 / 255;
        }

        /**
         * @inheritDoc
         */
        override arcane function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "m44 vt0, va0, vc8			\n" + // transform Q0 to eye space
                    "m44 vt1, va1, vc8			\n" + // transform Q1 to eye space
                    "sub vt2, vt1, vt0 			\n" + // L = Q1 - Q0

                // test if behind camera near plane
                // if 0 - Q0.z < Camera.near then the point needs to be clipped
                //"neg vt5.x, vt0.z				\n" + // 0 - Q0.z
                    "slt vt5.x, vt0.z, vc7.z			\n" + // behind = ( 0 - Q0.z < -Camera.near ) ? 1 : 0
                    "sub vt5.y, vc5.x, vt5.x			\n" + // !behind = 1 - behind

                // p = point on the plane (0,0,-near)
                // n = plane normal (0,0,-1)
                // D = Q1 - Q0
                // t = ( dot( n, ( p - Q0 ) ) / ( dot( n, d )

                // solve for t where line crosses Camera.near
                    "add vt4.x, vt0.z, vc7.z			\n" + // Q0.z + ( -Camera.near )
                    "sub vt4.y, vt0.z, vt1.z			\n" + // Q0.z - Q1.z

                // fix divide by zero for horizontal lines
                    "seq vt4.z, vt4.y vc6.x			\n" + // offset = (Q0.z - Q1.z)==0 ? 1 : 0
                    "add vt4.y, vt4.y, vt4.z			\n" + // ( Q0.z - Q1.z ) + offset

                    "div vt4.z, vt4.x, vt4.y			\n" + // t = ( Q0.z - near ) / ( Q0.z - Q1.z )

                    "mul vt4.xyz, vt4.zzz, vt2.xyz	\n" + // t(L)
                    "add vt3.xyz, vt0.xyz, vt4.xyz	\n" + // Qclipped = Q0 + t(L)
                    "mov vt3.w, vc5.x			\n" + // Qclipped.w = 1

                // If necessary, replace Q0 with new Qclipped
                    "mul vt0, vt0, vt5.yyyy			\n" + // !behind * Q0
                    "mul vt3, vt3, vt5.xxxx			\n" + // behind * Qclipped
                    "add vt0, vt0, vt3				\n" + // newQ0 = Q0 + Qclipped

                // calculate side vector for line
                    "sub vt2, vt1, vt0 			\n" + // L = Q1 - Q0
                    "nrm vt2.xyz, vt2.xyz			\n" + // normalize( L )
                    "nrm vt5.xyz, vt0.xyz			\n" + // D = normalize( Q1 )
                    "mov vt5.w, vc5.x				\n" + // D.w = 1
                    "crs vt3.xyz, vt2, vt5			\n" + // S = L x D
                    "nrm vt3.xyz, vt3.xyz			\n" + // normalize( S )

                // face the side vector properly for the given point
                    "mul vt3.xyz, vt3.xyz, va2.xxx	\n" + // S *= weight
                    "mov vt3.w, vc5.x			\n" + // S.w = 1

                // calculate the amount required to move at the point's distance to correspond to the line's pixel width
                // scale the side vector by that amount
                    "dp3 vt4.x, vt0, vc6			\n" + // distance = dot( view )
                    "mul vt4.x, vt4.x, vc7.x			\n" + // distance *= vpsod
                    "mul vt3.xyz, vt3.xyz, vt4.xxx	\n" + // S.xyz *= pixelScaleFactor

                // add scaled side vector to Q0 and transform to clip space
                    "add vt0.xyz, vt0.xyz, vt3.xyz	\n" + // Q0 + S

                    "m44 op, vt0, vc0			\n" + // transform Q0 to clip space

                // interpolate color
                    "mov v0, va3				\n";
        }

        /**
         * @inheritDoc
         * todo: keep maps in dictionary per renderable
         */
        override arcane function renderPass(pass:MaterialPassData, renderable:RenderableBase, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
        {
            var context:Context3D = stage3DProxy._context3D;
            _calcMatrix.copyFrom(renderable.sourceEntity.sceneTransform);
            _calcMatrix.append(camera.inverseSceneTransform);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, _calcMatrix, true);

            stage3DProxy.activateBuffer(0, renderable.getVertexData(LineSubGeometry.START_POSITION_DATA), renderable.getVertexOffset(LineSubGeometry.START_POSITION_DATA), LineSubGeometry.POSITION_FORMAT);
            stage3DProxy.activateBuffer(1, renderable.getVertexData(LineSubGeometry.END_POSITION_DATA), renderable.getVertexOffset(LineSubGeometry.END_POSITION_DATA), LineSubGeometry.POSITION_FORMAT);
            stage3DProxy.activateBuffer(2, renderable.getVertexData(LineSubGeometry.THICKNESS_DATA), renderable.getVertexOffset(LineSubGeometry.THICKNESS_DATA), LineSubGeometry.THICKNESS_FORMAT);
            stage3DProxy.activateBuffer(3, renderable.getVertexData(LineSubGeometry.COLOR_DATA), renderable.getVertexOffset(LineSubGeometry.COLOR_DATA), LineSubGeometry.COLOR_FORMAT);

            context.drawTriangles(stage3DProxy.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
        }

        /**
         * @inheritDoc
         */
        override arcane function activatePass(pass:MaterialPassData, stage3DProxy:Stage3DProxy, camera:Camera3D):void
        {
            var context:Context3D = stage3DProxy._context3D;
            super.activatePass(pass, stage3DProxy, camera);

            if (stage3DProxy.scissorRect)
                _constants[0] = _thickness / Math.min(stage3DProxy.scissorRect.width, stage3DProxy.scissorRect.height);
            else
                _constants[0] = _thickness / Math.min(stage3DProxy.width, stage3DProxy.height);

            // value to convert distance from camera to model length per pixel width
            _constants[2] = camera.projection.near;

            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, ONE_VECTOR);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 6, FRONT_VECTOR);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 7, _constants);

            // projection matrix
            if (!stage3DProxy.renderTarget)
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, camera.projection.matrix, true);
            else {
                //TODO: to find a better way
                _calcMatrix.copyFrom(camera.projection.matrix);
                var rttBufferManager:RTTBufferManager = RTTBufferManager.getInstance(stage3DProxy);
                _calcMatrix.appendScale(rttBufferManager.textureRatioX, rttBufferManager.textureRatioY, 1);
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _calcMatrix, true);
            }
        }
    }
}
