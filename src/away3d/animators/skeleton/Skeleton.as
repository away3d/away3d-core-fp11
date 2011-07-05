package away3d.animators.skeleton
{
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;

	/**
	 * A Skeleton object is a hierarchical grouping of Joint objects that can be used for skeletal animation.
	 *
	 * @see away3d.core.animation.skeleton.Joint
	 */
	public class Skeleton extends NamedAssetBase implements IAsset
	{
		/**
		 * A flat list of Joint objects that comprise the skeleton. Every joint except for the root has a parentIndex
		 * property that is an index into this list.
		 * A child Joint should always have a higher index than its parent.
		 */
		public var joints : Vector.<SkeletonJoint>;

		/**
		 * Creates a new Skeleton object
		 */
		public function Skeleton()
		{
			// in the long run, it might be a better idea to not store Joint objects, but keep all data in Vectors, that we can upload easily?
			joints = new Vector.<SkeletonJoint>();
		}

		/**
		 * Returns the SkeletonJoint, given the joint name.
		 * @param jointName is the name of the SkeletonJoint to be found.
		 * @return SkeletonJoint 
		 */
		public function jointFromName(jointName:String):SkeletonJoint
		{
			var jointIndex:int = jointIndexFromName(jointName);
			if (jointIndex != -1)
			{
				return joints[jointIndex];
			}
			else
			{
				return null;
			}
		}

		/**
		 * Returns the joint index, given the joint name. -1 is returned if joint name not found.
		 * @param jointName is the name of the SkeletonJoint to be found.
		 * @return jointIndex 
		 */
		public function jointIndexFromName(jointName:String):int
		{
			// this function is implemented as a linear search, rather than a possibly
			// more optimal method (Dictionary lookup, for example) because:
			// a) it is assumed that it will be called once for each joint
			// b) it is assumed that it will be called only during load, and not during main loop
			// c) maintaining a dictionary (for safety) would dictate an interface to access SkeletonJoints,
			//    rather than direct array access.  this would be sub-optimal.
			var jointIndex:int;
			for each (var joint:SkeletonJoint in joints)
			{
				if (joint.name == jointName)
				{
					return jointIndex;
				}
				jointIndex++;
			}

			return -1;
		}

		/**
		 * The amount of joints in the Skeleton
		 */
		public function get numJoints() : uint
		{
			return joints.length;
		}
		
		
		public function get assetType() : String
		{
			return AssetType.SKELETON;
		}
	}
}