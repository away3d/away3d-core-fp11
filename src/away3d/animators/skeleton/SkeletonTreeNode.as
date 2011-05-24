/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;

	/**
	 * SkeletonTreeNode provides an abstract base class for nodes in a skeleton blend tree.
	 */
	public class SkeletonTreeNode
	{
		protected var _time : Number = 0;
		protected var _direction : Number = 0;
		protected var _duration : Number = 0;
		public var name : String;
		public var skeletonPose : SkeletonPose;

		public var rootDelta : Vector3D;

		/**
		 * Creates a new SkeletonTreeNode object.
		 * @param numJoints The amount of joint in the target skeleton.
		 */
		public function SkeletonTreeNode()
		{
			rootDelta = new Vector3D();
			skeletonPose = new SkeletonPose();
		}

		/**
		 * The time ratio between 0 and 1.
		 */
		public function get time() : Number
		{
			return _time;
		}

		public function set time(value : Number) : void
		{
			_time = value;
		}

		public function get direction() : Number
		{
			return _direction;
		}

		public function set direction(value : Number) : void
		{
			_direction = value;
		}

		public function get duration() : Number
		{
			return _duration;
		}

		/**
		 * Updates the node's skeleton pose
		 */
		public function updatePose(skeleton : Skeleton) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Updates the s root delta position and bounds
		 *
		 * todo: support bounds
		 */
		public function updatePositionData() : void
		{
			throw new AbstractMethodError();
		}
	}
}
