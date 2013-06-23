package away3d.animators.states
{
	import away3d.animators.IAnimator;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	
	import flash.geom.*;
	
	/**
	 *
	 */
	public class SkeletonBinaryLERPState extends AnimationStateBase implements ISkeletonAnimationState
	{
		private var _blendWeight:Number = 0;
		private var _skeletonAnimationNode:SkeletonBinaryLERPNode;
		private var _skeletonPose:SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty:Boolean = true;
		private var _inputA:ISkeletonAnimationState;
		private var _inputB:ISkeletonAnimationState;
		
		/**
		 * Defines a fractional value between 0 and 1 representing the blending ratio between inputA (0) and inputB (1),
		 * used to produce the skeleton pose output.
		 *
		 * @see inputA
		 * @see inputB
		 */
		public function get blendWeight():Number
		{
			return _blendWeight;
		}
		
		public function set blendWeight(value:Number):void
		{
			_blendWeight = value;
			
			_positionDeltaDirty = true;
			_skeletonPoseDirty = true;
		}
		
		function SkeletonBinaryLERPState(animator:IAnimator, skeletonAnimationNode:SkeletonBinaryLERPNode)
		{
			super(animator, skeletonAnimationNode);
			
			_skeletonAnimationNode = skeletonAnimationNode;
			
			_inputA = animator.getAnimationState(_skeletonAnimationNode.inputA) as ISkeletonAnimationState;
			_inputB = animator.getAnimationState(_skeletonAnimationNode.inputB) as ISkeletonAnimationState;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function phase(value:Number):void
		{
			_skeletonPoseDirty = true;
			
			_positionDeltaDirty = true;
			
			_inputA.phase(value);
			_inputB.phase(value);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time:int):void
		{
			_skeletonPoseDirty = true;
			
			_inputA.update(time);
			_inputB.update(time);
			
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
		override protected function updatePositionDelta():void
		{
			_positionDeltaDirty = false;
			
			var deltA:Vector3D = _inputA.positionDelta;
			var deltB:Vector3D = _inputB.positionDelta;
			
			_rootDelta.x = deltA.x + _blendWeight*(deltB.x - deltA.x);
			_rootDelta.y = deltA.y + _blendWeight*(deltB.y - deltA.y);
			_rootDelta.z = deltA.z + _blendWeight*(deltB.z - deltA.z);
		}
		
		/**
		 * Updates the output skeleton pose of the node based on the blendWeight value between input nodes.
		 *
		 * @param skeleton The skeleton used by the animator requesting the ouput pose.
		 */
		private function updateSkeletonPose(skeleton:Skeleton):void
		{
			_skeletonPoseDirty = false;
			
			var endPose:JointPose;
			var endPoses:Vector.<JointPose> = _skeletonPose.jointPoses;
			var poses1:Vector.<JointPose> = _inputA.getSkeletonPose(skeleton).jointPoses;
			var poses2:Vector.<JointPose> = _inputB.getSkeletonPose(skeleton).jointPoses;
			var pose1:JointPose, pose2:JointPose;
			var p1:Vector3D, p2:Vector3D;
			var tr:Vector3D;
			var numJoints:uint = skeleton.numJoints;
			
			// :s
			if (endPoses.length != numJoints)
				endPoses.length = numJoints;
			
			for (var i:uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				pose1 = poses1[i];
				pose2 = poses2[i];
				p1 = pose1.translation;
				p2 = pose2.translation;
				
				endPose.orientation.lerp(pose1.orientation, pose2.orientation, _blendWeight);
				
				tr = endPose.translation;
				tr.x = p1.x + _blendWeight*(p2.x - p1.x);
				tr.y = p1.y + _blendWeight*(p2.y - p1.y);
				tr.z = p1.z + _blendWeight*(p2.z - p1.z);
			}
		}
	}
}
