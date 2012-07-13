package away3d.animators
{
	import away3d.animators.transitions.StateTransitionBase;
	import away3d.arcane;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;
	
	import flash.display3D.*;

	use namespace arcane;

	/**
	 * Provides an interface for assigning vertex-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	public class VertexAnimator extends AnimatorBase implements IAnimator
	{
		private var _activeNode:IVertexAnimationNode;
		
		private var _vertexAnimationSet:VertexAnimationSet;
		private var _poses : Vector.<Geometry> = new Vector.<Geometry>();
		private var _weights : Vector.<Number> = Vector.<Number>([1, 0, 0, 0]);
		private var _numPoses : uint;
		private var _blendMode:String;
		
		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function VertexAnimator(vertexAnimationSet:VertexAnimationSet )
		{
			super(vertexAnimationSet);
			
			_vertexAnimationSet = vertexAnimationSet;
			_numPoses = vertexAnimationSet.numPoses;
			_blendMode = vertexAnimationSet.blendMode;
		}

		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(stateName : String, stateTransition:StateTransitionBase = null) : void
		{
			_activeState = _vertexAnimationSet.getState(stateName) as VertexAnimationState;
			
			if (!_activeState)
				throw new Error("Animation state " + stateName + " not found!");
			
			_activeNode = _activeState.rootNode as IVertexAnimationNode;
			
			_absoluteTime = 0;
			
			start();
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateDeltaTime(dt : Number) : void
		{
			_absoluteTime += dt;
			
			_activeNode.update(_absoluteTime);
			
			_poses[uint(0)] = _activeNode.currentGeometry;
			_poses[uint(1)] = _activeNode.nextGeometry;
			_weights[uint(0)] = 1 - (_weights[uint(1)] = _activeNode.blendWeight);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			// todo: add code for when running on cpu

			// if no poses defined, set temp data
			if (!_poses.length) {
				setNullPose(stage3DProxy, renderable, vertexConstantOffset, vertexStreamOffset);
				return;
			}

			// this type of animation can only be SubMesh
			var subMesh : SubMesh = SubMesh(renderable);
			var subGeom : SubGeometry;
			var i : uint;
			var len : uint = _numPoses;

			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

			if (_blendMode == VertexAnimationMode.ABSOLUTE) {
				i = 1;
				subGeom = _poses[uint(0)].subGeometries[subMesh._index];
				// set the base sub-geometry so the material can simply pick up on this data
				if (subGeom)
					subMesh.subGeometry = subGeom;
			}
			else i = 0;

			for (; i < len; ++i) {
				subGeom = _poses[i].subGeometries[subMesh._index] || subMesh.subGeometry;

				stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset++, subGeom.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, subGeom.vertexBufferOffset);

				if (_vertexAnimationSet.useNormals)
					stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset++, subGeom.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, subGeom.normalBufferOffset);

			}
		}

		private function setNullPose(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

			if (_blendMode == VertexAnimationMode.ABSOLUTE) {
				var len : uint = _numPoses;
				for (var i : uint = 1; i < len; ++i) {
					stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset++, renderable.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.vertexBufferOffset);

					if (_vertexAnimationSet.useNormals)
						stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset++, renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.normalBufferOffset);
				}
			}
			// todo: set temp data for additive?
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