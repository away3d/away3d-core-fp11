package away3d.core.base
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;

	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;

	use namespace arcane;

	/**
	 * SkinnedSubGeometry provides a SubGeometry extension that contains data needed to skin vertices. In particular,
	 * it provides joint indices and weights.
	 * Important! Joint indices need to be pre-multiplied by 3, since they index the matrix array (and each matrix has 3 float4 elements)
	 */
	public class SkinnedSubGeometry extends SubGeometry
	{
		private var _jointWeightsData : Vector.<Number>;
		private var _jointIndexData : Vector.<Number>;
		private var _animatedVertexData : Vector.<Number>;	// used for cpu fallback
		private var _animatedNormalData : Vector.<Number>;	// used for cpu fallback
		private var _animatedTangentData : Vector.<Number>;	// used for cpu fallback
		private var _jointWeightsBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		private var _jointIndexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);

		private var _jointWeightContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		private var _jointIndexContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		private var _jointsPerVertex : int;
		
		private var _condensedJointIndexData : Vector.<Number>;
		private var _condensedIndexLookUp : Vector.<uint>;	// used for linking condensed indices to the real ones
		private var _numCondensedJoints : uint;


		/**
		 * Creates a new SkinnedSubGeometry object.
		 * @param jointsPerVertex The amount of joints that can be assigned per vertex.
		 */
		public function SkinnedSubGeometry(jointsPerVertex : int)
		{
			super();
			_jointsPerVertex = jointsPerVertex;
		}

		/**
		 * If indices have been condensed, this will contain the original index for each condensed index.
		 */
		public function get condensedIndexLookUp() : Vector.<uint>
		{
			return _condensedIndexLookUp;
		}

		/**
		 * The amount of joints used when joint indices have been condensed.
		 */
		public function get numCondensedJoints() : uint
		{
			return _numCondensedJoints;
		}

		/**
		 * The animated vertex normals when set explicitly if the skinning transformations couldn't be performed on GPU.
		 */
		public function get animatedNormalData() : Vector.<Number>
		{
			return _animatedNormalData ||= new Vector.<Number>(_vertices.length, true);
		}

		public function set animatedNormalData(value : Vector.<Number>) : void
		{
			_animatedNormalData = value;
			invalidateBuffers(_vertexNormalBufferContext);
		}

		/**
		 * The animated vertex tangents when set explicitly if the skinning transformations couldn't be performed on GPU.
		 */
		public function get animatedTangentData() : Vector.<Number>
		{
			return _animatedTangentData ||= new Vector.<Number>(_vertices.length, true);
		}

		public function set animatedTangentData(value : Vector.<Number>) : void
		{
			_animatedTangentData = value;
			invalidateBuffers(_vertexTangentBufferContext);
		}

		/**
		 * The animated vertex positions when set explicitly if the skinning transformations couldn't be performed on GPU.
		 */
		public function get animatedVertexData() : Vector.<Number>
		{
			return _animatedVertexData ||= new Vector.<Number>(_vertices.length, true);
		}

		public function set animatedVertexData(value : Vector.<Number>) : void
		{
			_animatedVertexData = value;
			invalidateBuffers(_vertexBufferContext);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains joint weights.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains joint weights.
		 */
		public function getJointWeightsBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;
			if (_jointWeightContext[contextIndex] != context || !_jointWeightsBuffer[contextIndex]) {
				_jointWeightsBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
				_jointWeightsBuffer[contextIndex].uploadFromVector(_jointWeightsData, 0, _jointWeightsData.length / _jointsPerVertex);
				_jointWeightContext[contextIndex] = context;
			}
			return _jointWeightsBuffer[contextIndex];
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains joint indices.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains joint indices.
		 */
		public function getJointIndexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (_jointIndexContext[contextIndex] != context || !_jointIndexBuffer[contextIndex]) {
				_jointIndexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
				_jointIndexBuffer[contextIndex].uploadFromVector(_numCondensedJoints > 0? _condensedJointIndexData : _jointIndexData, 0, _jointIndexData.length / _jointsPerVertex);
				_jointIndexContext[contextIndex] = context;
			}
			return _jointIndexBuffer[contextIndex];
		}

		/**
		 * @inheritDoc
		 */
		override public function getVertexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (_animatedVertexData) {
				var contextIndex : int = stage3DProxy._stage3DIndex;
				var context : Context3D = stage3DProxy._context3D;
				if (_vertexBufferContext[contextIndex] != context || !_vertexBuffer[contextIndex]) {
					_vertexBuffer[contextIndex] = context.createVertexBuffer(_animatedVertexData.length / 3, 3);
					_vertexBuffer[contextIndex].uploadFromVector(_animatedVertexData, 0, _animatedVertexData.length / 3);
					_vertexBufferContext[contextIndex] = context;
				}
			    return _vertexBuffer[contextIndex];
			}
			else
				return super.getVertexBuffer(stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override public function getVertexNormalBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (_animatedNormalData) {
				var contextIndex : int = stage3DProxy._stage3DIndex;
				var context : Context3D = stage3DProxy._context3D;
				if (_vertexNormalBufferContext[contextIndex] != context || !_vertexNormalBuffer[contextIndex]) {
					_vertexNormalBuffer[contextIndex] = context.createVertexBuffer(_animatedNormalData.length / 3, 3)
					_vertexNormalBuffer[contextIndex].uploadFromVector(_animatedNormalData, 0, _animatedNormalData.length/3);
					_vertexNormalBufferContext[contextIndex] = context;
				}
			    return _vertexNormalBuffer[contextIndex];
			}
			else
				return super.getVertexNormalBuffer(stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override public function getVertexTangentBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (_animatedTangentData) {
				var contextIndex : int = stage3DProxy._stage3DIndex;
				var context : Context3D = stage3DProxy._context3D;
				if (_vertexTangentBufferContext[contextIndex] != context || !_vertexTangentBuffer[contextIndex]) {
					_vertexTangentBuffer[contextIndex] = context.createVertexBuffer(_animatedTangentData.length / 3, 3);
					_vertexTangentBuffer[contextIndex].uploadFromVector(_animatedTangentData, 0, _animatedTangentData.length/3);
					_vertexTangentBufferContext[contextIndex] = context;
				}
			    return _vertexTangentBuffer[contextIndex];
			}
			else
				return super.getVertexTangentBuffer(stage3DProxy);
		}
		/**
		 * Clones the current object.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone() : SubGeometry
		{
			var clone : SkinnedSubGeometry = new SkinnedSubGeometry(_jointsPerVertex);
			clone.updateVertexData(_vertices.concat());
			clone.updateUVData(_uvs.concat());
			clone.updateIndexData(_indices.concat());
			clone.updateJointIndexData(_jointIndexData.concat());
			clone.updateJointWeightsData(_jointWeightsData.concat());
			if (!autoDeriveVertexNormals) clone.updateVertexNormalData(_vertexNormals.concat());
			if (!autoDeriveVertexTangents) clone.updateVertexTangentData(_vertexTangents.concat());
			clone._numCondensedJoints = _numCondensedJoints;
			clone._condensedIndexLookUp = _condensedIndexLookUp;
			clone._condensedJointIndexData = _condensedJointIndexData;
			return clone;
		}

		/**
		 * Cleans up any resources used by this object.
		 */
		override public function dispose() : void
		{
			super.dispose();
			disposeVertexBuffers(_jointWeightsBuffer);
			disposeVertexBuffers(_jointIndexBuffer);
		}

		/**
		 */
		arcane function condenseIndexData() : void
		{
			var len : int = _jointIndexData.length;
			var oldIndex : int;
			var newIndex : int = 0;
			var dic : Dictionary = new Dictionary();

			_condensedJointIndexData = new Vector.<Number>(len, true);
			_condensedIndexLookUp = new Vector.<uint>();

			for (var i : int = 0; i < len; ++i) {
				oldIndex = _jointIndexData[i];

				// if we encounter a new index, assign it a new condensed index
				if (dic[oldIndex] == undefined) {
					dic[oldIndex] = newIndex;
					_condensedIndexLookUp[newIndex++] = oldIndex;
					_condensedIndexLookUp[newIndex++] = oldIndex+1;
					_condensedIndexLookUp[newIndex++] = oldIndex+2;
				}
				_condensedJointIndexData[i] = dic[oldIndex];
			}
			_numCondensedJoints = newIndex/3;

			invalidateBuffers(_jointIndexContext);
		}


		/**
		 * The raw joint weights data.
		 */
		arcane function get jointWeightsData() : Vector.<Number>
		{
			return _jointWeightsData;
		}

		arcane function updateJointWeightsData(value : Vector.<Number>) : void
		{
			// invalidate condensed stuff
			_numCondensedJoints = 0;
			_condensedIndexLookUp = null;
			_condensedJointIndexData = null;

			_jointWeightsData = value;
			invalidateBuffers(_jointWeightContext);
		}

		/**
		 * The raw joint index data.
		 */
		arcane function get jointIndexData() : Vector.<Number>
		{
			return _jointIndexData;
		}

		arcane function updateJointIndexData(value : Vector.<Number>) : void
		{
			_jointIndexData = value;
			invalidateBuffers(_jointIndexContext);
		}


		override protected function disposeForStage3D(stage3DProxy : Stage3DProxy) : void
		{
			super.disposeForStage3D(stage3DProxy);

			var index : int = stage3DProxy._stage3DIndex;
			if (_jointWeightsBuffer[index]) {
				_jointWeightsBuffer[index].dispose();
				_jointWeightsBuffer[index] = null;
			}
			if (_jointIndexBuffer[index]) {
				_jointIndexBuffer[index].dispose();
				_jointIndexBuffer[index] = null;
			}
		}
	}
}
