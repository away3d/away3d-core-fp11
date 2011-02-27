package away3d.animators.skeleton
{
	/**
	 * Joint represents a joint in a Skeleton.
	 *
	 * @see away3d.core.animation.skeleton.Skeleton
	 */
	public class Joint
	{
		/**
		 * The parent joint's index
		 */
		public var parentIndex : int = -1;

		/**
		 * The name of the joint
		 */
		public var name : String;

		/**
		 * The inverse bind pose matrix, as raw data, used to transform vertices to bind joint space, so it can be transformed using the target joint matrix.
		 */
		public var inverseBindPose : Vector.<Number>;

		/**
		 * Creates a new Joint object
		 */
		public function Joint()
		{
		}
	}
}