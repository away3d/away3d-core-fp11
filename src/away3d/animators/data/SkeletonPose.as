package away3d.animators.data
{
	import away3d.library.assets.*;
	
	/**
	 * A collection of pose objects, determining the pose for an entire skeleton.
	 * The <code>jointPoses</code> vector object corresponds to a skeleton's <code>joints</code> vector object, however, there is no
	 * reference to a skeleton's instance, since several skeletons can be influenced by the same pose (eg: animation
	 * clips are added to any animator with a valid skeleton)
	 * 
	 * @see away3d.animators.data.Skeleton
	 * @see away3d.animators.data.JointPose
	 */
	public class SkeletonPose extends NamedAssetBase implements IAsset
	{
		/**
		 * A flat list of pose objects that comprise the skeleton pose. The pose indices correspond to the target skeleton's joint indices.
		 * 
		 * @see away3d.animators.data.Skeleton#joints
		 */
		public var jointPoses : Vector.<JointPose>;
		
		/**
		 * The total number of joint poses in the skeleton pose.
		 */
		public function get numJointPoses() : uint
		{
			return jointPoses.length;
		}
		
		/**
		 * Creates a new <code>SkeletonPose</code> object.
		 */
		public function SkeletonPose()
		{
			jointPoses = new Vector.<JointPose>();
		}
		
		/**
		 * @inheritDoc
		 */
		public function get assetType() : String
		{
			return AssetType.SKELETON_POSE;
		}
		
		/**
		 * Returns the joint pose object with the given joint name, otherwise returns a null object.
		 * 
		 * @param jointName The name of the joint object whose pose is to be found.
		 * @return The pose object with the given joint name.
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
		 * Returns the pose index, given the joint name. -1 is returned if the joint name is not found in the pose.
		 * 
		 * @param The name of the joint object whose pose is to be found.
		 * @return The index of the pose object in the jointPoses vector. 
		 * 
		 * @see #jointPoses
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
		 * Creates a copy of the <code>SkeletonPose</code> object, with a dulpicate of its component joint poses.
		 * 
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