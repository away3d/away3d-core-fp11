package away3d.animators.data
{
	/**
	 * A value obect representing a single joint in a skeleton object.
	 *
	 * @see away3d.animators.data.Skeleton
	 */
	public class SkeletonJoint
	{
		/**
		 * The index of the parent joint in the skeleton's joints vector.
		 * 
		 * @see away3d.animators.data.Skeleton#joints
		 */
		public var parentIndex : int = -1;

		/**
		 * The name of the joint
		 */
		public var name : String; // intention is that this should be used only at load time, not in the main loop

		/**
		 * The inverse bind pose matrix, as raw data, used to transform vertices to bind joint space in preparation for transformation using the joint matrix.
		 */
		public var inverseBindPose : Vector.<Number>;

		/**
		 * Creates a new <code>SkeletonJoint</code> object
		 */
		public function SkeletonJoint()
		{
		}
	}
}