/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{

	import away3d.core.math.Quaternion;

	import flash.geom.Vector3D;

	public class SkeletonAdditiveNode extends SkeletonTreeNode
	{
		public var baseInput : SkeletonTreeNode;
		public var differenceInput : SkeletonTreeNode;
		private var _blendWeight : Number = 0;

		private static var _tempQuat : Quaternion = new Quaternion();

		public function SkeletonAdditiveNode(numJoints : uint)
		{
			super(numJoints);
		}

		override public function get duration() : Number
		{
			return baseInput.duration;
		}

		public function get blendWeight() : Number
		{
			return _blendWeight;
		}

		public function set blendWeight(value : Number) : void
		{
			_blendWeight = value;
			_duration = baseInput.duration;
		}

		override public function set time(value : Number) : void
		{
			baseInput.time = value;
			differenceInput.time = value;
			super.time = value;
		}

		override public function set direction(value : Number) : void
		{
			baseInput.direction = value;
			differenceInput.direction = value;
			super.direction = value;
		}

		// todo: return whether or not update was performed
		override public function updatePose(skeleton : Skeleton) : void
		{
			// todo: should only update if blendWeight dirty, or if either child returns false
			baseInput.updatePose(skeleton);
			differenceInput.updatePose(skeleton);

			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = skeletonPose.jointPoses;
			var basePoses : Vector.<JointPose> = baseInput.skeletonPose.jointPoses;
			var diffPoses : Vector.<JointPose> = differenceInput.skeletonPose.jointPoses;
			var base : JointPose, diff : JointPose;
			var basePos : Vector3D, diffPos : Vector3D;
			var tr : Vector3D;

			for (var i : uint = 0; i < _numJoints; ++i) {
				endPose = endPoses[i];
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

		override public function updatePositionData() : void
		{
			var deltA : Vector3D = baseInput.rootDelta;
			var deltB : Vector3D = differenceInput.rootDelta;

			rootDelta.x = deltA.x + _blendWeight*deltB.x;
			rootDelta.y = deltA.y + _blendWeight*deltB.y;
			rootDelta.z = deltA.z + _blendWeight*deltB.z;
		}
	}
}
