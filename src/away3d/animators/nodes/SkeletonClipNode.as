package away3d.animators.nodes
{
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.JointPose;
	import flash.geom.Vector3D;
	import away3d.animators.skeleton.SkeletonPose;
	import away3d.animators.nodes.SkeletonNodeBase;

	/**
	 * @author robbateman
	 */
	public class SkeletonClipNode extends SkeletonNodeBase
	{
		private var _timeDir:Number;
		private var _totalDuration : uint = 0;
		private var _totalDelta : Vector3D = new Vector3D();
		private var _delta : Vector3D = new Vector3D();
		private var _frames : Vector.<SkeletonPose> = new Vector.<SkeletonPose>();
		private var _framesDirty : Boolean;
		private var _numFrames : uint = 0;
		private var _lastFrame : uint;
		private var _currentFrame : uint;
		private var _nextFrame : uint;
		private var _rootPos : Vector3D = new Vector3D();
		private var _durations : Vector.<uint> = new Vector.<uint>();
		private var _fixedFrameRate:Boolean = true;
		private var _currentPose : SkeletonPose;
		private var _nextPose : SkeletonPose;
		private var _blendWeight : Number;
		
		/**
		 * 
		 */
		public var highQuality:Boolean = false;
		private var _old:uint;
		
		/**
		 * 
		 */
		public function get currentPose() : SkeletonPose
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentPose;
		}
		
		/**
		 * 
		 */
		public function get nextPose() : SkeletonPose
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextPose;
		}
		
		
		public function get blendWeight() : Number
		{
			if (_framesDirty)
				updateFrames();
			
			return _blendWeight;
		}
		
		public function SkeletonClipNode()
		{
		}
		
		public function addFrame(skeletonPose : SkeletonPose, duration : uint) : void
		{
			if (_numFrames) {
				_totalDuration += _durations[_lastFrame];
				var p1 : Vector3D = _frames[_lastFrame].jointPoses[0].translation;
				var p2 : Vector3D = skeletonPose.jointPoses[0].translation;
				_delta.x = p2.x - p1.x;
				_delta.y = p2.y - p1.y;
				_delta.z = p2.z - p1.z;
				_totalDelta.x += _delta.x;
				_totalDelta.y += _delta.y;
				_totalDelta.z += _delta.z;
			}
			_frames.push(skeletonPose);
			_durations.push(duration);
			
			_numFrames = _durations.length;
			_lastFrame = _numFrames - 1;
			
		}
		
		override protected function updateTime(time:Number):void
		{
			_timeDir = time - _time;
			
			super.updateTime(time);
			
			_framesDirty = true;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function updateSkeletonPose(skeleton:Skeleton) : void
		{
			_skeletonPoseDirty = false;
			
			if (!_totalDuration)
				return;
			
			if (_framesDirty)
				updateFrames();

			var currentPose : Vector.<JointPose> = _currentPose.jointPoses;
			var nextPose : Vector.<JointPose> = _nextPose.jointPoses;
			var numJoints : uint = skeleton.numJoints;
			var p1 : Vector3D, p2 : Vector3D;
			var pose1 : JointPose, pose2 : JointPose;
			var endPoses : Vector.<JointPose> = _skeletonPose.jointPoses;
			var endPose : JointPose;
			var tr : Vector3D;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;

			if ((numJoints != currentPose.length) || (numJoints != nextPose.length))
				throw new Error("joint counts don't match!");

			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				pose1 = currentPose[i];
				pose2 = nextPose[i];
				p1 = pose1.translation; p2 = pose2.translation;

				if (highQuality)
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
		override protected function updateRootDelta() : void
		{
			if (_framesDirty)
				updateFrames();

			var p1 : Vector3D = _frames[_currentFrame].jointPoses[0].translation,
				p2 : Vector3D = _nextPose.jointPoses[0].translation;
				
			if ((_timeDir > 0 && _nextFrame > _old) || (_timeDir < 0 && _currentFrame < _old)) {
			}
			// jumping back, need to reset position
			else {
				_rootPos.x -= _totalDelta.x;
				_rootPos.y -= _totalDelta.y;
				_rootPos.z -= _totalDelta.z;
			}
			trace(_rootPos)
			var dx : Number = _rootPos.x;
			var dy : Number = _rootPos.y;
			var dz : Number = _rootPos.z;
			_rootPos.x = p1.x + _blendWeight*(p2.x - p1.x);
			_rootPos.y = p1.y + _blendWeight*(p2.y - p1.y);
			_rootPos.z = p1.z + _blendWeight*(p2.z - p1.z);
			_rootDelta.x = _rootPos.x - dx;
			_rootDelta.y = _rootPos.y - dy;
			_rootDelta.z = _rootPos.z - dz;
			_old = _timeDir > 0? _currentFrame : _nextFrame;
		}

		private function updateFrames() : void
		{
			_framesDirty = false;
			
			var dur : uint = 0, frameTime : uint;
			var time : Number = _time;
			
			if ((time > _totalDuration || time < 0) && _looping) {
				time %= _totalDuration;
				if (time < 0) time += _totalDuration;
			}
			
			if (!_looping && time > _totalDuration) {
				//_activeSequence.notifyPlaybackComplete();
				_currentFrame = _lastFrame;
				_nextFrame = _lastFrame;
				_blendWeight = 0;
			}
			else if (_fixedFrameRate) {
				var t : Number = time/_totalDuration * _lastFrame;
				_currentFrame = t;
				_blendWeight = t - _currentFrame;
				_nextFrame = _currentFrame + 1;
			}
			else {
				_currentFrame = 0;
				_nextFrame = 0;
				do {
					frameTime = dur;
					dur += _durations[_nextFrame];
					_currentFrame = _nextFrame++;
				} while (time > dur);
				
				if (_currentFrame >= _lastFrame) {
					_currentFrame = 0;
					_nextFrame = 1;
				}
				
				_blendWeight = (time - frameTime) / _durations[_currentFrame];
			}
			
			_currentPose = _frames[_currentFrame || _lastFrame];
			_nextPose = _frames[_nextFrame];
		}
	}
}
