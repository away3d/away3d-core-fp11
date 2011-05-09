/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{

	import flash.geom.Vector3D;

	public class SkeletonBinaryLERPNode extends SkeletonTreeNode
	{
		public var inputA : SkeletonTreeNode;
		public var inputB : SkeletonTreeNode;
		private var _blendWeight : Number;

		public function SkeletonBinaryLERPNode()
		{
			super();
		}

		override public function set time(value : Number) : void
		{
			inputA.time = value;
			inputB.time = value;
			super.time = value;
		}

		override public function set direction(value : Number) : void
		{
			inputA.direction = value;
			inputB.direction = value;
			super.direction = value;
		}

		public function get blendWeight() : Number
		{
			return _blendWeight;
		}

		public function set blendWeight(value : Number) : void
		{
			_blendWeight = value;
			_duration = inputA.duration + _blendWeight*(inputB.duration - inputB.duration);
		}

// todo: return whether or not update was performed
		override public function updatePose(skeleton : Skeleton) : void
		{
			// todo: should only update if blendWeight dirty, or if either child returns false
			inputA.updatePose(skeleton);
			inputB.updatePose(skeleton);

			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = skeletonPose.jointPoses;
			var poses1 : Vector.<JointPose> = inputA.skeletonPose.jointPoses;
			var poses2 : Vector.<JointPose> = inputB.skeletonPose.jointPoses;
			var pose1 : JointPose, pose2 : JointPose;
			var p1 : Vector3D, p2 : Vector3D;
			var tr : Vector3D;
			var numJoints : uint = skeleton.numJoints;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;

			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				pose1 = poses1[i];
				pose2 = poses2[i];
				p1 = pose1.translation; p2 = pose2.translation;

				endPose.orientation.lerp(pose1.orientation, pose2.orientation, blendWeight);

				tr = endPose.translation;
				tr.x = p1.x + blendWeight*(p2.x - p1.x);
				tr.y = p1.y + blendWeight*(p2.y - p1.y);
				tr.z = p1.z + blendWeight*(p2.z - p1.z);
			}
		}

		override public function updatePositionData() : void
		{
			var deltA : Vector3D = inputA.rootDelta;
			var deltB : Vector3D = inputB.rootDelta;
			rootDelta.x = deltA.x + blendWeight*(deltB.x - deltA.x);
			rootDelta.y = deltA.y + blendWeight*(deltB.y - deltA.y);
			rootDelta.z = deltA.z + blendWeight*(deltB.z - deltA.z);
		}
	}
}
