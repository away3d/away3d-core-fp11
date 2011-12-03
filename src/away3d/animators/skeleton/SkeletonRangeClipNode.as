/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{
	import away3d.arcane;

	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * SkeletonRangeClipNode represents a node in a skeleton tree containing a blending clip in which the keyframes
	 * represent poses along a range of values
	 */
	public class SkeletonRangeClipNode extends SkeletonClipNodeBase
	{
		/**
		 * The animation clip.
		 */
		private var _frame1 : int;
		private var _frame2 : int;
		private var _blendWeight : Number = .5;
		private var _framesInvalid : Boolean;
		private var _phase : Number;

		/**
		 * Creates a new SkeletonPhaseClipNode object.
		 * @param numJoints The amount of joints in the target skeleton.
		 */
		public function SkeletonRangeClipNode()
		{
			super();
			_rootPos = new Vector3D();
		}

		/**
		 * The normalized ratio of the state within the range. For example, for a clip that defines left, center and
		 * right aiming poses, 0 would be entirely left, 1 entirely right, and .5 the center.
		 */
		public function get phase() : Number
		{
			return _phase;
		}

		public function set phase(value : Number) : void
		{
			if (_phase == value) return;
			_framesInvalid = true;
			_phase = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function updatePose(skeleton : Skeleton) : void
		{
			// TODO: not used
			skeleton  = skeleton;			
			if (_clip.duration == 0) return;
			if (_framesInvalid) updateFrames(_phase);

			var poses1 : Vector.<JointPose> = clip._frames[_frame1].jointPoses;
			var poses2 : Vector.<JointPose> = clip._frames[_frame2].jointPoses;
			var numJoints : uint = poses1.length;
			var p1 : Vector3D, p2 : Vector3D;
			var pose1 : JointPose, pose2 : JointPose;
			var endPoses : Vector.<JointPose> = skeletonPose.jointPoses;
			var endPose : JointPose;
			var tr : Vector3D;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;

			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				pose1 = poses1[i];
				pose2 = poses2[i];
				p1 = pose1.translation; p2 = pose2.translation;

				if (_highQuality)
					endPose.orientation.slerp(pose1.orientation, pose2.orientation, _blendWeight);
				else
					endPose.orientation.lerp(pose1.orientation, pose2.orientation, _blendWeight);

				if (i > 0) {
					tr = endPose.translation;
					tr.x = p1.x + _blendWeight*(p2.x - p1.x);
					tr.y = p1.y + _blendWeight*(p2.y - p1.y);
					tr.z = p1.z + _blendWeight*(p2.z - p1.z);
				}
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function updatePositionData() : void
		{
			if (_framesInvalid) updateFrames(_phase);

			var p1 : Vector3D = clip._frames[_frame1].jointPoses[0].translation,
				p2 : Vector3D = clip._frames[_frame2].jointPoses[0].translation;

			var dx : Number = _rootPos.x;
			var dy : Number = _rootPos.y;
			var dz : Number = _rootPos.z;
			_rootPos.x = p1.x + _blendWeight*(p2.x - p1.x);
			_rootPos.y = p1.y + _blendWeight*(p2.y - p1.y);
			_rootPos.z = p1.z + _blendWeight*(p2.z - p1.z);
			rootDelta.x = _rootPos.x - dx;
			rootDelta.y = _rootPos.y - dy;
			rootDelta.z = _rootPos.z - dz;
		}

		private function updateFrames(phase : Number) : void
		{
			var lastFrame : uint;
			var dur : uint, frameTime : uint;
			var frames : Vector.<SkeletonPose> = _clip._frames;
			var durations : Vector.<uint> = _clip._durations;
			var duration : uint = _clip._totalDuration;
			var numFrames : uint = frames.length;

			if (numFrames == 0) return;

			if (phase >= 1) {
				lastFrame = numFrames - 1;
				_frame1 = lastFrame;
				_frame2 = lastFrame;
				_blendWeight = 0;
			}
			else if (phase < 0) {
				_frame1 = 0;
				_frame2 = 0;
				_blendWeight = 0;
			}
			else if (_clip._fixedFrameRate) {
				phase *= numFrames-1;
				_frame1 = phase;
				_frame2 = _frame1 + 1;
				if (_frame2 == numFrames) _frame2 = _frame1;
				_blendWeight = phase - _frame1;
			}
			else {
				phase *= duration - durations[numFrames - 1];
				do {
					frameTime = dur;
					dur += durations[_frame1];
					_frame1 = _frame2++;
				} while (phase > dur);

				if (_frame2 == numFrames) {
					_frame2 = _frame1;
					_blendWeight = 0;
				}
				else
					_blendWeight = (phase - frameTime) / durations[_frame1];
			}

			_framesInvalid = false;
		}
	}
}
