/**
 * Author: David Lenaerts
 */
package away3d.animators.nodes
{

	import away3d.animators.data.*;
	import away3d.core.math.*;
	
	import flash.geom.*;
	


	public class SkeletonAdditiveNode extends AnimationNodeBase implements ISkeletonAnimationNode
	{
		public var baseInput : ISkeletonAnimationNode;
		public var differenceInput : ISkeletonAnimationNode;
		
		private var _blendWeight : Number = 0;
		private var _skeletonPose : SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty : Boolean = true;
		
		private static var _tempQuat : Quaternion = new Quaternion();

		public function SkeletonAdditiveNode()
		{
			super();
		}
		
		public function get blendWeight() : Number
		{
			return _blendWeight;
		}

		public function set blendWeight(value : Number) : void
		{
			_blendWeight = value;
			
			_rootDeltaDirty = true;
			_skeletonPoseDirty = true;
		}
		
		override public function reset(time:int):void
		{
			super.reset(time);
			
			baseInput.reset(time);
			differenceInput.reset(time);
		}
		
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if (_skeletonPoseDirty)
				updateSkeletonPose(skeleton);
			
			return _skeletonPose;
		}
		
		override protected function updateTime(time : int) : void
		{
			super.updateTime(time);
			
			baseInput.update(time);
			differenceInput.update(time);
			
			_skeletonPoseDirty = true;
		}

		// todo: return whether or not update was performed
		public function updateSkeletonPose(skeleton : Skeleton) : void
		{
			_skeletonPoseDirty = false;
			
			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = _skeletonPose.jointPoses;
			var basePoses : Vector.<JointPose> = baseInput.getSkeletonPose(skeleton).jointPoses;
			var diffPoses : Vector.<JointPose> = differenceInput.getSkeletonPose(skeleton).jointPoses;
			var base : JointPose, diff : JointPose;
			var basePos : Vector3D, diffPos : Vector3D;
			var tr : Vector3D;
			var numJoints : uint = skeleton.numJoints;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;

			for (var i : uint = 0; i < numJoints; ++i) {
				endPose = endPoses[i] ||= new JointPose();
				base = basePoses[i];
				diff = diffPoses[i];
				basePos = base.translation;
				diffPos = diff.translation;

				_tempQuat.multiply(diff.orientation, base.orientation);
				endPose.orientation.lerp(base.orientation, _tempQuat, _blendWeight);

				tr = endPose.translation;
				tr.x = basePos.x + _blendWeight*diffPos.x;
				tr.y = basePos.y + _blendWeight*diffPos.y;
				tr.z = basePos.z + _blendWeight*diffPos.z;
			}
		}

		override protected function updateRootDelta() : void
		{
			var deltA : Vector3D = baseInput.rootDelta;
			var deltB : Vector3D = differenceInput.rootDelta;

			rootDelta.x = deltA.x + _blendWeight*deltB.x;
			rootDelta.y = deltA.y + _blendWeight*deltB.y;
			rootDelta.z = deltA.z + _blendWeight*deltB.z;
		}
	}
}
