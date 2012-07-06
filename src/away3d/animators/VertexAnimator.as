package away3d.animators
{
	import away3d.arcane;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;
	
	import flash.display3D.*;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class VertexAnimator extends AnimatorBase implements IAnimator
	{
		private var _activeNode : VertexClipNode;
		private var _absoluteTime : Number;
		
		private var _vertexAnimationLibrary:VertexAnimationLibrary;
		private var _poses : Vector.<Geometry> = new Vector.<Geometry>();
		private var _weights : Vector.<Number> = Vector.<Number>([1, 0, 0, 0]);
		private var _numPoses : uint;
		private var _blendMode : String;
		
		
		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function VertexAnimator(vertexAnimationLibrary:VertexAnimationLibrary )
		{
			super(vertexAnimationLibrary);
			
			_vertexAnimationLibrary = vertexAnimationLibrary;
			_numPoses = vertexAnimationLibrary.numPoses;
			_blendMode = vertexAnimationLibrary.blendMode;
		}

		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(stateName : String) : void
		{
			_activeNode = (_vertexAnimationLibrary.getState(stateName) as VertexAnimationState).rootNode as VertexClipNode;
			
			if (!_activeNode)
				throw new Error("Clip not found!");

			reset();
			start();
		}

		private function reset() : void
		{
			_absoluteTime = 0;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			_absoluteTime += scaledDT;
			
			_activeNode.update(_absoluteTime);
			
			_poses[uint(0)] = _activeNode.currentFrame;
			_poses[uint(1)] = _activeNode.nextFrame;
			_weights[uint(0)] = 1 - (_weights[uint(1)] = _activeNode.blendWeight);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			// todo: add code for when running on cpu
			var i : uint;
			var len : uint = _numPoses;
			var index : uint = _vertexAnimationLibrary.streamIndex;
			var context : Context3D = stage3DProxy._context3D;

			// if no poses defined, set temp data
			if (!_poses.length) {
				if (_blendMode == VertexAnimationMode.ABSOLUTE) {
					for (i = 1; i < len; ++i) {
						stage3DProxy.setSimpleVertexBuffer(index + (j++), renderable.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.vertexBufferOffset);
						context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

						if (_vertexAnimationLibrary.useNormals)
							stage3DProxy.setSimpleVertexBuffer(index + (j++), renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.normalBufferOffset);
					}
				}
					// todo: set temp data for additive?
				return;
			}

			// this type of animation can only be SubMesh
			var subMesh : SubMesh = SubMesh(renderable);
			var subGeom : SubGeometry;
			var j : uint;

			if (_blendMode == VertexAnimationMode.ABSOLUTE) {
				i = 1;
				subGeom = _poses[uint(0)].subGeometries[subMesh._index];
				if (subGeom) subMesh.subGeometry = subGeom;
			}
			else i = 0;
			// set the base sub-geometry so the material can simply pick up on this data



			for (; i < len; ++i) {
				subGeom = _poses[i].subGeometries[subMesh._index] || subMesh.subGeometry;
				stage3DProxy.setSimpleVertexBuffer(index + (j++), subGeom.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, subGeom.vertexBufferOffset);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

				if (_vertexAnimationLibrary.useNormals)
					stage3DProxy.setSimpleVertexBuffer(index + (j++), subGeom.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, subGeom.normalBufferOffset);

			}
		}

				
        /**
         * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
         */
        public function testGPUCompatibility(pass : MaterialPassBase) : void
        {
        }
	}
}