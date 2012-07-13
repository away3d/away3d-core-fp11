package away3d.animators.nodes
{
	import away3d.animators.data.*;
	import away3d.core.math.*;
	
	import flash.geom.*;
	
	/**
	 * A skeleton animation node that uses an n-dimensional array of animation node inputs to blend a lineraly interpolated output of a skeleton pose.
	 */
	public class SkeletonNaryLERPNode extends AnimationNodeBase implements ISkeletonAnimationNode
	{
		private var _blendWeights : Vector.<Number>;
		private var _inputs : Vector.<ISkeletonAnimationNode>;
		private var _numInputs : uint;
		private var _skeletonPose : SkeletonPose = new SkeletonPose();
		private var _skeletonPoseDirty : Boolean =true;
		
		/**
		 * Creates a new <code>SkeletonNaryLERPNode</code> object.
		 */
		public function SkeletonNaryLERPNode()
		{
			super();
			_inputs = new Vector.<ISkeletonAnimationNode>();
			_blendWeights = new Vector.<Number>();
		}
		
		/**
		 * Returns an integer representing the input index of the given skeleton animation node.
		 * 
		 * @param input The skeleton animation node for with the input index is requested.
		 */
		public function getInputIndex(input : ISkeletonAnimationNode) : int
		{
			return _inputs.indexOf(input);
		}
		
		/**
		 * Returns the skeleton animation node object that resides at the given input index.
		 * 
		 * @param index The input index for which the skeleton animation node is requested.
		 */
		public function getInputAt(index : uint) : ISkeletonAnimationNode
		{
			return _inputs[index];
		}
		
		/**
		 * Returns the blend weight of the skeleton aniamtion node that resides at the given input index.
		 * 
		 * @param index The input index for which the skeleton animation node blend weight is requested.
		 */
		public function getBlendWeightAt(index : uint) : Number
		{
			return _blendWeights[index];
		}
		
		/**
		 * Sets the blend weight of the skeleton aniamtion node that resides at the given input index.
		 * 
		 * @param index The input index on which the skeleton animation node blend weight is to be set.
		 * @param blendWeight The blend weight value to use for the given skeleton animation node index.
		 */
		public function setBlendWeightAt(index : uint, blendWeight:Number) : void
		{
			_blendWeights[index] = blendWeight;
			
			_rootDeltaDirty = true;
			_skeletonPoseDirty = true;
		}
		
		/**
		 * Adds a new skeleton animation node input to the animation node.
		 */
		public function addInput(input : ISkeletonAnimationNode) : void
		{
			_inputs[_numInputs] = input;
			_blendWeights[_numInputs++] = 0;
		}
		
		/**
		 * Returns the current skeleton pose of the animation node based on the blend weight values given to the input nodes.
		 * 
		 * @see #setBlendWeightAt
		 */
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if (_skeletonPoseDirty)
				updateSkeletonPose(skeleton);
			
			return _skeletonPose;
		}
		
		/**
		 * Updates the output skeleton pose of the node based on the blend weight values given to the input nodes.
		 * 
		 * @param skeleton The skeleton used by the animator requesting the ouput pose. 
		 */
		public function updateSkeletonPose(skeleton : Skeleton) : void
		{
			_skeletonPoseDirty = false;
			
			var weight : Number;
			var endPoses : Vector.<JointPose> = _skeletonPose.jointPoses;
			var poses : Vector.<JointPose>;
			var endPose : JointPose, pose : JointPose;
			var endTr : Vector3D, tr : Vector3D;
			var endQuat : Quaternion, q : Quaternion;
			var firstPose : Vector.<JointPose>;
			var i : uint;
			var w0 : Number, x0 : Number, y0 : Number, z0 : Number;
			var w1 : Number, x1 : Number, y1 : Number, z1 : Number;
			var numJoints : uint = skeleton.numJoints;

			// :s
			if (endPoses.length != numJoints) endPoses.length = numJoints;

			for (var j : uint = 0; j < _numInputs; ++j) {
				weight = _blendWeights[j];
				
				if (!weight)
					continue;

				poses = _inputs[j].getSkeletonPose(skeleton).jointPoses;

				if (!firstPose) {
					firstPose = poses;
					for (i = 0; i < numJoints; ++i) {
						endPose = endPoses[i] ||= new JointPose();
						pose = poses[i];
						q = pose.orientation;
						tr = pose.translation;

						endQuat = endPose.orientation;

						endQuat.x = weight*q.x;
						endQuat.y = weight*q.y;
						endQuat.z = weight*q.z;
						endQuat.w = weight*q.w;

						endTr = endPose.translation;
						endTr.x = weight*tr.x;
						endTr.y = weight*tr.y;
						endTr.z = weight*tr.z;
					}
				}
				else {
					for (i = 0; i < skeleton.numJoints; ++i) {
						endPose = endPoses[i];
						pose = poses[i];

						q = firstPose[i].orientation;
						x0 = q.x; y0 = q.y; z0 = q.z; w0 = q.w;

						q = pose.orientation;
						tr = pose.translation;

						x1 = q.x; y1 = q.y; z1 = q.z; w1 = q.w;
						// find shortest direction
						if (x0*x1 + y0*y1 + z0*z1 + w0*w1 < 0) {
							x1 = -x1;
							y1 = -y1;
							z1 = -z1;
							w1 = -w1;
						}
						endQuat = endPose.orientation;
						endQuat.x += weight*x1;
						endQuat.y += weight*y1;
						endQuat.z += weight*z1;
						endQuat.w += weight*w1;

						endTr = endPose.translation;
						endTr.x += weight*tr.x;
						endTr.y += weight*tr.y;
						endTr.z += weight*tr.z;
					}
				}
			}

			for (i = 0; i < skeleton.numJoints; ++i) {
				endPoses[i].orientation.normalize();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time : int) : void
		{
			super.updateTime(time);
			
			for (var j : uint = 0; j < _numInputs; ++j) {
				if (_blendWeights[j])
					_inputs[j].update(time);
			}
			
			_skeletonPoseDirty = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateRootDelta() : void
		{
			_rootDeltaDirty = false;
			
			var delta : Vector3D;
			var weight : Number;

			_rootDelta.x = 0;
			_rootDelta.y = 0;
			_rootDelta.z = 0;

			for (var j : uint = 0; j < _numInputs; ++j) {
				weight = _blendWeights[j];
				
				if (weight) {
					delta = _inputs[j].rootDelta;
					_rootDelta.x += weight*delta.x;
					_rootDelta.y += weight*delta.y;
					_rootDelta.z += weight*delta.z;
				}
			}
		}
	}
}
