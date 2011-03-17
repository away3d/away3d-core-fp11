package away3d.animators.data
{
	import away3d.arcane;
	import away3d.materials.passes.MaterialPassBase;

	import flash.display3D.Context3D;
	import away3d.animators.skeleton.Skeleton;

	use namespace arcane;

	/**
	 * SkinnedAnimation defines an animation type that blends different skeletal poses into a final pose and transforms
	 * the geometries' vertices along the skeleton. Each vertex is bound to a number of skeleton joints with a number of
	 * weights, which define how the skeleton influences the vertex position.
	 *
	 * @see away3d.core.animation.skeleton.Skeleton
	 * @see away3d.core.animation.skeleton.Joint
	 */
	public class SkeletonAnimation extends AnimationBase
	{
		private var _skeleton : Skeleton;
		private var _usesCPU : Boolean;
		private var _nullAnimation : NullAnimation;
		private var _jointsPerVertex : uint;

		/**
		 * Creates a SkinnedAnimation instance.
		 * @param skeleton The skeleton that's used for this SkinnedAnimation instance.
		 * @param jointsPerVertex The amount of joints that can be linked to a vertex.
		 */
		public function SkeletonAnimation(skeleton : Skeleton, jointsPerVertex : uint = 4)
		{
			_skeleton = skeleton;
			_jointsPerVertex = jointsPerVertex;
		}

		/**
		 * Indicates whether or not the vertex transformation happens on CPU or GPU. Returns false if it cannot run on GPU,
		 * due to too many joints or too many joints per vertex.
		 */
		public function get usesCPU() : Boolean
		{
			return _usesCPU;
		}

		/**
		 * The amount of joints that can be linked t oa vertex.
		 */
		public function get jointsPerVertex() : uint
		{
			return _jointsPerVertex;
		}

		public function set jointsPerVertex(value : uint) : void
		{
			_jointsPerVertex = value;
		}

		/**
		 * The skeleton that's used for this SkinnedAnimation instance.
		 */
		public function get skeleton() : Skeleton
		{
			return _skeleton;
		}

		public function set skeleton(value : Skeleton) : void
		{
			_skeleton = value;
		}

		/**
		 * The amount of joints in the skeleton.
		 */
		public function get numJoints() : uint
		{
			return _skeleton.numJoints;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function deactivate(context3D : Context3D, pass : MaterialPassBase) : void
		{
			if (_usesCPU) return;
			var streamOffset : uint = pass.numUsedStreams;
			context3D.setVertexBufferAt(streamOffset, null);
			context3D.setVertexBufferAt(streamOffset + 1, null);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function createAnimationState() : AnimationStateBase
		{
			return new SkeletonAnimationState(this);
		}


		/**
		 * @inheritDoc
		 */
		override arcane function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var attributes : Array = pass.getAnimationSourceRegisters();
			var len : uint = attributes.length;

			// if too many bones to fit in the constants, fall back to cpu animation :(
			if (_jointsPerVertex > 4 || pass.numUsedVertexConstants + _skeleton.numJoints * 3 > 128) {
				_usesCPU = true;
				_nullAnimation = new NullAnimation();
				return _nullAnimation.getAGALVertexCode(pass);
			}

			var targets : Array = pass.getAnimationTargetRegisters();
			var indexOffset0 : uint = pass.numUsedVertexConstants;
			var indexOffset1 : uint = indexOffset0 + 1;
			var indexOffset2 : uint = indexOffset0 + 2;
			var indexStream : String = "va" + pass.numUsedStreams;
			var weightStream : String = "va" + (pass.numUsedStreams + 1);
			var indices : Array = [ indexStream + ".x", indexStream + ".y", indexStream + ".z", indexStream + ".w" ];
			var weights : Array = [ weightStream + ".x", weightStream + ".y", weightStream + ".z", weightStream + ".w" ];
			var temp1 : String = findTempReg(targets);
			var temp2 : String = findTempReg(targets, temp1);
			var dot : String = "dp4";
			var code : String = "";

			for (var i : uint = 0; i < len; ++i) {

				var src : String = attributes[i];

				for (var j : uint = 0; j < _jointsPerVertex; ++j) {
					code +=	dot + " " + temp1 + ".x, " + src + ", vc[" + indices[j] + "+" + indexOffset0 + "]		\n" +
							dot + " " + temp1 + ".y, " + src + ", vc[" + indices[j] + "+" + indexOffset1 + "]    	\n" +
							dot + " " + temp1 + ".z, " + src + ", vc[" + indices[j] + "+" + indexOffset2 + "]		\n" +
							"mov " + temp1 + ".w, " + src + ".w		\n" +
							"mul " + temp1 + ", " + temp1 + ", " + weights[j] + "\n";	// apply weight

					// add or mov to target. Need to write to a temp reg first, because an output can be a target
					if (j == 0) code += "mov " + temp2 + ", " + temp1 + "\n";
					else code += "add " + temp2 + ", " + temp2 + ", " + temp1 + "\n";
				}
				// switch to dp3 once positions have been transformed, from now on, it should only be vectors instead of points
				dot = "dp3";
				code += "mov " + targets[i] + ", " + temp2 + "\n";
			}

			return code;
		}

		/**
		 * Retrieves a temporary register that's still free.
		 * @param exclude An array of non-free temporary registers
		 * @param excludeAnother An additional register that's not free
		 * @return A temporary register that can be used
		 */
		private function findTempReg(exclude : Array, excludeAnother : String = null) : String
		{
			var i : uint;
			var reg : String;

			while (true) {
				reg = "vt" + i;
				if (exclude.indexOf(reg) == -1 && excludeAnother != reg) return reg;
				++i;
			}

			// can't be reached
			return null;
		}
	}
}