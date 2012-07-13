package away3d.animators.nodes
{

	import away3d.animators.data.*;
	
	import flash.geom.*;
	
	/**
	 * A skeleton animation node that uses two animation node inputs to blend a lineraly interpolated output of a skeleton pose.
	 */
	public class SkeletonBinaryLERPNode extends AnimationNodeBase implements ISkeletonAnimationNode
	{
		private var _blendWeight : Number = 0;
		private var _skeletonPose : SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty : Boolean = true;
		
		/**
		 * Defines input node A to use for the blended output.
		 */
		public var inputA : ISkeletonAnimationNode;
		
		/**
		 * Defines input node B to use for the blended output.
		 */
		public var inputB : ISkeletonAnimationNode;
		
		/**
		 * Creates a new <code>SkeletonBinaryLERPNode</code> object.
		 */
		public function SkeletonBinaryLERPNode()
		{
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function reset(time:int):void
		{
			super.reset(time);
			
			inputA.reset(time);
			inputB.reset(time);
		}
		
		/**
		 * Returns the current skeleton pose of the animation node based on the blendWeight value between input nodes.
		 * 
		 * @see #inputA
		 * @see #inputB
		 * @see #blendWeight
		 */
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if (_skeletonPoseDirty)
				updateSkeletonPose(skeleton);
			
			return _skeletonPose;
		}
		
		/**
		 * Defines a fractional value between 0 and 1 representing the blending ratio between inputA (0) and inputB (1),
		 * used to produce the skeleton pose output.
		 * 
		 * @see inputA
		 * @see inputB
		 */
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
		
		/**
		 * Updates the output skeleton pose of the node based on the blendWeight value between input nodes.
		 * 
		 * @param skeleton The skeleton used by the animator requesting the ouput pose. 
		 */
		protected function updateSkeletonPose(skeleton : Skeleton) : void
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
		
		override protected function updateTime(time : int) : void
		{
			super.updateTime(time);
			
			inputA.update(time);
			inputB.update(time);
			
			_skeletonPoseDirty = true;
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
		
	}
}
