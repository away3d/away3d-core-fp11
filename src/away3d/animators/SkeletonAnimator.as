package away3d.animators
{
	import away3d.errors.AbstractMethodError;
	import away3d.entities.Mesh;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.core.base.SubMesh;
	import flash.geom.Vector3D;
	import away3d.core.math.Quaternion;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.animators.skeleton.JointPose;
	import flash.display3D.Context3DProgramType;
	import away3d.core.base.SkinnedSubGeometry;
	import flash.utils.Dictionary;
	import away3d.animators.skeleton.SkeletonPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.nodes.SkeletonTimelineClipNode;
	import away3d.animators.nodes.SkeletonTreeNode;
	import away3d.arcane;

	use namespace arcane;

	/**
	 * AnimationSequenceController provides a controller for single clip-based animation sequences (fe: md2, md5anim).
	 */
	public class SkeletonAnimator extends AnimatorBase implements IAnimator
	{
		private var _sequences : Array;
		private var _clipNode : SkeletonTimelineClipNode;
		private var _globalMatrices : Vector.<Number>;
		private var _numJoints : uint;
		private var _jointsPerVertex : uint;
		private var _bufferFormat : String;
        private var _skeleton : Skeleton;
        private var _blendTree : SkeletonTreeNode;
        private var _globalPose : SkeletonPose;
		private var _animationStates : Dictionary = new Dictionary();
		private var _condensedMatrices : Vector.<Number>;
		
		private var _forceCPU : Boolean;
		private var _useCondensedIndices : Boolean;
		
		public var updateRootPosition:Boolean = true;
		
		/**
		 * Creates a new AnimationSequenceController object.
		 */
		public function SkeletonAnimator(skeleton : Skeleton, jointsPerVertex : uint = 4, forceCPU : Boolean = false)
		{
			super();
			
			_forceCPU = _usesCPU = forceCPU;
			_skeleton = skeleton;
			_jointsPerVertex = jointsPerVertex;
			
			_numJoints = _skeleton.numJoints;
			_globalMatrices = new Vector.<Number>(_numJoints*12, true);
			_bufferFormat = "float"+_jointsPerVertex;
            _globalPose = new SkeletonPose();

			var j : int;
			for (var i : uint = 0; i < _numJoints; ++i) {
				_globalMatrices[j++] = 1; _globalMatrices[j++] = 0; _globalMatrices[j++] = 0; _globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0; _globalMatrices[j++] = 1; _globalMatrices[j++] = 0; _globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0; _globalMatrices[j++] = 0; _globalMatrices[j++] = 1; _globalMatrices[j++] = 0;
			}
			
			_sequences = [];
			
			_blendTree = createBlendTree();
		}
		
		protected function createBlendTree() : SkeletonTreeNode
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function invalidateState() : void
		{
			super.invalidateState();

			for(var key : Object in _animationStates) {
			    SubGeomAnimationState(_animationStates[key]).valid = false;
			}
		}
		
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			invalidateState();

			_blendTree.updatePositionData();

			if (updateRootPosition)
				applyRootDelta();
		}
		
		/**
		 * @inheritDoc
		 */
        public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			// do on request of globalPose
			if (_stateInvalid) {
				_stateInvalid = false;
				_blendTree.updatePose(_skeleton);
				_blendTree.skeletonPose.toGlobalPose(_globalPose, _skeleton);
				convertToMatrices();
			}

			var skinnedGeom : SkinnedSubGeometry = SkinnedSubGeometry(SubMesh(renderable).subGeometry);

			// using condensed data
			var numCondensedJoints : uint = skinnedGeom.numCondensedJoints;
			if (_useCondensedIndices) {
				if (skinnedGeom.numCondensedJoints == 0)
					skinnedGeom.condenseIndexData();
				updateCondensedMatrices(skinnedGeom.condensedIndexLookUp, numCondensedJoints);
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _condensedMatrices, numCondensedJoints*3);
			}
			else {
				if (_usesCPU) {
					var subGeomAnimState : SubGeomAnimationState = _animationStates[skinnedGeom] ||= new SubGeomAnimationState(skinnedGeom);

					if (!subGeomAnimState.valid) {
						morphGeometry(subGeomAnimState, skinnedGeom);
						subGeomAnimState.valid = true;
					}
					skinnedGeom.animatedVertexData = subGeomAnimState.animatedVertexData;
					skinnedGeom.animatedNormalData = subGeomAnimState.animatedNormalData;
					skinnedGeom.animatedTangentData = subGeomAnimState.animatedTangentData;
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
		}
		
		/**
		 * If the animation can't be performed on GPU, transform vertices manually
		 * @param subGeom The subgeometry containing the weights and joint index data per vertex.
		 * @param pass The material pass for which we need to transform the vertices
		 *
		 * todo: we may be able to transform tangents more easily, similar to how it happens on gpu
		 */
		private function morphGeometry(state : SubGeomAnimationState, subGeom : SkinnedSubGeometry) : void
		{
			var verts : Vector.<Number> = subGeom.vertexData;
			var normals : Vector.<Number> = subGeom.vertexNormalData;
			var tangents : Vector.<Number> = subGeom.vertexTangentData;
			var targetVerts : Vector.<Number> = state.animatedVertexData;
			var targetNormals : Vector.<Number> = state.animatedNormalData;
			var targetTangents : Vector.<Number> = state.animatedTangentData;
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
		}

		public function applyRootDelta() : void
		{
			var delta : Vector3D = _blendTree.rootDelta;
			var dist : Number = delta.length;
			var len : uint;
			if (dist > 0) {
				len = _owners.length;
				for (var i : uint = 0; i < len; ++i)
					_owners[i].translateLocal(delta, dist);
			}
		}

		/**
		 * @inheritDoc
		 */
		public function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : String
		{
			var len : uint = sourceRegisters.length;

			var indexOffset0 : uint = pass.numUsedVertexConstants;
			var indexOffset1 : uint = indexOffset0 + 1;
			var indexOffset2 : uint = indexOffset0 + 2;
			var indexStream : String = "va" + pass.numUsedStreams;
			var weightStream : String = "va" + (pass.numUsedStreams + 1);
			var indices : Array = [ indexStream + ".x", indexStream + ".y", indexStream + ".z", indexStream + ".w" ];
			var weights : Array = [ weightStream + ".x", weightStream + ".y", weightStream + ".z", weightStream + ".w" ];
			var temp1 : String = findTempReg(targetRegisters);
			var temp2 : String = findTempReg(targetRegisters, temp1);
			var dot : String = "dp4";
			var code : String = "";

			for (var i : uint = 0; i < len; ++i) {

				var src : String = sourceRegisters[i];

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
				code += "mov " + targetRegisters[i] + ", " + temp2 + "\n";
			}

			return code;
		}
		

		/**
		 * Retrieves a sequence with a given name.
		 * @private
		 */
		/*arcane function getSequence(sequenceName : String) : AnimationSequenceBase
		{
			return _sequences[sequenceName];
		 } */
		 
		/**
		 * Retrieving the sequences
		 */
		arcane function get sequences() : Array
		{
			return _sequences;
		}
		 
		/**
		* Retrieves all sequences names.
		* @private
		*/
		arcane function get sequencesNames() : Array
		{
			var seqsNames:Array = [];
			for(var key:String in _sequences)
				seqsNames.push(key);
			
			return seqsNames;
		}
		
        /**
         * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
         */
        public function testGPUCompatibility(pass : MaterialPassBase) : void
        {
			if (!_useCondensedIndices && (_forceCPU || _jointsPerVertex > 4 || pass.numUsedVertexConstants + _skeleton.numJoints * 3 > 128)) {
				_usesCPU = true;
			}
        }
		
		/**
		 * @inheritDoc
		 */
		public function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			if (_usesCPU) return;
			var streamOffset : uint = pass.numUsedStreams;

			stage3DProxy.setSimpleVertexBuffer(streamOffset, null, null, 0);
			stage3DProxy.setSimpleVertexBuffer(streamOffset + 1, null, null, 0);
		}
	}
}

import away3d.core.base.SubGeometry;

class SubGeomAnimationState
{
	public var animatedVertexData : Vector.<Number>;
	public var animatedNormalData : Vector.<Number>;
	public var animatedTangentData : Vector.<Number>;
	public var valid : Boolean = false;

	public function SubGeomAnimationState(subGeom : SubGeometry)
	{
		animatedVertexData = subGeom.vertexData.concat();
		animatedNormalData = subGeom.vertexNormalData.concat();
		animatedTangentData = subGeom.vertexTangentData.concat();
	}
}