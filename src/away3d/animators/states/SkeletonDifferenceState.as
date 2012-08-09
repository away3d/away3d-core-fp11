package away3d.animators.states
{
	import away3d.animators.IAnimator;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.core.math.*;
	
	import flash.geom.*;
	
	/**
	 * 
	 */
	public class SkeletonDifferenceState extends AnimationStateBase implements ISkeletonAnimationState
	{
		private var _blendWeight : Number = 0;
		private static var _tempQuat : Quaternion = new Quaternion();
		private var _skeletonAnimationNode:SkeletonDifferenceNode;
		private var _skeletonPose : SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty : Boolean = true;
		private var _baseInput:ISkeletonAnimationState;
		private var _differenceInput:ISkeletonAnimationState;
		
		/**
		 * Defines a fractional value between 0 and 1 representing the blending ratio between the base input (0) and difference input (1),
		 * used to produce the skeleton pose output.
		 * 
		 * @see #baseInput
		 * @see #differenceInput
		 */
		public function get blendWeight() : Number
		{
			return _blendWeight;
		}

		public function set blendWeight(value : Number) : void
		{
			_blendWeight = value;
			
			_positionDeltaDirty = true;
			_skeletonPoseDirty = true;
		}
		
		function SkeletonDifferenceState(animator:IAnimator, skeletonAnimationNode:SkeletonDifferenceNode)
		{
			super(animator, skeletonAnimationNode);
			
			_skeletonAnimationNode = skeletonAnimationNode;
			
			_baseInput = animator.getAnimationState(_skeletonAnimationNode.baseInput) as ISkeletonAnimationState;
			_differenceInput = animator.getAnimationState(_skeletonAnimationNode.differenceInput) as ISkeletonAnimationState;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function phase(value:Number):void
		{
			_skeletonPoseDirty = true;
			
			_positionDeltaDirty = true;
			
			_baseInput.phase(value);
			_baseInput.phase(value);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time : int) : void
		{
			_skeletonPoseDirty = true;
			
			_baseInput.update(time);
			_differenceInput.update(time);
			
			super.updateTime(time);
		}
		
		/**
		 * Returns the current skeleton pose of the animation in the clip based on the internal playhead position.
		 */
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if (_skeletonPoseDirty)
				updateSkeletonPose(skeleton);
			
			return _skeletonPose;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updatePositionDelta() : void
		{
			_positionDeltaDirty = false;
			
			var deltA : Vector3D = _baseInput.positionDelta;
			var deltB : Vector3D = _differenceInput.positionDelta;

			positionDelta.x = deltA.x + _blendWeight*deltB.x;
			positionDelta.y = deltA.y + _blendWeight*deltB.y;
			positionDelta.z = deltA.z + _blendWeight*deltB.z;
		}

		/**
		 * Updates the output skeleton pose of the node based on the blendWeight value between base input and difference input nodes.
		 * 
		 * @param skeleton The skeleton used by the animator requesting the ouput pose. 
		 */
		private function updateSkeletonPose(skeleton : Skeleton) : void
		{
			_skeletonPoseDirty = false;
			
			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = _skeletonPose.jointPoses;
			var basePoses : Vector.<JointPose> = _baseInput.getSkeletonPose(skeleton).jointPoses;
			var diffPoses : Vector.<JointPose> = _differenceInput.getSkeletonPose(skeleton).jointPoses;
			var base : JointPose, diff : JointPose;
			var basePos : Vector3D, diffPos : Vector3D;
			var tr : Vector3D;
			var numJoints : uint = skeleton.numJoints;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;

			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				base = basePoses[i];
				diff = diffPoses[i];
				basePos = base.translation;
				diffPos = diff.translation;

				_tempQuat.multiply(diff.orientation, base.orientation);
				endPose.orientation.lerp(base.orientation, _tempQuat, _blendWeight);

				tr = endPose.translation;
				tr.x = basePos.x + _blendWeight*diffPos.x;
				tr.y = basePos.y + _blendWeight*diffPos.y;
				tr.z = basePos.z + _blendWeight*diffPos.z;
			}
		}
	}
}
