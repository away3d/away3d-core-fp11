/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{
	import away3d.arcane;

	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * SkeletonTimelineClipNode represents a node in a skeleton tree containing a blending clip for which the keyframes
	 * are laid out on a timeline. As such, the pose is determined by the time property.
	 */
	public class SkeletonTimelineClipNode extends SkeletonClipNodeBase
	{
		private var _timeDir : Number;
		private var _frame1 : int;
		private var _frame2 : int;
		private var _blendWeight : Number = 0;
		private var _framesInvalid : Boolean;
		private var _resetTime : Boolean;
		private var _startTime : Number = 0;
		private var _lastFrame : int;

		/**
		 * Creates a new SkeletonTimelineClipNode object.
		 * @param numJoints The amount of joints in the target skeleton.
		 */
		public function SkeletonTimelineClipNode(numJoints : uint)
		{
			super(numJoints);
		}

		public function reset() : void
		{
			if (!clip.looping)
				_resetTime = true;
		}

		override public function set time(value : Number) : void
		{
			if (_resetTime) {
				_startTime = value;
				_resetTime = false;
			}
			if (_time == value) return;
			_framesInvalid = true;
			_timeDir = value - _time;
			super.time = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function updatePose(skeleton : Skeleton) : void
		{
			if (_clip.duration == 0) return;
			if (_framesInvalid) updateFrames(_time-_startTime);

			var poses1 : Vector.<JointPose> = clip._frames[_frame1].jointPoses;
			var poses2 : Vector.<JointPose> = clip._frames[_frame2].jointPoses;
			var numJoints : uint = poses1.length;
			var p1 : Vector3D, p2 : Vector3D;
			var pose1 : JointPose, pose2 : JointPose;
			var endPoses : Vector.<JointPose> = skeletonPose.jointPoses;
			var endPose : JointPose;
			var tr : Vector3D;

			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i];
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
			if (_framesInvalid) updateFrames(_time-_startTime);

			var p1 : Vector3D = clip._frames[_frame1].jointPoses[0].translation,
				p2 : Vector3D = clip._frames[_frame2].jointPoses[0].translation;

			if ((_timeDir > 0 && _frame2 > _lastFrame) || (_timeDir < 0 && _frame1 < _lastFrame)) {
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
			// jumping back, need to reset position
			else {
				_rootPos.x = p1.x + _blendWeight*(p2.x - p1.x);
				_rootPos.y = p1.y + _blendWeight*(p2.y - p1.y);
				_rootPos.z = p1.z + _blendWeight*(p2.z - p1.z);
				rootDelta.x = 0;
				rootDelta.y = 0;
				rootDelta.z = 0;
			}
			_lastFrame = _timeDir > 0? _frame1 : _frame2;
		}

		private function updateFrames(time : Number) : void
		{
			var lastFrame : uint;
			var dur : uint, frameTime : uint;
			var frames : Vector.<SkeletonPose> = _clip._frames;
			var durations : Vector.<uint> = _clip._durations;
			var duration : uint = _clip._totalDuration;
			var looping : Boolean = _clip.looping;
			var numFrames : uint = frames.length;

			if (numFrames == 0) return;

			lastFrame = numFrames - 1;
			if (looping) {
				if (time > 1) time -= int(time);
				if (time < 0) time -= int(time)-1;

				if (_clip._fixedFrameRate) {
					time *= lastFrame;
					_frame1 = time;
					_blendWeight = time - _frame1;
					_frame2 = _frame1 + 1;
				}
				else {
					do {
						frameTime = dur;
						dur += durations[_frame1];
						_frame1 = _frame2;
						if (++_frame2 == numFrames) {
							_frame1 = 0;
							_frame2 = 1;
						}
					} while (time > dur);

					_blendWeight = (time - frameTime) / durations[_frame1];
				}
			}
			else {
				if (time >= 1) {
					clip.notifyPlaybackComplete();
					//if the animation has different frame count, set the frame to the lastframe return an error
					//_frame1 = lastFrame;
					//_frame2 = lastFrame;
					_frame1 = 0;
					_frame2 = 0;
					_blendWeight = 0;
				}
				else if (_clip._fixedFrameRate) {
					time *= lastFrame;
					_frame1 = time;
					_frame2 = _frame1 + 1;
					if (_frame2 == numFrames) _frame2 = _frame1;
					_blendWeight = time - _frame1;
				}
				else {
					time *= duration - durations[lastFrame];
					do {
						frameTime = dur;
						dur += durations[_frame1];
						_frame1 = _frame2++;
					} while (time > dur);

					if (_frame2 == numFrames) {
						_frame2 = _frame1;
						_blendWeight = 0;
					}
					else
						_blendWeight = (time - frameTime) / durations[_frame1];
				}
			}

			_framesInvalid = false;
		}
	}
}
