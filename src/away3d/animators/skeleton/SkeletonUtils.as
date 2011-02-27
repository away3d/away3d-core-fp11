/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{
	import away3d.arcane;

	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;
	import away3d.animators.data.SkeletonAnimationSequence;

	use namespace arcane;

	public class SkeletonUtils
	{
		public static function generateDifferenceClip(source : SkeletonAnimationSequence, referencePose : SkeletonPose) : SkeletonAnimationSequence
		{
			var diff : SkeletonAnimationSequence = new SkeletonAnimationSequence(source.name, true);
			var numFrames : uint = source._frames.length;

			for (var i : uint = 0; i < numFrames; ++i)
				diff.addFrame(generateDifferencePose(source._frames[i], referencePose), source._durations[i]);

			return diff;
		}

		public static function generateDifferencePose(source : SkeletonPose, reference : SkeletonPose) : SkeletonPose
		{
			var numJoints : uint = source.jointPoses.length;
			var diff : SkeletonPose = new SkeletonPose(numJoints);
			var srcPose : JointPose;
			var refPose : JointPose;
			var diffPose : JointPose;
			var mtx : Matrix3D = new Matrix3D();
			var tempMtx : Matrix3D = new Matrix3D();
			var vec : Vector.<Vector3D>;

			for (var i : int = 0; i < numJoints; ++i) {
				srcPose = source.jointPoses[i];
				refPose = reference.jointPoses[i];
				diffPose = diff.jointPoses[i];

				refPose.toMatrix3D(mtx);
				mtx.invert();
				mtx.append(srcPose.toMatrix3D(tempMtx));
				vec = mtx.decompose(Orientation3D.QUATERNION);
				diffPose.translation.copyFrom(vec[0]);
				diffPose.orientation.x = vec[1].x;
				diffPose.orientation.y = vec[1].y;
				diffPose.orientation.z = vec[1].z;
				diffPose.orientation.w = vec[1].w;
			}

			return diff;
		}
	}
}
