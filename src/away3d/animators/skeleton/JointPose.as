package away3d.animators.skeleton
{
	import away3d.core.math.Quaternion;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * JointPose contains transformation data for a skeleton joint, used for skeleton animation.
	 *
	 * @see away3d.core.animation.skeleton.Skeleton
	 * @see away3d.core.animation.skeleton.Joint
	 *
	 * todo: support (uniform) scale
	 */
	public class JointPose
	{
		/**
		 * The name of the joint this pose is for
		 */
		public var name : String; // intention is that this should be used only at load time, not in the main loop
		
		/**
		 * The rotation of the joint stored as a quaternion
		 */
		public var orientation : Quaternion = new Quaternion();

		/**
		 * The translation of the joint
		 */
		public var translation : Vector3D = new Vector3D();

		/**
		 * Converts the transformation to a Matrix3D representation.
		 * @param target An optional target matrix to store the transformation. If not provided, it will create a new instance.
		 * @return A Matrix3D object containing the transformation.
		 */
		public function toMatrix3D(target : Matrix3D = null) : Matrix3D
		{
			target ||= new Matrix3D();
			orientation.toMatrix3D(target);
			target.appendTranslation(translation.x, translation.y, translation.z);
			return target;
		}

		/**
		 * Copies the transformation data from a different JointPose object
		 * @param pose the source JointPose object to copy from
		 */
		public function copyFrom(pose : JointPose) : void
		{
			var or : Quaternion = pose.orientation;
			var tr : Vector3D = pose.translation;
			orientation.x = or.x;
			orientation.y = or.y;
			orientation.z = or.z;
			orientation.w = or.w;
			translation.x = tr.x;
			translation.y = tr.y;
			translation.z = tr.z;
		}


		public function toString() : String
		{
			return "JOINT POSE: Orientation: "+orientation.toString()+" - Translation: "+translation.toString();
		}
	}
}
