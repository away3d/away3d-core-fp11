package away3d.animators.data
{
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;

	use namespace arcane;

	/**
	 * VertexAnimationState defines the state for a given Mesh and VertexAnimation. The state consists out of the current
	 * poses as Geometry, and their respective blend weights.
	 *
	 * @see away3d.core.animation.vertex.VertexAnimation
	 */
	public class VertexAnimationState extends AnimationStateBase
	{
		arcane var _poses : Vector.<Geometry>;

		// keep a narrowly typed reference
		private var _vertexAnimation : VertexAnimation;
		private var _weights : Vector.<Number>;

		/**
		 * Creates a VertexAnimationState object.
		 * @param animation The animation object the state refers to.
		 */
		public function VertexAnimationState(animation : VertexAnimation)
		{
			super(animation);
			_vertexAnimation = animation;
			_weights = Vector.<Number>([1, 0, 0, 0]);
			_poses = new Vector.<Geometry>();
		}

		/**
		 * The blend weights per pose, must be values between 0 and 1.
		 */
		public function get weights() : Vector.<Number>
		{
			return _weights;
		}

		/**
		 * The blend poses that will be used to compute the final pose.
		 */
		public function get poses() : Vector.<Geometry>
		{
			return _poses;
		}

		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			// todo: add code for when running on cpu
			var i : uint;
			var len : uint = _vertexAnimation._numPoses;
			var index : uint = _vertexAnimation._streamIndex;
			var context : Context3D = stage3DProxy._context3D;

			// if no poses defined, set temp data
			if (!_poses.length) {
				if (_vertexAnimation.blendMode == VertexAnimationMode.ABSOLUTE) {
					for (i = 1; i < len; ++i) {
						stage3DProxy.setSimpleVertexBuffer(index + (j++), renderable.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.vertexBufferOffset);
						context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

						if (_vertexAnimation._useNormals)
							stage3DProxy.setSimpleVertexBuffer(index + (j++), renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.normalBufferOffset);
					}
				}
					// todo: set temp data for additive?
				return;
			}

			// this type of animation can only be SubMesh
			var subMesh : SubMesh = SubMesh(renderable);
			var subGeom : SubGeometry;
			var j : uint;

			if (_vertexAnimation.blendMode == VertexAnimationMode.ABSOLUTE) {
				i = 1;
				subGeom = _poses[uint(0)].subGeometries[subMesh._index];
				if (subGeom) subMesh.subGeometry = subGeom;
			}
			else i = 0;
			// set the base sub-geometry so the material can simply pick up on this data



			for (; i < len; ++i) {
				subGeom = _poses[i].subGeometries[subMesh._index] || subMesh.subGeometry;
				stage3DProxy.setSimpleVertexBuffer(index + (j++), subGeom.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, subGeom.vertexBufferOffset);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

				if (_vertexAnimation._useNormals)
					stage3DProxy.setSimpleVertexBuffer(index + (j++), subGeom.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, subGeom.normalBufferOffset);

			}
		}

		/**
		 * @inheritDoc
		 */
		override public function clone() : AnimationStateBase
		{
			var clone : VertexAnimationState = new VertexAnimationState(_vertexAnimation);
			clone._poses = _poses;
			clone._weights = _weights;
			return clone;
		}
	}
}