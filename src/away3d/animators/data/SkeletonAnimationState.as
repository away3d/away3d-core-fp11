package away3d.animators.data
{
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.animators.skeleton.SkeletonPose;
	import away3d.animators.skeleton.SkeletonTreeNode;
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Quaternion;

	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace arcane;

	/**
	 * SkeletonAnimationState defines the state for a given Mesh and SkeletonAnimation. The state consists of a skeleton pose.
	 *
	 * @see away3d.core.animation.skinned.SkinnedAnimation
	 *
	 */
	public class SkeletonAnimationState extends AnimationStateBase
	{
		private var _globalMatrices : Vector.<Number>;
		private var _numJoints : uint;
		private var _skinnedAnimation : SkeletonAnimation;
		private var _jointsPerVertex : uint;
		private var _bufferFormat : String;
        private var _skeleton : Skeleton;
        private var _blendTree : SkeletonTreeNode;
        private var _globalPose : SkeletonPose;
        private var _globalInput : Boolean;
		private var _buffersValid : Dictionary = new Dictionary();
		private var _globalMatricesInvalid : Boolean;
		private var _useCondensedIndices : Boolean;
		private var _condensedMatrices : Vector.<Number>;


		/**
		 * Creates a SkeletonAnimationState object.
		 * @param animation The animation object the state refers to.
		 * @param jointsPerVertex The amount of joints per vertex define
		 */
		public function SkeletonAnimationState(animation : SkeletonAnimation)
		{
			super(animation);

			_skinnedAnimation = animation;
            if (animation.numJoints > 0) {
				init();
			}
		}

		private function init() : void
		{
			_jointsPerVertex = _skinnedAnimation.jointsPerVertex;
            _skeleton = _skinnedAnimation.skeleton;
            _numJoints = _skinnedAnimation.numJoints;
			_globalMatrices = new Vector.<Number>(_numJoints*12, true);
			_bufferFormat = "float"+_jointsPerVertex;
            _globalPose = new SkeletonPose();

			var j : int;
			for (var i : uint = 0; i < _numJoints; ++i) {
				_globalMatrices[j++] = 1; _globalMatrices[j++] = 0; _globalMatrices[j++] = 0; _globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0; _globalMatrices[j++] = 1; _globalMatrices[j++] = 0; _globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0; _globalMatrices[j++] = 0; _globalMatrices[j++] = 1; _globalMatrices[j++] = 0;
			}
		}

		/**
		 * The amount of joints in the target skeleton.
		 */
		public function get numJoints() : uint
		{
			return _numJoints;
		}

		/**
		 * The chained raw data of the global pose matrices in row-major order.
		 */
		public function get globalMatrices() : Vector.<Number>
		{
			return _globalMatrices;
		}

		/**
		 * The global skeleton pose used to transform the mesh's vertices.
		 */
		public function get globalPose() : SkeletonPose
		{
			if (_stateInvalid) updateGlobalPose();
			return _globalPose;
		}

		public function set globalPose(value : SkeletonPose) : void
		{
			if (!_globalInput) throw new Error("Cannot set global pose if globalInput is false");
			_globalPose = value;
			_globalMatricesInvalid = true;
		}

        arcane function validateGlobalMatrices() : void
        {
            _stateInvalid = false;
            _globalMatricesInvalid = false;
        }

		/**
		 * The local skeleton blend tree that will be used to generate the global pose.
		 */
		public function get blendTree() : SkeletonTreeNode
		{
			return _blendTree;
		}

		public function set blendTree(value : SkeletonTreeNode) : void
		{
			_blendTree = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function invalidateState() : void
		{
			super.invalidateState();

			for(var key : Object in _buffersValid) {
			    delete _buffersValid[key];
			}
		}

		/**
		 * @inheritDoc
		 */
        override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			if (_numJoints == 0) {
				// delayed skeleton instantiation
				if (_skinnedAnimation.numJoints > 0)
					init();
				else
					return;
			}

			// do on request of globalPose
			if (_stateInvalid) updateGlobalPose();
			if (_globalMatricesInvalid) convertToMatrices();

			var skinnedGeom : SkinnedSubGeometry = SkinnedSubGeometry(SubMesh(renderable).subGeometry);

			// using condensed data
			var numCondensedJoints : uint = skinnedGeom.numCondensedJoints;
			if (SkeletonAnimation(_animation).useCondensedIndices) {
				if (skinnedGeom.numCondensedJoints == 0)
					skinnedGeom.condenseIndexData();
				updateCondensedMatrices(skinnedGeom.condensedIndexLookUp, numCondensedJoints);
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _condensedMatrices, numCondensedJoints*3);
			}
			else {
				if (_animation.usesCPU) {
					if (!_buffersValid[skinnedGeom]) {
						morphGeometry(skinnedGeom);
						_buffersValid[skinnedGeom] = skinnedGeom;
					}
					return;
				}
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _globalMatrices, _numJoints*3);
			}

			stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset, skinnedGeom.getJointIndexBuffer(stage3DProxy), _bufferFormat, 0);
			stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset+1, skinnedGeom.getJointWeightsBuffer(stage3DProxy), _bufferFormat, 0);
		}

		private function updateCondensedMatrices(condensedIndexLookUp : Vector.<uint>, numJoints : uint) : void
		{
			var i : uint = 0, j : uint = 0;
			var len : uint;
			var srcIndex : uint;

			_condensedMatrices = new Vector.<Number>();

			do {
				srcIndex = condensedIndexLookUp[i*3]*4;
				len = srcIndex+12;
				// copy into condensed
				while (srcIndex < len)
					_condensedMatrices[j++] = _globalMatrices[srcIndex++];
			} while (++i < numJoints);
		}

		private function updateGlobalPose() : void
		{
			if (!_globalInput) {
				_blendTree.updatePose(_skeleton);
				_blendTree.skeletonPose.toGlobalPose(_globalPose, _skeleton);
			}
			_globalMatricesInvalid = true;
			_stateInvalid = false;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone() : AnimationStateBase
		{
			return new SkeletonAnimationState(_skinnedAnimation);
		}

		/**
		 * Defines whether or not to bypass the blend tree and allow setting the global skeleton pose directly.
		 * todo: remove, use post-processing effects for global position based... stuff.
		 */
		arcane function get globalInput() : Boolean
        {
            return _globalInput;
        }

        arcane function set globalInput(value : Boolean) : void
        {
            _globalInput = value;
        }

		/**
		 * Converts the current final pose to matrices for the actual transformations
		 */
		private function convertToMatrices() : void
		{
			// convert pose to matrix
		    var mtxOffset : uint;
			var globalPoses : Vector.<JointPose> = _globalPose.jointPoses;
			var raw : Vector.<Number>;
			var ox : Number, oy : Number, oz : Number, ow : Number;
			var xy2 : Number, xz2 : Number, xw2 : Number;
			var yz2 : Number, yw2 : Number, zw2 : Number;
			var xx : Number, yy : Number, zz : Number, ww : Number;
			var n11 : Number, n12 : Number, n13 : Number, n14 : Number;
			var n21 : Number, n22 : Number, n23 : Number, n24 : Number;
			var n31 : Number, n32 : Number, n33 : Number, n34 : Number;
			var m11 : Number, m12 : Number, m13 : Number, m14 : Number;
			var m21 : Number, m22 : Number, m23 : Number, m24 : Number;
			var m31 : Number, m32 : Number, m33 : Number, m34 : Number;
			var joints : Vector.<SkeletonJoint> = _skeleton.joints;
			var pose : JointPose;
			var quat : Quaternion;
			var vec : Vector3D;

			for (var i : uint = 0; i < _numJoints; ++i) {
				pose = globalPoses[i];
				quat = pose.orientation;
				vec = pose.translation;
				ox = quat.x;	oy = quat.y;	oz = quat.z;	ow = quat.w;
				xy2 = 2.0 * ox * oy; 	xz2 = 2.0 * ox * oz; 	xw2 = 2.0 * ox * ow;
				yz2 = 2.0 * oy * oz; 	yw2 = 2.0 * oy * ow; 	zw2 = 2.0 * oz * ow;
				xx = ox * ox;			yy = oy * oy;			zz = oz * oz; 			ww = ow * ow;

				n11 = xx - yy - zz + ww;	n12 = xy2 - zw2;			n13 = xz2 + yw2;			n14 = vec.x;
				n21 = xy2 + zw2;			n22 = -xx + yy - zz + ww;	n23 = yz2 - xw2;			n24 = vec.y;
				n31 = xz2 - yw2;			n32 = yz2 + xw2;			n33 = -xx - yy + zz + ww;	n34 = vec.z;

				// prepend inverse bind pose
				raw = joints[i].inverseBindPose;
				m11 = raw[0];	m12 = raw[4];	m13 = raw[8];	m14 = raw[12];
				m21 = raw[1];	m22 = raw[5];   m23 = raw[9];	m24 = raw[13];
				m31 = raw[2];   m32 = raw[6];   m33 = raw[10];  m34 = raw[14];

				_globalMatrices[mtxOffset++] = n11 * m11 + n12 * m21 + n13 * m31;
				_globalMatrices[mtxOffset++] = n11 * m12 + n12 * m22 + n13 * m32;
				_globalMatrices[mtxOffset++] = n11 * m13 + n12 * m23 + n13 * m33;
				_globalMatrices[mtxOffset++] = n11 * m14 + n12 * m24 + n13 * m34 + n14;
				_globalMatrices[mtxOffset++] = n21 * m11 + n22 * m21 + n23 * m31;
				_globalMatrices[mtxOffset++] = n21 * m12 + n22 * m22 + n23 * m32;
				_globalMatrices[mtxOffset++] = n21 * m13 + n22 * m23 + n23 * m33;
				_globalMatrices[mtxOffset++] = n21 * m14 + n22 * m24 + n23 * m34 + n24;
				_globalMatrices[mtxOffset++] = n31 * m11 + n32 * m21 + n33 * m31;
				_globalMatrices[mtxOffset++] = n31 * m12 + n32 * m22 + n33 * m32;
				_globalMatrices[mtxOffset++] = n31 * m13 + n32 * m23 + n33 * m33;
				_globalMatrices[mtxOffset++] = n31 * m14 + n32 * m24 + n33 * m34 + n34;
			}

			_globalMatricesInvalid = false;
		}

		/**
		 * If the animation can't be performed on cpu, transform vertices manually
		 * @param subGeom The subgeometry containing the weights and joint index data per vertex.
		 * @param pass The material pass for which we need to transform the vertices
		 *
		 * todo: we may be able to transform tangents more easily, similar to how it happens on gpu
		 */
		private function morphGeometry(subGeom : SkinnedSubGeometry) : void
		{
			var verts : Vector.<Number> = subGeom.vertexData;
			var normals : Vector.<Number> = subGeom.vertexNormalData;
			var tangents : Vector.<Number> = subGeom.vertexTangentData;
			var targetVerts : Vector.<Number> = subGeom.animatedVertexData;
			var targetNormals : Vector.<Number> = subGeom.animatedNormalData;
			var targetTangents : Vector.<Number> = subGeom.animatedTangentData;
			var jointIndices : Vector.<Number> = subGeom.jointIndexData;
			var jointWeights : Vector.<Number> = subGeom.jointWeightsData;
			var i1 : uint, i2 : uint = 1, i3 : uint = 2;
			var j : uint, k : uint;
			var vx : Number, vy : Number, vz : Number;
			var nx : Number, ny : Number, nz : Number;
			var tx : Number, ty : Number, tz : Number;
			var len : int = verts.length;
			var weight : Number;
			var mtxOffset : uint;
			var vertX : Number, vertY : Number, vertZ : Number;
			var normX : Number, normY : Number, normZ : Number;
			var tangX : Number, tangY : Number, tangZ : Number;
			var m11 : Number, m12 : Number, m13 : Number;
			var m21 : Number, m22 : Number, m23 : Number;
			var m31 : Number, m32 : Number, m33 : Number;

			while (i1 < len) {
				vertX = verts[i1]; vertY = verts[i2]; vertZ = verts[i3];
				vx = 0; vy = 0; vz = 0;
				normX = normals[i1]; normY = normals[i2]; normZ = normals[i3];
				nx = 0; ny = 0; nz = 0;
				tangX = tangents[i1]; tangY = tangents[i2]; tangZ = tangents[i3];
				tx = 0; ty = 0; tz = 0;

				// todo: can we use actual matrices when using cpu + using matrix.transformVectors, then adding them in loop?

				k = 0;
				while (k < _jointsPerVertex) {
					weight = jointWeights[j];
					if (weight == 0) {
						j += _jointsPerVertex - k;
						k = _jointsPerVertex;
					}
					else {
						// implicit /3*12 (/3 because indices are multiplied by 3 for gpu matrix access, *12 because it's the matrix size)
						mtxOffset = jointIndices[uint(j++)]*4;
						m11 = _globalMatrices[mtxOffset]; m12 = _globalMatrices[mtxOffset+1]; m13 = _globalMatrices[mtxOffset+2];
						m21 = _globalMatrices[mtxOffset+4]; m22 = _globalMatrices[mtxOffset+5]; m23 = _globalMatrices[mtxOffset+6];
						m31 = _globalMatrices[mtxOffset+8]; m32 = _globalMatrices[mtxOffset+9]; m33 = _globalMatrices[mtxOffset+10];
						vx += weight*(m11*vertX + m12*vertY + m13*vertZ + _globalMatrices[mtxOffset+3]);
						vy += weight*(m21*vertX + m22*vertY + m23*vertZ + _globalMatrices[mtxOffset+7]);
						vz += weight*(m31*vertX + m32*vertY + m33*vertZ + _globalMatrices[mtxOffset+11]);

						nx += weight*(m11*normX + m12*normY + m13*normZ);
						ny += weight*(m21*normX + m22*normY + m23*normZ);
						nz += weight*(m31*normX + m32*normY + m33*normZ);
						tx += weight*(m11*tangX + m12*tangY + m13*tangZ);
						ty += weight*(m21*tangX + m22*tangY + m23*tangZ);
						tz += weight*(m31*tangX + m32*tangY + m33*tangZ);
						k++;
					}
				}

				targetVerts[i1] = vx; targetVerts[i2] = vy; targetVerts[i3] = vz;
				targetNormals[i1] = nx; targetNormals[i2] = ny; targetNormals[i3] = nz;
				targetTangents[i1] = tx; targetTangents[i2] = ty; targetTangents[i3] = tz;

				i1 += 3; i2 += 3; i3 += 3;
			}
			subGeom.animatedVertexData = targetVerts;
			subGeom.animatedNormalData = targetNormals;
			subGeom.animatedTangentData = targetTangents;
		}

		public function applyRootDelta() : void
		{
			var delta : Vector3D = blendTree.rootDelta;
			var dist : Number = delta.length;
			var len : uint;
			if (dist > 0) {
				len = _owners.length;
				for (var i : uint = 0; i < len; ++i)
					_owners[i].translateLocal(delta, dist);
			}
		}
	}
}