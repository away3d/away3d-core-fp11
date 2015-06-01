package away3d.animators {
    import away3d.animators.data.VertexAnimationMode;
    import away3d.animators.states.IVertexAnimationState;
    import away3d.animators.transitions.IAnimationTransition;
    import away3d.arcane;
    import away3d.core.base.TriangleSubMesh;
    import away3d.core.base.SubGeometryBase;
    import away3d.core.base.TriangleSubGeometry;
    import away3d.managers.Stage3DProxy;
    import away3d.core.pool.IRenderable;
    import away3d.core.pool.RenderableBase;
    import away3d.core.pool.TriangleSubMeshRenderable;
    import away3d.core.pool.VertexDataPool;
    import away3d.entities.Camera3D;
    import away3d.entities.Mesh;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.passes.MaterialPassBase;

    import flash.display3D.Context3DProgramType;

    use namespace arcane;

    /**
     * Provides an interface for assigning vertex-based animation data sets to mesh-based entity objects
     * and controlling the various available states of animation through an interative playhead that can be
     * automatically updated or manually triggered.
     */
    public class VertexAnimator extends AnimatorBase implements IAnimator {
        private var _vertexAnimationSet:VertexAnimationSet;
        private var _poses:Array = [];
        private var _weights:Vector.<Number> = Vector.<Number>([1, 0, 0, 0]);
        private var _numPoses:uint;
        private var _blendMode:String;
        private var _activeVertexState:IVertexAnimationState;

        /**
         * Creates a new <code>VertexAnimator</code> object.
         *
         * @param vertexAnimationSet The animation data set containing the vertex animations used by the animator.
         */
        public function VertexAnimator(vertexAnimationSet:VertexAnimationSet)
        {
            super(vertexAnimationSet);

            _vertexAnimationSet = vertexAnimationSet;
            _numPoses = vertexAnimationSet.numPoses;
            _blendMode = vertexAnimationSet.blendMode;
        }

        /**
         * @inheritDoc
         */
        override public function clone():IAnimator
        {
            return new VertexAnimator(this._vertexAnimationSet);
        }

        /**
         * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
         * @param sequenceName The name of the clip to be played.
         */
        public function play(name:String, transition:IAnimationTransition = null, offset:Number = NaN):void
        {
            if (_activeAnimationName == name)
                return;

            _activeAnimationName = name;

            //TODO: implement transitions in vertex animator

            if (!_animationSet.hasAnimation(name))
                throw new Error("Animation root node " + name + " not found!");

            _activeNode = _animationSet.getAnimation(name);

            _activeState = getAnimationState(_activeNode);

            if (updatePosition) {
                //update straight away to reset position deltas
                _activeState.update(_absoluteTime);
                _activeState.positionDelta;
            }

            _activeVertexState = _activeState as IVertexAnimationState;

            start();

            //apply a time offset if specified
            if (!isNaN(offset))
                reset(name, offset);
        }

        /**
         * @inheritDoc
         */
        override protected function updateDeltaTime(dt:Number):void
        {
            super.updateDeltaTime(dt);

            var geometryFlag:Boolean = false;

            if (_poses[0] != _activeVertexState.currentGeometry) {
                _poses[0] = _activeVertexState.currentGeometry;
                geometryFlag = true;
            }

            if (_poses[1] != _activeVertexState.nextGeometry) {
                _poses[1] = _activeVertexState.nextGeometry;
                geometryFlag = true;
            }

            _weights[0] = 1 - (_weights[1] = _activeVertexState.blendWeight);

            if (geometryFlag) {
                //invalidate meshes
                var mesh:Mesh;
                var len:Number = _owners.length;
                for (var i:Number = 0; i < len; i++) {
                    mesh = _owners[i];
                    mesh.invalidateRenderableGeometries();
                }
            }
        }

        /**
         * @inheritDoc
         */
        override public function setRenderState(shaderObject:ShaderObjectBase, renderable:RenderableBase, stage3DProxy:Stage3DProxy, camera:Camera3D, vertexConstantOffset:int, vertexStreamOffset:int):void
        {
            // todo: add code for when running on cpu

            // if no poses defined, set temp data
            if (!_poses.length) {
                setNullPose(shaderObject, stage3DProxy, renderable, vertexConstantOffset, vertexStreamOffset);
                return;
            }

            // this type of animation can only be SubMesh
            var subMesh:TriangleSubMesh = (renderable as TriangleSubMeshRenderable).subMesh as TriangleSubMesh;
            var subGeom:SubGeometryBase;
            var i:uint;
            var len:uint = _numPoses;

            stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

            if (_blendMode == VertexAnimationMode.ABSOLUTE)
                i = 1;
            else
                i = 0;

            for (; i < len; ++i) {
                subGeom = _poses[i].subGeometries[subMesh.index] || subMesh.subGeometry;

                stage3DProxy.activateBuffer(vertexStreamOffset++, VertexDataPool.getItem(subGeom, renderable.getIndexData(), TriangleSubGeometry.POSITION_DATA), subGeom.getOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);

                if (shaderObject.normalDependencies > 0)
                    stage3DProxy.activateBuffer(vertexStreamOffset++, VertexDataPool.getItem(subGeom, renderable.getIndexData(), TriangleSubGeometry.NORMAL_DATA), subGeom.getOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
            }
        }

        private function setNullPose(shaderObject:ShaderObjectBase, stage3DProxy:Stage3DProxy, renderable:RenderableBase, vertexConstantOffset:int, vertexStreamOffset:int):void
        {
            stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

            if (_blendMode == VertexAnimationMode.ABSOLUTE) {
                var len:uint = _numPoses;
                for (var i:uint = 1; i < len; ++i) {
                    stage3DProxy.activateBuffer(vertexStreamOffset++, renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);

                    if (shaderObject.normalDependencies > 0)
                        stage3DProxy.activateBuffer(vertexStreamOffset++, renderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), renderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
                }
            }
            // todo: set temp data for additive?
        }

        /**
         * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
         * Needs to be called if gpu code is potentially required.
         */
        override public function testGPUCompatibility(shaderObject:ShaderObjectBase):void
        {
        }

        override public function getRenderableSubGeometry(renderable:IRenderable, sourceSubGeometry:SubGeometryBase):SubGeometryBase
        {
            if (_blendMode == VertexAnimationMode.ABSOLUTE && _poses.length)
                return _poses[0].subGeometries[(renderable as TriangleSubMeshRenderable).subMesh.index] || sourceSubGeometry;

            //nothing to do here
            return sourceSubGeometry;
        }
    }
}
