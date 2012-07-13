/**
 * Author: David Lenaerts
 */
package away3d.animators.nodes
{

	import away3d.animators.data.*;
	
	import flash.geom.*;

	public class SkeletonDirectionalNode extends AnimationNodeBase implements ISkeletonAnimationNode
	{
		/**
		 * The weights for each joint. The total needs to equal 1.
		 */
		public var forward : ISkeletonAnimationNode;
		public var backward : ISkeletonAnimationNode;
		public var left : ISkeletonAnimationNode;
		public var right : ISkeletonAnimationNode;
		
		private var _inputA : ISkeletonAnimationNode;
		private var _inputB : ISkeletonAnimationNode;
		private var _blendWeight : Number = 0;
		private var _direction:Number = 0;
		private var _blendDirty:Boolean;
		private var _skeletonPose : SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty : Boolean;
		
		public function SkeletonDirectionalNode()
		{
			super();
		}
		
		override public function reset(time:int):void
		{
			super.reset(time);
			
			forward.reset(time);
			backward.reset(time);
			left.reset(time);
			right.reset(time);
		}
		
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if (_skeletonPoseDirty)
				updateSkeletonPose(skeleton);
			
			return _skeletonPose;
		}

		// between 0 - 360
		public function set direction(value : Number) : void
		{
			if (_direction == value)
				return;
			
			_direction = value;
			
			_blendDirty = true;
			_skeletonPoseDirty = true;
			_rootDeltaDirty = true;
		}
		
		public function get direction():Number
		{
			return _direction;
		}

		public function updateSkeletonPose(skeleton : Skeleton) : void
		{
			_skeletonPoseDirty = false;
			
			if (_blendDirty)
				updateBlend();
			
			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = _skeletonPose.jointPoses;
			var poses1 : Vector.<JointPose> = _inputA.getSkeletonPose(skeleton).jointPoses;
			var poses2 : Vector.<JointPose> = _inputB.getSkeletonPose(skeleton).jointPoses;
			var pose1 : JointPose, pose2 : JointPose;
			var p1 : Vector3D, p2 : Vector3D;
			var tr : Vector3D;
			var numJoints : uint = skeleton.numJoints;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;
			
			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				pose1 = poses1[i];
				pose2 = poses2[i];
				p1 = pose1.translation; p2 = pose2.translation;

				endPose.orientation.lerp(pose1.orientation, pose2.orientation, _blendWeight);

				tr = endPose.translation;
				tr.x = p1.x + _blendWeight*(p2.x - p1.x);
				tr.y = p1.y + _blendWeight*(p2.y - p1.y);
				tr.z = p1.z + _blendWeight*(p2.z - p1.z);
			}
		}

		private function updateBlend() : void
		{
			_blendDirty = false;

			if (_direction < 0 || _direction > 360) {
				 _direction %= 360;
				 if (_direction < 0) _direction += 360;
			}

			if (_direction < 90) {
				_inputA = forward;
				_inputB = right;
				_blendWeight = _direction/90;
			}
			else if (_direction < 180) {
				_inputA = right;
				_inputB = backward;
				_blendWeight = (_direction-90)/90;
			}
			else if (_direction < 270) {
				_inputA = backward;
				_inputB = left;
				_blendWeight = (_direction-180)/90;
			}
			else {
				_inputA = left;
				_inputB = forward;
				_blendWeight = (_direction-270)/90;
			}
		}
		
		
		override protected function updateTime(time : int) : void
		{
			super.updateTime(time);
			
			_inputA.update(time);
			_inputB.update(time);
			
			_skeletonPoseDirty = true;
		}
		
		override protected function updateRootDelta() : void
		{
			_rootDeltaDirty = false;
			
			if (_blendDirty)
				updateBlend();
			
			var deltA : Vector3D = _inputA.rootDelta;
			var deltB : Vector3D = _inputB.rootDelta;
			
			_rootDelta.x = deltA.x + _blendWeight*(deltB.x - deltA.x);
			_rootDelta.y = deltA.y + _blendWeight*(deltB.y - deltA.y);
			_rootDelta.z = deltA.z + _blendWeight*(deltB.z - deltA.z);
		}
	}
}
