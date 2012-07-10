package away3d.animators.nodes
{
	import away3d.animators.AnimationStateBase;
	import away3d.events.AnimationStateEvent;
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
		private var _totalDelta : Vector3D = new Vector3D();
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
		private var _stitchFinalFrame:Boolean = false;
		private var _stitchDirty:Boolean = true;
		private var _animationStatePlaybackComplete:AnimationStateEvent;
		
		/**
		 * 
		 */
		public var highQuality:Boolean = false;
		
		public function get stitchFinalFrame() : Boolean
		{
			return _stitchFinalFrame;
		}
		
		public function set stitchFinalFrame(value:Boolean):void
		{
			if (_stitchFinalFrame == value)
				return;
			
			_stitchFinalFrame = value;
			
			_stitchDirty = true;
			_framesDirty = true;
		}
		
		public function get frames():Vector.<SkeletonPose>
		{
			return _frames;
		}
		
		public function get durations():Vector.<uint>
		{
			return _durations;
		}
		
		private var _oldFrame:uint;
		
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
		
		override public function reset(time:Number):void
		{
			super.reset(time);
			
			updateRootDelta();	
		}
		
		public function addFrame(skeletonPose : SkeletonPose, duration : uint) : void
		{
			_frames.push(skeletonPose);
			_durations.push(duration);
			
			_numFrames = _durations.length;
			
			_stitchDirty = true;
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
			
			if (_framesDirty)
				updateFrames();

			if (!_totalDuration)
				return;
			
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
			
			var p1 : Vector3D, p2 : Vector3D, p3 : Vector3D;
			
			// jumping back, need to reset position
			if (_nextFrame < _oldFrame) {
				_rootPos.x -= _totalDelta.x;
				_rootPos.y -= _totalDelta.y;
				_rootPos.z -= _totalDelta.z;
			}
			
			var dx : Number = _rootPos.x;
			var dy : Number = _rootPos.y;
			var dz : Number = _rootPos.z;
			
			if (_stitchFinalFrame && _nextFrame == _lastFrame) {
				p1 = _frames[0].jointPoses[0].translation;
				p2 = _frames[1].jointPoses[0].translation;
				p3 = _currentPose.jointPoses[0].translation;
				
				_rootPos.x = p3.x + p1.x + _blendWeight*(p2.x - p1.x);
				_rootPos.y = p3.y + p1.y + _blendWeight*(p2.y - p1.y);
				_rootPos.z = p3.z + p1.z + _blendWeight*(p2.z - p1.z);
			} else {
				p1 = _currentPose.jointPoses[0].translation;
				p2 = _frames[_nextFrame].jointPoses[0].translation; //cover the instances where we wrap the pose but still want the final frame translation values
				_rootPos.x = p1.x + _blendWeight*(p2.x - p1.x);
				_rootPos.y = p1.y + _blendWeight*(p2.y - p1.y);
				_rootPos.z = p1.z + _blendWeight*(p2.z - p1.z);
			}
			
			_rootDelta.x = _rootPos.x - dx;
			_rootDelta.y = _rootPos.y - dy;
			_rootDelta.z = _rootPos.z - dz;
			
			_oldFrame = _nextFrame;
		}
		
		override protected function updateLooping():void
		{
			super.updateLooping();
			
			_stitchDirty = true;
		}
		
		private function updateFrames() : void
		{
			_framesDirty = false;
			
			if (_stitchDirty)
				updateStitch();
			
			var dur : uint = 0, frameTime : uint;
			var time : Number = _time;
			
			if ((time > _totalDuration || time < 0) && _looping) {
				time %= _totalDuration;
				if (time < 0) time += _totalDuration;
			}
			
			if (!_looping && time >= _totalDuration) {
				notifyPlaybackComplete();
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
				
				if (_currentFrame == _lastFrame) {
					_currentFrame = 0;
					_nextFrame = 1;
				}
				
				_blendWeight = (time - frameTime) / _durations[_currentFrame];
			}
			
			_currentPose = _frames[_currentFrame];
			
			if (_looping && _nextFrame >= _lastFrame)
				_nextPose = _frames[0];
			else
				_nextPose = _frames[_nextFrame];
		}
		
		private function updateStitch():void
		{
			_stitchDirty = false;
			
			_lastFrame = (_stitchFinalFrame)? _numFrames : _numFrames - 1;
			
			_totalDuration = 0;
			_totalDelta.x = 0;
			_totalDelta.y = 0;
			_totalDelta.z = 0;
			
			var i:uint = _numFrames - 1;
			var p1 : Vector3D, p2 : Vector3D, delta : Vector3D;
			while (i--) {
				_totalDuration += _durations[i];
				p1 = _frames[i].jointPoses[0].translation;
				p2 = _frames[i+1].jointPoses[0].translation;
				delta = p2.subtract(p1);
				_totalDelta.x += delta.x;
				_totalDelta.y += delta.y;
				_totalDelta.z += delta.z;
			}
			
			if (_stitchFinalFrame || !_looping) {
				_totalDuration += _durations[_numFrames - 1];
				p1 = _frames[0].jointPoses[0].translation;
				p2 = _frames[1].jointPoses[0].translation;
				delta = p2.subtract(p1);
				_totalDelta.x += delta.x;
				_totalDelta.y += delta.y;
				_totalDelta.z += delta.z;
			}
		}
		
		private function notifyPlaybackComplete():void
		{
			dispatchEvent(_animationStatePlaybackComplete || (_animationStatePlaybackComplete = new AnimationStateEvent(AnimationStateEvent.PLAYBACK_COMPLETE, null, this)));
		}
	}
}
