package away3d.animators.nodes
{
	import away3d.animators.data.*;
	
	import flash.geom.*;

	/**
	 * A skeleton animation node containing time-based animation data as individual skeleton poses.
	 */
	public class SkeletonClipNode extends AnimationClipNodeBase implements ISkeletonAnimationNode
	{
		private var _frames : Vector.<SkeletonPose> = new Vector.<SkeletonPose>();
		private var _rootPos : Vector3D = new Vector3D();
		private var _currentPose : SkeletonPose;
		private var _nextPose : SkeletonPose;
		private var _oldFrame:uint;
		private var _timeDir:int;
		
		private var _skeletonPose : SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty : Boolean = true;
		
		/**
		 * Determines whether to use SLERP equations (true) or LERP equations (false) in the calculation
		 * of the output skeleton pose. Defaults to false.
		 */
		public var highQuality:Boolean = false;
		
		/**
		 * Returns a vector of skeleton poses representing the pose of each animation frame in the clip.
		 */
		public function get frames():Vector.<SkeletonPose>
		{
			return _frames;
		}
		
		/**
		 * Returns the current skeleton pose frame of animation in the clip based on the internal playhead position.
		 */
		public function get currentPose() : SkeletonPose
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentPose;
		}
		
		/**
		 * Returns the next skeleton pose frame of animation in the clip based on the internal playhead position.
		 */
		public function get nextPose() : SkeletonPose
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextPose;
		}
		
		/**
		 * Creates a new <code>SkeletonClipNode</code> object.
		 */
		public function SkeletonClipNode()
		{
		}
		
		/**
		 * Returns the current skeleton pose of the animation in the clip based on the internal playhead position.
		 */
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if (_skeletonPoseDirty)
				updateSkeletonPose(skeleton);
			
			return _skeletonPose;
		}
		
		/**
		 * Adds a skeleton pose frame to the internal timeline of the animation node.
		 * 
		 * @param skeletonPose The skeleton pose object to add to the timeline of the node.
		 * @param duration The specified duration of the frame in milliseconds.
		 */
		public function addFrame(skeletonPose : SkeletonPose, duration : uint) : void
		{
			_frames.push(skeletonPose);
			_durations.push(duration);
			
			_numFrames = _durations.length;
			
			_stitchDirty = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time:int):void
		{
			_timeDir = (time - _time > 0)? 1 : -1;
			
			super.updateTime(time);
			
			_framesDirty = true;
			_skeletonPoseDirty = true;
		}
		
		
		/**
		 * Updates the output skeleton pose of the node based on the internal playhead position.
		 * 
		 * @param skeleton The skeleton used by the animator requesting the ouput pose. 
		 */
		protected function updateSkeletonPose(skeleton:Skeleton) : void
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
			if ((_timeDir > 0 && _nextFrame < _oldFrame) || (_timeDir < 0 && _nextFrame > _oldFrame)) {
				_rootPos.x -= _totalDelta.x*_timeDir;
				_rootPos.y -= _totalDelta.y*_timeDir;
				_rootPos.z -= _totalDelta.z*_timeDir;
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
		
		/**
		 * @inheritDoc
		 */
		override protected function updateFrames() : void
		{
			super.updateFrames();
			
			_currentPose = _frames[_currentFrame];
			
			if (_looping && _nextFrame >= _lastFrame)
				_nextPose = _frames[0];
			else
				_nextPose = _frames[_nextFrame];
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateStitch():void
		{
			super.updateStitch();
			
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
	}
}
