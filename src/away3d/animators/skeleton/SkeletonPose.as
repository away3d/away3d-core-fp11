package away3d.animators.skeleton
{
	import away3d.core.math.Quaternion;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;

	import flash.geom.Vector3D;

	/**
	 * A SkeletonPose is a collection of JointPose objects, determining the pose for an entire skeleton.
	 * A SkeletonPose and JointPose combination corresponds to a Skeleton and Joint combination. However, there is no
	 * reference to a Skeleton instance, since several skeletons could be influenced by the same pose (fe: animation
	 * sequences that can apply to any target with a valid skeleton)
	 */
	public class SkeletonPose extends NamedAssetBase implements IAsset
	{
		/**
		 * The joint poses for the skeleton. The JointPoses indices correspond to the target skeleton's joints.
		 */
		public var jointPoses : Vector.<JointPose>;

		/**
		 * Creates a new SkeletonPose object.
		 * @param numJoints The number of joints in the target skeleton.
		 */
		public function SkeletonPose()
		{
			jointPoses = new Vector.<JointPose>();
		}


		public function get assetType() : String
		{
			return AssetType.SKELETON_POSE;
		}

		/**
		 * Returns the JointPose, given the joint name.
		 * @param jointName is the name of the JointPose to be found.
		 * @return JointPose
		 */
		public function jointPoseFromName(jointName : String) : JointPose
		{
			var jointPoseIndex : int = jointPoseIndexFromName(jointName);
			if (jointPoseIndex != -1) {
				return jointPoses[jointPoseIndex];
			}
			else {
				return null;
			}
		}

		/**
		 * Returns the joint index, given the joint name. -1 is returned if joint name not found.
		 * @param jointName is the name of the JointPose to be found.
		 * @return jointIndex
		 */
		public function jointPoseIndexFromName(jointName : String) : int
		{
			// this function is implemented as a linear search, rather than a possibly
			// more optimal method (Dictionary lookup, for example) because:
			// a) it is assumed that it will be called once for each joint
			// b) it is assumed that it will be called only during load, and not during main loop
			// c) maintaining a dictionary (for safety) would dictate an interface to access JointPoses,
			//    rather than direct array access.  this would be sub-optimal.
			var jointPoseIndex : int;
			for each (var jointPose : JointPose in jointPoses) {
				if (jointPose.name == jointName) {
					return jointPoseIndex;
				}
				jointPoseIndex++;
			}

			return -1;
		}

		/**
		 * The amount of joints in the Skeleton
		 */
		public function get numJointPoses() : uint
		{
			return jointPoses.length;
		}

		/**
		 * Clones this SkeletonPose, with all of its component jointPoses.
		 * @return SkeletonPose
		 */
		public function clone() : SkeletonPose
		{
			var clone : SkeletonPose = new SkeletonPose();
			var numJointPoses : uint = this.jointPoses.length;
			for (var i : uint = 0; i < numJointPoses; i++) {
				var cloneJointPose : JointPose = new JointPose();
				var thisJointPose : JointPose = this.jointPoses[i];
				cloneJointPose.name = thisJointPose.name;
				cloneJointPose.copyFrom(thisJointPose);
				clone.jointPoses[i] = cloneJointPose;
			}
			return clone;
		}
		
		/** 
		 * @inheritDoc
		 */
		public function dispose() : void
		{
			jointPoses.length = 0;
		}
	}
}