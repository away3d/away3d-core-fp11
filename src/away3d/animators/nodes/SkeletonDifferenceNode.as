package away3d.animators.nodes
{
	import away3d.animators.data.*;
	import away3d.core.math.*;
	
	import flash.geom.*;
	
	/**
	 * A skeleton animation node that uses a difference input pose with a base input pose to blend a linearly interpolated output of a skeleton pose.
	 */
	public class SkeletonDifferenceNode extends AnimationNodeBase implements ISkeletonAnimationNode
	{
		private var _blendWeight : Number = 0;
		private var _skeletonPose : SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty : Boolean = true;
		private static var _tempQuat : Quaternion = new Quaternion();

		/**
		 * Defines a base input node to use for the blended output.
		 */
		public var baseInput : ISkeletonAnimationNode;
		
		/**
		 * Defines a difference input node to use for the blended output.
		 */
		public var differenceInput : ISkeletonAnimationNode;
		
		/**
		 * Creates a new <code>SkeletonAdditiveNode</code> object.
		 */
		public function SkeletonDifferenceNode()
		{
			super();
		}
		
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
			
			_rootDeltaDirty = true;
			_skeletonPoseDirty = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function reset(time:int):void
		{
			super.reset(time);
			
			baseInput.reset(time);
			differenceInput.reset(time);
		}
		
		/**
		 * Returns the current skeleton pose of the animation node based on the blendWeight value between base input and difference input nodes.
		 * 
		 * @see #baseInput
		 * @see #differenceInput
		 * @see #blendWeight
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
		override protected function updateTime(time : int) : void
		{
			super.updateTime(time);
			
			baseInput.update(time);
			differenceInput.update(time);
			
			_skeletonPoseDirty = true;
		}

		/**
		 * Updates the output skeleton pose of the node based on the blendWeight value between base input and difference input nodes.
		 * 
		 * @param skeleton The skeleton used by the animator requesting the ouput pose. 
		 */
		public function updateSkeletonPose(skeleton : Skeleton) : void
		{
			_skeletonPoseDirty = false;
			
			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = _skeletonPose.jointPoses;
			var basePoses : Vector.<JointPose> = baseInput.getSkeletonPose(skeleton).jointPoses;
			var diffPoses : Vector.<JointPose> = differenceInput.getSkeletonPose(skeleton).jointPoses;
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
		
		/**
		 * @inheritDoc
		 */
		override protected function updateRootDelta() : void
		{
			var deltA : Vector3D = baseInput.rootDelta;
			var deltB : Vector3D = differenceInput.rootDelta;

			_rootDelta.x = deltA.x + _blendWeight*deltB.x;
			_rootDelta.y = deltA.y + _blendWeight*deltB.y;
			_rootDelta.z = deltA.z + _blendWeight*deltB.z;
		}
	}
}
