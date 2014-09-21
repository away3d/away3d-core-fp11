package away3d.animators {
    import away3d.animators.data.VertexAnimationMode;
    import away3d.arcane;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.passes.MaterialPassBase;

    import flash.display3D.Context3D;

    import flash.utils.Dictionary;

    use namespace arcane;

    /**
     * The animation data set used by vertex-based animators, containing vertex animation state data.
     *
     * @see away3d.animators.VertexAnimator
     */
    public class VertexAnimationSet extends AnimationSetBase implements IAnimationSet {
        private var _numPoses:uint;
        private var _blendMode:String;
//		private var _streamIndices:Dictionary = new Dictionary(true);
//		private var _useNormals:Dictionary = new Dictionary(true);
//		private var _useTangents:Dictionary = new Dictionary(true);
//		private var _uploadNormals:Boolean;
//		private var _uploadTangents:Boolean;

        /**
         * Returns the number of poses made available at once to the GPU animation code.
         */
        public function get numPoses():uint
        {
            return _numPoses;
        }

        /**
         * Returns the active blend mode of the vertex animator object.
         */
        public function get blendMode():String
        {
            return _blendMode;
        }

        /**
         * Returns whether or not normal data is used in last set GPU pass of the vertex shader.
         */
//		public function get useNormals():Boolean
//		{
//			return _uploadNormals;
//		}

        /**
         * Creates a new <code>VertexAnimationSet</code> object.
         *
         * @param numPoses The number of poses made available at once to the GPU animation code.
         * @param blendMode Optional value for setting the animation mode of the vertex animator object.
         *
         * @see away3d.animators.data.VertexAnimationMode
         */
        public function VertexAnimationSet(numPoses:uint = 2, blendMode:String = "absolute")
        {
            super();
            _numPoses = numPoses;
            _blendMode = blendMode;

        }

        /**
         * @inheritDoc
         */
        override public function getAGALVertexCode(shaderObject:ShaderObjectBase):String
        {
            if (_blendMode == VertexAnimationMode.ABSOLUTE)
                return getAbsoluteAGALCode(shaderObject, shaderObject.animatableAttributes, shaderObject.animationTargetRegisters);
            else
                return getAdditiveAGALCode(shaderObject, shaderObject.animatableAttributes, shaderObject.animationTargetRegisters);
        }

        /**
         * @inheritDoc
         */
        override public function activate(shaderObject:ShaderObjectBase, stage3DProxy:Stage3DProxy):void
        {
//			_uploadNormals = Boolean(_useNormals[shaderObject]);
//			_uploadTangents = Boolean(_useTangents[shaderObject]);
        }

        /**
         * @inheritDoc
         */
        override public function deactivate(shaderObject:ShaderObjectBase, stage3DProxy:Stage3DProxy):void
        {
//			var index:int = _streamIndices[pass];
//			var context:Context3D = stage3DProxy._context3D;
//			context.setVertexBufferAt(index, null);
//			if (_uploadNormals)
//				context.setVertexBufferAt(index + 1, null);
//			if (_uploadTangents)
//				context.setVertexBufferAt(index + 2, null);
        }

        /**
         * @inheritDoc
         */
        override public function getAGALFragmentCode(shaderObject:ShaderObjectBase, shadedTarget:String):String
        {
            return "";
        }

        /**
         * @inheritDoc
         */
        override public function getAGALUVCode(shaderObject:ShaderObjectBase):String
        {
            return "mov " + shaderObject.uvTarget + "," + shaderObject.uvSource + "\n";
        }

        /**
         * @inheritDoc
         */
        override public function doneAGALCode(shaderObject:ShaderObjectBase):void
        {

        }

        /**
         * Generates the vertex AGAL code for absolute blending.
         */
        private function getAbsoluteAGALCode(shaderObject:ShaderObjectBase, sourceRegisters:Vector.<String>, targetRegisters:Vector.<String>):String
        {
            var code:String = "";
            var temp1:String = findTempReg(targetRegisters);
            var temp2:String = findTempReg(targetRegisters, temp1);
            var regs:Array = ["x", "y", "z", "w"];
            var len:uint = sourceRegisters.length;
            var constantReg:String = "vc" + shaderObject.numUsedVertexConstants;

            if (len > 2)
                len = 2;
            var streamIndex:uint = shaderObject.numUsedStreams;

            for (var i:uint = 0; i < len; ++i) {
                code += "mul " + temp1 + ", " + sourceRegisters[i] + ", " + constantReg + "." + regs[0] + "\n";

                for (var j:uint = 1; j < _numPoses; ++j) {
                    code += "mul " + temp2 + ", va" + streamIndex + ", " + constantReg + "." + regs[j] + "\n";

                    if (j < _numPoses - 1)
                        code += "add " + temp1 + ", " + temp1 + ", " + temp2 + "\n";

                    ++streamIndex;
                }

                code += "add " + targetRegisters[i] + ", " + temp1 + ", " + temp2 + "\n";
            }

            // add code for bitangents if tangents are used
            if (shaderObject.tangentDependencies > 0 || shaderObject.outputsNormals) {
                code += "dp3 " + temp1 + ".x, " + sourceRegisters[uint(2)] + ", " + targetRegisters[uint(1)] + "\n" +
                        "mul " + temp1 + ", " + targetRegisters[uint(1)] + ", " + temp1 + ".x			 \n" +
                        "sub " + targetRegisters[uint(2)] + ", " + sourceRegisters[uint(2)] + ", " + temp1 + "\n";
            }
            return code;
        }

        /**
         * Generates the vertex AGAL code for additive blending.
         */
        private function getAdditiveAGALCode(shaderObject:ShaderObjectBase, sourceRegisters:Vector.<String>, targetRegisters:Vector.<String>):String
        {
            var code:String = "";
            var len:uint = sourceRegisters.length;
            var regs:Array = ["x", "y", "z", "w"];
            var temp1:String = findTempReg(targetRegisters);
            var k:uint;
            var streamIndex:uint = shaderObject.numUsedStreams;

            if (len > 2)
                len = 2;

            code += "mov  " + targetRegisters[0] + ", " + sourceRegisters[0] + "\n";
            if (shaderObject.normalDependencies > 0)
                code += "mov " + targetRegisters[1] + ", " + sourceRegisters[1] + "\n";

            for (var i:uint = 0; i < len; ++i) {
                for (var j:uint = 0; j < _numPoses; ++j) {
                    code += "mul " + temp1 + ", va" + (streamIndex + k) + ", vc" + shaderObject.numUsedVertexConstants + "." + regs[j] + "\n" +
                            "add " + targetRegisters[i] + ", " + targetRegisters[i] + ", " + temp1 + "\n";
                    k++;
                }
            }

            if (shaderObject.tangentDependencies > 0 || shaderObject.outputsNormals) {
                code += "dp3 " + temp1 + ".x, " + sourceRegisters[uint(2)] + ", " + targetRegisters[uint(1)] + "\n" +
                        "mul " + temp1 + ", " + targetRegisters[uint(1)] + ", " + temp1 + ".x			 \n" +
                        "sub " + targetRegisters[uint(2)] + ", " + sourceRegisters[uint(2)] + ", " + temp1 + "\n";
            }

            return code;
        }
    }
}
