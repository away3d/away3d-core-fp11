/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{
	import away3d.core.math.Quaternion;

	import flash.geom.Vector3D;

	public class SkeletonNaryLERPNode extends SkeletonTreeNode
	{
		/**
		 * The weights for each joint. The total needs to equal 1.
		 */
		private var _blendWeights : Vector.<Number>;
		private var _inputs : Vector.<SkeletonTreeNode>;
		private var _numInputs : uint;

		public function SkeletonNaryLERPNode(numJoints : uint)
		{
			super(numJoints);
			_inputs = new Vector.<SkeletonTreeNode>();
			_blendWeights = new Vector.<Number>();
		}

		public function getInputIndex(input : SkeletonTreeNode) : int
		{
			return _inputs.indexOf(input);
		}

		public function getInputAt(index : uint) : SkeletonTreeNode
		{
			return _inputs[index];
		}

		public function addInput(input : SkeletonTreeNode) : void
		{
			_inputs[_numInputs] = input;
			_blendWeights[_numInputs++] = 0;
		}

		override public function updatePose(skeleton : Skeleton) : void
		{
			var input : SkeletonTreeNode;
			var weight : Number;
			var endPoses : Vector.<JointPose> = skeletonPose.jointPoses;
			var poses : Vector.<JointPose>;
			var endPose : JointPose, pose : JointPose;
			var endTr : Vector3D, tr : Vector3D;
			var endQuat : Quaternion, q : Quaternion;
			var firstPose : Vector.<JointPose>;
			var i : uint;
			var w0 : Number, x0 : Number, y0 : Number, z0 : Number;
			var w1 : Number, x1 : Number, y1 : Number, z1 : Number;

			for (var j : uint = 0; j < _numInputs; ++j) {
				weight = _blendWeights[j];
				if (weight == 0) continue;
				input = _inputs[j];
				input.time = _time;
				input.direction = _direction;
				input.updatePose(skeleton);

				poses = input.skeletonPose.jointPoses;

				if (!firstPose) {
					firstPose = poses;
					for (i = 0; i < _numJoints; ++i) {
						endPose = endPoses[i];
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
					for (i = 0; i < _numJoints; ++i) {
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

			for (i = 0; i < _numJoints; ++i) {
				endPoses[i].orientation.normalize();
			}
		}

		override public function updatePositionData() : void
		{
			var delta : Vector3D;
			var weight : Number;

			rootDelta.x = 0;
			rootDelta.y = 0;
			rootDelta.z = 0;

			for (var j : uint = 0; j < _numInputs; ++j) {
				weight = _blendWeights[j];
				if (weight == 0) continue;
				_inputs[j].time = _time;
				_inputs[j].updatePositionData();
				delta = _inputs[j].rootDelta;
				rootDelta.x += weight*delta.x;
				rootDelta.y += weight*delta.y;
				rootDelta.z += weight*delta.z;
			}
		}

		public function get blendWeights() : Vector.<Number>
		{
			return _blendWeights;
		}

		public function updateWeights(weights : Vector.<Number>) : void
		{
			var weight : Number;

			_duration = 0;
			_blendWeights = weights;
			for (var j : uint = 0; j < _numInputs; ++j) {
				weight = _blendWeights[j];
				if (weight == 0) continue;
				_duration += weight*_inputs[j].duration;
			}
		}
	}
}
