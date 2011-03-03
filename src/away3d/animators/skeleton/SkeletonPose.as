package away3d.animators.skeleton
{
	import away3d.core.math.Quaternion;

	import flash.geom.Vector3D;

	/**
	 * A SkeletonPose is a collection of JointPose objects, determining the pose for an entire skeleton.
	 * A SkeletonPose and JointPose combination corresponds to a Skeleton and Joint combination. However, there is no
	 * reference to a Skeleton instance, since several skeletons could be influenced by the same pose (fe: animation
	 * sequences that can apply to any target with a valid skeleton)
	 */
	public class SkeletonPose
	{
		/**
		 * The joint poses for the skeleton. The JointPoses indices correspond to the target skeleton's joints.
		 */
		public var jointPoses : Vector.<JointPose>;
		private var _numJoints : uint;

		/**
		 * Creates a new SkeletonPose object.
		 * @param numJoints The amount of joint in the target skeleton.
		 */
		public function SkeletonPose(numJoints : uint)
		{
			_numJoints = numJoints;
			jointPoses = new Vector.<JointPose>(_numJoints, true);
			for (var i : uint = 0; i < _numJoints; ++i) jointPoses[i] = new JointPose();
		}

		/**
		 * Converts a local hierarchical skeleton pose to a global pose
		 * @param targetPose The SkeletonPose object that will contain the global pose.
		 * @param skeleton The skeleton containing the joints, and as such, the hierarchical data to transform to global poses.
		 */
		public function toGlobalPose(targetPose : SkeletonPose, skeleton : Skeleton) : void
		{
			var globalPoses : Vector.<JointPose> = targetPose.jointPoses;
			var globalJointPose : JointPose;
			var joints : Vector.<SkeletonJoint> = skeleton.joints;
			var len : uint = _numJoints;
			var parentIndex : int;
			var joint : SkeletonJoint;
			var parentPose : JointPose;
			var pose : JointPose;
			var or : Quaternion;
			var tr : Vector3D;
			var t : Vector3D;
			var q : Quaternion;

			var x1 : Number, y1 : Number, z1 : Number, w1 : Number;
			var x2 : Number, y2 : Number, z2 : Number, w2 : Number;
			var x3 : Number, y3 : Number, z3 : Number;

			for (var i : uint = 0; i < len; ++i) {
				globalJointPose = globalPoses[i];
				joint = joints[i];
				parentIndex = joint.parentIndex;
				pose = jointPoses[i];

				q = globalJointPose.orientation;
				t = globalJointPose.translation;

				if (parentIndex < 0) {
					tr = pose.translation;
					or = pose.orientation;
					q.x = or.x;	q.y = or.y;	q.z = or.z;	q.w = or.w;
					t.x = tr.x;	t.y = tr.y;	t.z = tr.z;
				}
				else {
					// append parent pose
					parentPose = globalPoses[parentIndex];

					// rotate point
					or = parentPose.orientation;
					tr = pose.translation;
					x2 = or.x; y2 = or.y; z2 = or.z; w2 = or.w;
					x3 = tr.x; y3 = tr.y; z3 = tr.z;

					w1 = -x2*x3 - y2*y3 - z2*z3;
					x1 = w2*x3 + y2*z3 - z2*y3;
					y1 = w2*y3 - x2*z3 + z2*x3;
					z1 = w2*z3 + x2*y3 - y2*x3;

					// append parent translation
					tr = parentPose.translation;
					t.x = -w1*x2 + x1*w2 - y1*z2 + z1*y2 + tr.x;
					t.y = -w1*y2 + x1*z2 + y1*w2 - z1*x2 + tr.y;
					t.z = -w1*z2 - x1*y2 + y1*x2 + z1*w2 + tr.z;

					// append parent orientation
					x1 = or.x;	y1 = or.y;	z1 = or.z;	w1 = or.w;
					or = pose.orientation;
					x2 = or.x;	y2 = or.y;	z2 = or.z;	w2 = or.w;

					q.w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2;
					q.x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2;
					q.y = w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2;
					q.z = w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2;
				}
			}
		}
	}
}