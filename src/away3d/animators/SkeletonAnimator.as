package away3d.animators
{
	import away3d.animators.data.JointPose;
	import away3d.animators.data.Skeleton;
	import away3d.animators.data.SkeletonJoint;
	import away3d.animators.data.SkeletonPose;
	import away3d.animators.states.ISkeletonAnimationState;
	import away3d.animators.transitions.IAnimationTransition;
	import away3d.arcane;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Quaternion;
	import away3d.core.pool.IRenderable;
	import away3d.core.pool.RenderableBase;
	import away3d.core.pool.TriangleSubMeshRenderable;
	import away3d.entities.Camera3D;
	import away3d.events.AnimationStateEvent;
	import away3d.events.SubGeometryEvent;
	import away3d.materials.passes.MaterialPassBase;

	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;

	use namespace arcane;
	
	/**
	 * Provides an interface for assigning skeleton-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	public class SkeletonAnimator extends AnimatorBase implements IAnimator
	{
		private var _globalMatrices:Vector.<Number>;
		private var _globalPose:SkeletonPose = new SkeletonPose();
		private var _globalPropertiesDirty:Boolean;
		private var _numJoints:uint;
		private var _morphedSubGeometry:Object = {};
		private var _morphedSubGeometryDirty:Object = {};
		private var _condensedMatrices:Vector.<Number>;
		
		private var _skeleton:Skeleton;
		private var _forceCPU:Boolean;
		private var _useCondensedIndices:Boolean;
		private var _jointsPerVertex:uint;
		private var _activeSkeletonState:ISkeletonAnimationState;
		
		/**
		 * returns the calculated global matrices of the current skeleton pose.
		 *
		 * @see #globalPose
		 */
		public function get globalMatrices():Vector.<Number>
		{
			if (_globalPropertiesDirty)
				updateGlobalProperties();
			
			return _globalMatrices;
		}
		
		/**
		 * returns the current skeleton pose output from the animator.
		 *
		 * @see away3d.animators.data.SkeletonPose
		 */
		public function get globalPose():SkeletonPose
		{
			if (_globalPropertiesDirty)
				updateGlobalProperties();
			
			return _globalPose;
		}
		
		/**
		 * Returns the skeleton object in use by the animator - this defines the number and heirarchy of joints used by the
		 * skinned geoemtry to which skeleon animator is applied.
		 */
		public function get skeleton():Skeleton
		{
			return _skeleton;
		}
		
		/**
		 * Indicates whether the skeleton animator is disabled by default for GPU rendering, something that allows the animator to perform calculation on the GPU.
		 * Defaults to false.
		 */
		public function get forceCPU():Boolean
		{
			return _forceCPU;
		}
		
		/**
		 * Offers the option of enabling GPU accelerated animation on skeletons larger than 32 joints
		 * by condensing the number of joint index values required per mesh. Only applicable to
		 * skeleton animations that utilise more than one mesh object. Defaults to false.
		 */
		public function get useCondensedIndices():Boolean
		{
			return _useCondensedIndices;
		}
		
		public function set useCondensedIndices(value:Boolean):void
		{
			_useCondensedIndices = value;
		}
		
		/**
		 * Creates a new <code>SkeletonAnimator</code> object.
		 *
		 * @param skeletonAnimationSet The animation data set containing the skeleton animations used by the animator.
		 * @param skeleton The skeleton object used for calculating the resulting global matrices for transforming skinned mesh data.
		 * @param forceCPU Optional value that only allows the animator to perform calculation on the CPU. Defaults to false.
		 */
		public function SkeletonAnimator(animationSet:SkeletonAnimationSet, skeleton:Skeleton, forceCPU:Boolean = false)
		{
			super(animationSet);
			
			_skeleton = skeleton;
			_forceCPU = forceCPU;
			_jointsPerVertex = animationSet.jointsPerVertex;
			
			_numJoints = _skeleton.numJoints;
			_globalMatrices = new Vector.<Number>(_numJoints*12, true);
			
			var j:int;
			for (var i:uint = 0; i < _numJoints; ++i) {
				_globalMatrices[j++] = 1;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 1;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 0;
				_globalMatrices[j++] = 1;
				_globalMatrices[j++] = 0;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():IAnimator
		{
			/* The cast to SkeletonAnimationSet should never fail, as _animationSet can only be set
			 through the constructor, which will only accept a SkeletonAnimationSet. */
			return new SkeletonAnimator(_animationSet as SkeletonAnimationSet, _skeleton, _forceCPU);
		}
		
		/**
		 * Plays an animation state registered with the given name in the animation data set.
		 *
		 * @param name The data set name of the animation state to be played.
		 * @param transition An optional transition object that determines how the animator will transition from the currently active animation state.
		 * @param offset An option offset time (in milliseconds) that resets the state's internal clock to the absolute time of the animator plus the offset value. Required for non-looping animation states.
		 */
		public function play(name:String, transition:IAnimationTransition = null, offset:Number = NaN):void
		{
			if (_activeAnimationName != name) {
				_activeAnimationName = name;
				
				if (!_animationSet.hasAnimation(name))
					throw new Error("Animation root node " + name + " not found!");
				
				if (transition && _activeNode) {
					//setup the transition
					_activeNode = transition.getAnimationNode(this, _activeNode, _animationSet.getAnimation(name), _absoluteTime);
					_activeNode.addEventListener(AnimationStateEvent.TRANSITION_COMPLETE, onTransitionComplete);
				} else
					_activeNode = _animationSet.getAnimation(name);
				
				_activeState = getAnimationState(_activeNode);
				
				if (updatePosition) {
					//update straight away to reset position deltas
					_activeState.update(_absoluteTime);
					_activeState.positionDelta;
				}
				
				_activeSkeletonState = _activeState as ISkeletonAnimationState;
			}
			
			start();
			
			//apply a time offset if specified
			if (!isNaN(offset))
				reset(name, offset);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:RenderableBase, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		{
			// do on request of globalProperties
			if (_globalPropertiesDirty)
				updateGlobalProperties();
			
			var subGeometry:TriangleSubGeometry = (renderable as TriangleSubMeshRenderable).subMesh.subGeometry as TriangleSubGeometry;
			subGeometry.useCondensedIndices = _useCondensedIndices;

			if (_useCondensedIndices) {
				updateCondensedMatrices(subGeometry.condensedIndexLookUp, subGeometry.numCondensedJoints);
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _condensedMatrices, subGeometry.numCondensedJoints*3);
			} else {
				if (_animationSet.usesCPU) {
					if (_morphedSubGeometryDirty[subGeometry.id]) {
						morphSubGeometry(renderable as TriangleSubMeshRenderable, subGeometry);
					}
					return;
				}
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _globalMatrices, _numJoints*3);
			}

			stage3DProxy.activateBuffer(vertexStreamOffset, renderable.getVertexData(TriangleSubGeometry.JOINT_INDEX_DATA), renderable.getVertexOffset(TriangleSubGeometry.JOINT_INDEX_DATA), renderable.JOINT_INDEX_FORMAT);
			stage3DProxy.activateBuffer(vertexStreamOffset + 1, renderable.getVertexData(TriangleSubGeometry.JOINT_WEIGHT_DATA), renderable.getVertexOffset(TriangleSubGeometry.JOINT_WEIGHT_DATA), renderable.JOINT_WEIGHT_FORMAT);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function testGPUCompatibility(pass:MaterialPassBase):void
		{
			if (!_useCondensedIndices && (_forceCPU || _jointsPerVertex > 4 || pass.numUsedVertexConstants + _numJoints*3 > 128))
				_animationSet.cancelGPUCompatibility();
		}
		
		/**
		 * Applies the calculated time delta to the active animation state node or state transition object.
		 */
		override protected function updateDeltaTime(dt:Number):void
		{
			super.updateDeltaTime(dt);
			
			//invalidate pose matrices
			_globalPropertiesDirty = true;

			//trigger geometry invalidation if using CPU animation
			if (_animationSet.usesCPU) {
				for (var key:* in _morphedSubGeometryDirty) {
					_morphedSubGeometryDirty[key] = true;
				}
			}
		}
		
		private function updateCondensedMatrices(condensedIndexLookUp:Vector.<uint>, numJoints:uint):void
		{
			var i:uint = 0, j:uint = 0;
			var len:uint;
			var srcIndex:uint;
			
			_condensedMatrices = new Vector.<Number>();
			
			do {
				srcIndex = condensedIndexLookUp[i]*4;
				len = srcIndex + 12;
				// copy into condensed
				while (srcIndex < len)
					_condensedMatrices[j++] = _globalMatrices[srcIndex++];
			} while (++i < numJoints);
		}
		
		private function updateGlobalProperties():void
		{
			_globalPropertiesDirty = false;
			
			//get global pose
			localToGlobalPose(_activeSkeletonState.getSkeletonPose(_skeleton), _globalPose, _skeleton);
			
			// convert pose to matrix
			var mtxOffset:uint;
			var globalPoses:Vector.<JointPose> = _globalPose.jointPoses;
			var raw:Vector.<Number>;
			var ox:Number, oy:Number, oz:Number, ow:Number;
			var xy2:Number, xz2:Number, xw2:Number;
			var yz2:Number, yw2:Number, zw2:Number;
			var n11:Number, n12:Number, n13:Number;
			var n21:Number, n22:Number, n23:Number;
			var n31:Number, n32:Number, n33:Number;
			var m11:Number, m12:Number, m13:Number, m14:Number;
			var m21:Number, m22:Number, m23:Number, m24:Number;
			var m31:Number, m32:Number, m33:Number, m34:Number;
			var joints:Vector.<SkeletonJoint> = _skeleton.joints;
			var pose:JointPose;
			var quat:Quaternion;
			var vec:Vector3D;
			var t:Number;
			
			for (var i:uint = 0; i < _numJoints; ++i) {
				pose = globalPoses[i];
				quat = pose.orientation;
				vec = pose.translation;
				ox = quat.x;
				oy = quat.y;
				oz = quat.z;
				ow = quat.w;
				
				xy2 = (t = 2.0*ox)*oy;
				xz2 = t*oz;
				xw2 = t*ow;
				yz2 = (t = 2.0*oy)*oz;
				yw2 = t*ow;
				zw2 = 2.0*oz*ow;
				
				yz2 = 2.0*oy*oz;
				yw2 = 2.0*oy*ow;
				zw2 = 2.0*oz*ow;
				ox *= ox;
				oy *= oy;
				oz *= oz;
				ow *= ow;
				
				n11 = (t = ox - oy) - oz + ow;
				n12 = xy2 - zw2;
				n13 = xz2 + yw2;
				n21 = xy2 + zw2;
				n22 = -t - oz + ow;
				n23 = yz2 - xw2;
				n31 = xz2 - yw2;
				n32 = yz2 + xw2;
				n33 = -ox - oy + oz + ow;
				
				// prepend inverse bind pose
				raw = joints[i].inverseBindPose;
				m11 = raw[0];
				m12 = raw[4];
				m13 = raw[8];
				m14 = raw[12];
				m21 = raw[1];
				m22 = raw[5];
				m23 = raw[9];
				m24 = raw[13];
				m31 = raw[2];
				m32 = raw[6];
				m33 = raw[10];
				m34 = raw[14];
				
				_globalMatrices[uint(mtxOffset)] = n11*m11 + n12*m21 + n13*m31;
				_globalMatrices[uint(mtxOffset + 1)] = n11*m12 + n12*m22 + n13*m32;
				_globalMatrices[uint(mtxOffset + 2)] = n11*m13 + n12*m23 + n13*m33;
				_globalMatrices[uint(mtxOffset + 3)] = n11*m14 + n12*m24 + n13*m34 + vec.x;
				_globalMatrices[uint(mtxOffset + 4)] = n21*m11 + n22*m21 + n23*m31;
				_globalMatrices[uint(mtxOffset + 5)] = n21*m12 + n22*m22 + n23*m32;
				_globalMatrices[uint(mtxOffset + 6)] = n21*m13 + n22*m23 + n23*m33;
				_globalMatrices[uint(mtxOffset + 7)] = n21*m14 + n22*m24 + n23*m34 + vec.y;
				_globalMatrices[uint(mtxOffset + 8)] = n31*m11 + n32*m21 + n33*m31;
				_globalMatrices[uint(mtxOffset + 9)] = n31*m12 + n32*m22 + n33*m32;
				_globalMatrices[uint(mtxOffset + 10)] = n31*m13 + n32*m23 + n33*m33;
				_globalMatrices[uint(mtxOffset + 11)] = n31*m14 + n32*m24 + n33*m34 + vec.z;
				
				mtxOffset = uint(mtxOffset + 12);
			}
		}

		override public function getRenderableSubGeometry(renderable:IRenderable, sourceSubGeometry:SubGeometryBase):SubGeometryBase
		{
			this._morphedSubGeometryDirty[sourceSubGeometry.id] = true;

			//early out for GPU animations
			if (!_animationSet.usesCPU)
				return sourceSubGeometry;

			var targetSubGeometry:TriangleSubGeometry;

			if (!(targetSubGeometry = _morphedSubGeometry[sourceSubGeometry.id])) {
				//not yet stored
				targetSubGeometry = _morphedSubGeometry[sourceSubGeometry.id] = sourceSubGeometry.clone();
				//turn off auto calculations on the morphed geometry
				targetSubGeometry.autoDeriveNormals = false;
				targetSubGeometry.autoDeriveTangents = false;
				targetSubGeometry.autoDeriveUVs = false;
				//add event listeners for any changes in UV values on the source geometry
				sourceSubGeometry.addEventListener(SubGeometryEvent.INDICES_UPDATED, onIndicesUpdate);
				sourceSubGeometry.addEventListener(SubGeometryEvent.VERTICES_UPDATED, onVerticesUpdate);
			}

			return targetSubGeometry;
		}
		/**
		 * If the animation can't be performed on GPU, transform vertices manually
		 * @param subGeom The subgeometry containing the weights and joint index data per vertex.
		 * @param pass The material pass for which we need to transform the vertices
		 */
		public function morphSubGeometry(renderable:TriangleSubMeshRenderable, sourceSubGeometry:TriangleSubGeometry):void
		{
			this._morphedSubGeometryDirty[sourceSubGeometry.id] = false;

			var sourcePositions:Vector.<Number> = sourceSubGeometry.positions;
			var sourceNormals:Vector.<Number> = sourceSubGeometry.vertexNormals;
			var sourceTangents:Vector.<Number> = sourceSubGeometry.vertexTangents;

			var jointIndices:Vector.<Number> = sourceSubGeometry.jointIndices;
			var jointWeights:Vector.<Number> = sourceSubGeometry.jointWeights;

			var targetSubGeometry = this._morphedSubGeometry[sourceSubGeometry.id];

			var targetPositions:Vector.<Number> = targetSubGeometry.positions;
			var targetNormals:Vector.<Number> = targetSubGeometry.vertexNormals;
			var targetTangents:Vector.<Number> = targetSubGeometry.vertexTangents;
			
			var index:uint = 0;
			var j:uint, k:uint;
			var vx:Number, vy:Number, vz:Number;
			var nx:Number, ny:Number, nz:Number;
			var tx:Number, ty:Number, tz:Number;
			var len:int = sourcePositions.length;
			var weight:Number;
			var vertX:Number, vertY:Number, vertZ:Number;
			var normX:Number, normY:Number, normZ:Number;
			var tangX:Number, tangY:Number, tangZ:Number;
			var m11:Number, m12:Number, m13:Number, m14:Number;
			var m21:Number, m22:Number, m23:Number, m24:Number;
			var m31:Number, m32:Number, m33:Number, m34:Number;
			
			while (index < len) {
				vertX = sourcePositions[index];
				vertY = sourcePositions[index + 1];
				vertZ = sourcePositions[index + 2];
				normX = sourceNormals[index];
				normY = sourceNormals[index + 1];
				normZ = sourceNormals[index + 2];
				tangX = sourceTangents[index];
				tangY = sourceTangents[index + 1];
				tangZ = sourceTangents[index + 2];
				vx = 0;
				vy = 0;
				vz = 0;
				nx = 0;
				ny = 0;
				nz = 0;
				tx = 0;
				ty = 0;
				tz = 0;
				k = 0;
				while (k < _jointsPerVertex) {
					weight = jointWeights[j];
					if (weight > 0) {
						// implicit /3*12 (/3 because indices are multiplied by 3 for gpu matrix access, *12 because it's the matrix size)
						var mtxOffset:uint = uint(jointIndices[j++]) << 2;
						m11 = _globalMatrices[mtxOffset];
						m12 = _globalMatrices[uint(mtxOffset + 1)];
						m13 = _globalMatrices[uint(mtxOffset + 2)];
						m14 = _globalMatrices[uint(mtxOffset + 3)];
						m21 = _globalMatrices[uint(mtxOffset + 4)];
						m22 = _globalMatrices[uint(mtxOffset + 5)];
						m23 = _globalMatrices[uint(mtxOffset + 6)];
						m24 = _globalMatrices[uint(mtxOffset + 7)];
						m31 = _globalMatrices[uint(mtxOffset + 8)];
						m32 = _globalMatrices[uint(mtxOffset + 9)];
						m33 = _globalMatrices[uint(mtxOffset + 10)];
						m34 = _globalMatrices[uint(mtxOffset + 11)];
						vx += weight*(m11*vertX + m12*vertY + m13*vertZ + m14);
						vy += weight*(m21*vertX + m22*vertY + m23*vertZ + m24);
						vz += weight*(m31*vertX + m32*vertY + m33*vertZ + m34);
						nx += weight*(m11*normX + m12*normY + m13*normZ);
						ny += weight*(m21*normX + m22*normY + m23*normZ);
						nz += weight*(m31*normX + m32*normY + m33*normZ);
						tx += weight*(m11*tangX + m12*tangY + m13*tangZ);
						ty += weight*(m21*tangX + m22*tangY + m23*tangZ);
						tz += weight*(m31*tangX + m32*tangY + m33*tangZ);
						++k;
					} else {
						j += uint(_jointsPerVertex - k);
						k = _jointsPerVertex;
					}
				}

				targetPositions[index] = vx;
				targetPositions[index + 1] = vy;
				targetPositions[index + 2] = vz;
				targetNormals[index] = nx;
				targetNormals[index + 1] = ny;
				targetNormals[index + 2] = nz;
				targetTangents[index] = tx;
				targetTangents[index + 1] = ty;
				targetTangents[index + 2] = tz;
				
				index = 3;
			}

			targetSubGeometry.updatePositions(targetPositions);
			targetSubGeometry.updateVertexNormals(targetNormals);
			targetSubGeometry.updateVertexTangents(targetTangents);
		}
		
		/**
		 * Converts a local hierarchical skeleton pose to a global pose
		 * @param targetPose The SkeletonPose object that will contain the global pose.
		 * @param skeleton The skeleton containing the joints, and as such, the hierarchical data to transform to global poses.
		 */
		private function localToGlobalPose(sourcePose:SkeletonPose, targetPose:SkeletonPose, skeleton:Skeleton):void
		{
			var globalPoses:Vector.<JointPose> = targetPose.jointPoses;
			var globalJointPose:JointPose;
			var joints:Vector.<SkeletonJoint> = skeleton.joints;
			var len:uint = sourcePose.numJointPoses;
			var jointPoses:Vector.<JointPose> = sourcePose.jointPoses;
			var parentIndex:int;
			var joint:SkeletonJoint;
			var parentPose:JointPose;
			var pose:JointPose;
			var or:Quaternion;
			var tr:Vector3D;
			var t:Vector3D;
			var q:Quaternion;
			
			var x1:Number, y1:Number, z1:Number, w1:Number;
			var x2:Number, y2:Number, z2:Number, w2:Number;
			var x3:Number, y3:Number, z3:Number;
			
			// :s
			if (globalPoses.length != len)
				globalPoses.length = len;
			
			for (var i:uint = 0; i < len; ++i) {
				globalJointPose = globalPoses[i] ||= new JointPose();
				joint = joints[i];
				parentIndex = joint.parentIndex;
				pose = jointPoses[i];
				
				q = globalJointPose.orientation;
				t = globalJointPose.translation;
				
				if (parentIndex < 0) {
					tr = pose.translation;
					or = pose.orientation;
					q.x = or.x;
					q.y = or.y;
					q.z = or.z;
					q.w = or.w;
					t.x = tr.x;
					t.y = tr.y;
					t.z = tr.z;
				} else {
					// append parent pose
					parentPose = globalPoses[parentIndex];
					
					// rotate point
					or = parentPose.orientation;
					tr = pose.translation;
					x2 = or.x;
					y2 = or.y;
					z2 = or.z;
					w2 = or.w;
					x3 = tr.x;
					y3 = tr.y;
					z3 = tr.z;
					
					w1 = -x2*x3 - y2*y3 - z2*z3;
					x1 = w2*x3 + y2*z3 - z2*y3;
					y1 = w2*y3 - x2*z3 + z2*x3;
					z1 = w2*z3 + x2*y3 - y2*x3;
					
					// append parent translation
					tr = parentPose.translation;
					t.x = -w1*x2 + x1*w2 - y1*z2 + z1*y2 + tr.x;
					t.y = -w1*y2 + x1*z2 + y1*w2 - z1*x2 + tr.y;
					t.z = -w1*z2 - x1*y2 + y1*x2 + z1*w2 + tr.z;
					
					// append parent orientation
					x1 = or.x;
					y1 = or.y;
					z1 = or.z;
					w1 = or.w;
					or = pose.orientation;
					x2 = or.x;
					y2 = or.y;
					z2 = or.z;
					w2 = or.w;
					
					q.w = w1*w2 - x1*x2 - y1*y2 - z1*z2;
					q.x = w1*x2 + x1*w2 + y1*z2 - z1*y2;
					q.y = w1*y2 - x1*z2 + y1*w2 + z1*x2;
					q.z = w1*z2 + x1*y2 - y1*x2 + z1*w2;
				}
			}
		}
		
		private function onTransitionComplete(event:AnimationStateEvent):void
		{
			if (event.type == AnimationStateEvent.TRANSITION_COMPLETE) {
				event.animationNode.removeEventListener(AnimationStateEvent.TRANSITION_COMPLETE, onTransitionComplete);
				//if this is the current active state transition, revert control to the active node
				if (_activeState == event.animationState) {
					_activeNode = _animationSet.getAnimation(_activeAnimationName);
					_activeState = getAnimationState(_activeNode);
					_activeSkeletonState = _activeState as ISkeletonAnimationState;
				}
			}
		}

		private function onIndicesUpdate(event:SubGeometryEvent):void
		{
			var subGeometry:TriangleSubGeometry = event.target as TriangleSubGeometry;
			(_morphedSubGeometry[subGeometry.id] as TriangleSubGeometry).updateIndices(subGeometry.indices);
		}

		private function onVerticesUpdate(event:SubGeometryEvent):void
		{
			var subGeometry:TriangleSubGeometry = event.target as TriangleSubGeometry;
			var morphGeometry:TriangleSubGeometry = _morphedSubGeometry[subGeometry.id] as TriangleSubGeometry;
			if(event.dataType == TriangleSubGeometry.UV_DATA) {
				morphGeometry.updateUVs(subGeometry.uvs);
			}else if(event.dataType == TriangleSubGeometry.SECONDARY_UV_DATA) {
				morphGeometry.updateUVs(subGeometry.secondaryUVs);
			}
		}
	}
}