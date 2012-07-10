package away3d.animators.nodes
{

	import away3d.animators.skeleton.SkeletonPose;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import flash.geom.Vector3D;

	public class SkeletonBinaryLERPNode extends SkeletonNodeBase
	{
		public var inputA : SkeletonNodeBase;
		public var inputB : SkeletonNodeBase;
		private var _blendWeight : Number;
		
		public function SkeletonBinaryLERPNode()
		{
			super();
		}
		
		override public function reset(time:Number):void
		{
			update(time);
			inputA.reset(time);
			inputB.reset(time);
		}
		
		override protected function updateTime(time : Number) : void
		{
			super.updateTime(time);
			inputA.update(time);
			inputB.update(time);
		}
		
		override protected function updateRootDelta() : void
		{
			_rootDeltaDirty = false;
			
			var deltA : Vector3D = inputA.rootDelta;
			var deltB : Vector3D = inputB.rootDelta;
			
			_rootDelta.x = deltA.x + _blendWeight*(deltB.x - deltA.x);
			_rootDelta.y = deltA.y + _blendWeight*(deltB.y - deltA.y);
			_rootDelta.z = deltA.z + _blendWeight*(deltB.z - deltA.z);
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
		
		override protected function updateSkeletonPose(skeleton : Skeleton) : void
		{
			_skeletonPoseDirty = false;

			var endPose : JointPose;
			var endPoses : Vector.<JointPose> = _skeletonPose.jointPoses;
			var poses1 : Vector.<JointPose> = inputA.getSkeletonPose(skeleton).jointPoses;
			var poses2 : Vector.<JointPose> = inputB.getSkeletonPose(skeleton).jointPoses;
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
	}
}
