package away3d.animators.skeleton
{




	/**
	 * A Skeleton object is a hierarchical grouping of Joint objects that can be used for skeletal animation.
	 *
	 * @see away3d.core.animation.skeleton.Joint
	 */
	public class Skeleton
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
		 * The amount of joints in the Skeleton
		 */
		public function get numJoints() : uint
		{
			return joints.length;
		}
	}
}