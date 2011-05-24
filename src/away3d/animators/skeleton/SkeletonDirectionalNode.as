/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{

	import flash.geom.Vector3D;

	public class SkeletonDirectionalNode extends SkeletonTreeNode
	{
		/**
		 * The weights for each joint. The total needs to equal 1.
		 */
		public var forward : SkeletonTreeNode;
		public var backward : SkeletonTreeNode;
		public var left : SkeletonTreeNode;
		public var right : SkeletonTreeNode;
		private var _inputA : SkeletonTreeNode;
		private var _inputB : SkeletonTreeNode;
		private var _blendWeight : Number;
		private var _blendDirty : Boolean;

		public function SkeletonDirectionalNode()
		{
			super();
		}

		override public function set time(value : Number) : void
		{
			forward.time = value;
			backward.time = value;
			left.time = value;
			right.time = value;
			super.time = value;
		}

		// between 0 - 360
		override public function set direction(value : Number) : void
		{
			forward.direction = value;
			backward.direction = value;
			left.direction = value;
			right.direction = value;
			_blendDirty = true;
			super.direction = value;
		}

		override public function updatePose(skeleton : Skeleton) : void
		{
			if (_blendDirty) updateBlend();
			_inputA.updatePose(skeleton);
			_inputB.updatePose(skeleton);

			var durA : Number = _inputA.duration;
			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = skeletonPose.jointPoses;
			var poses1 : Vector.<JointPose> = _inputA.skeletonPose.jointPoses;
			var poses2 : Vector.<JointPose> = _inputB.skeletonPose.jointPoses;
			var pose1 : JointPose, pose2 : JointPose;
			var p1 : Vector3D, p2 : Vector3D;
			var tr : Vector3D;
			var numJoints : uint = skeleton.numJoints;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;

			_duration = durA + _blendWeight*(_inputB.duration - durA);

			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				pose1 = poses1[i];
				pose2 = poses2[i];
				p1 = pose1.translation; p2 = pose2.translation;

				endPose.orientation.lerp(pose1.orientation, pose2.orientation, _blendWeight);

				tr = endPose.translation;
				tr.x = p1.x + _blendWeight*(p2.x - p1.x);
				tr.y = p1.y + _blendWeight*(p2.y - p1.y);
				tr.z = p1.z + _blendWeight*(p2.z - p1.z);
			}
		}

		private function updateBlend() : void
		{
			_blendDirty = false;

			while (_direction < 0) _direction += 360;
			while (_direction >= 360) _direction -= 360;

			if (_direction < 90) {
				_inputA = forward;
				_inputB = right;
				_blendWeight = _direction/90;
			}
			else if (_direction < 180) {
				_inputA = right;
				_inputB = backward;
				_blendWeight = (_direction-90)/90;
			}
			else if (_direction < 270) {
				_inputA = backward;
				_inputB = left;
				_blendWeight = (_direction-180)/90;
			}
			else {
				_inputA = left;
				_inputB = forward;
				_blendWeight = (_direction-270)/90;
			}
		}

		override public function updatePositionData() : void
		{
			if (_blendDirty) updateBlend();
			var deltA : Vector3D = _inputA.rootDelta;
			var deltB : Vector3D = _inputB.rootDelta;
			rootDelta.x = deltA.x + _blendWeight*(deltB.x - deltA.x);
			rootDelta.y = deltA.y + _blendWeight*(deltB.y - deltA.y);
			rootDelta.z = deltA.z + _blendWeight*(deltB.z - deltA.z);
		}
	}
}
