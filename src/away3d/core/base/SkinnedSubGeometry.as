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
	public class SkinnedSubGeometry extends CompactSubGeometry
	{
		private var _bufferFormat:String;
		private var _jointWeightsData:Vector.<Number>;
		private var _jointIndexData:Vector.<Number>;
		private var _animatedData:Vector.<Number>; // used for cpu fallback
		private var _jointWeightsBuffer:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		private var _jointIndexBuffer:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		private var _jointWeightsInvalid:Vector.<Boolean> = new Vector.<Boolean>(8, true);
		private var _jointIndicesInvalid:Vector.<Boolean> = new Vector.<Boolean>(8, true);
		private var _jointWeightContext:Vector.<Context3D> = new Vector.<Context3D>(8);
		private var _jointIndexContext:Vector.<Context3D> = new Vector.<Context3D>(8);
		private var _jointsPerVertex:int;
		
		private var _condensedJointIndexData:Vector.<Number>;
		private var _condensedIndexLookUp:Vector.<uint>; // used for linking condensed indices to the real ones
		private var _numCondensedJoints:uint;
		
		/**
		 * Creates a new SkinnedSubGeometry object.
		 * @param jointsPerVertex The amount of joints that can be assigned per vertex.
		 */
		public function SkinnedSubGeometry(jointsPerVertex:int)
		{
			super();
			_jointsPerVertex = jointsPerVertex;
			_bufferFormat = "float" + _jointsPerVertex;
		}
		
		/**
		 * If indices have been condensed, this will contain the original index for each condensed index.
		 */
		public function get condensedIndexLookUp():Vector.<uint>
		{
			return _condensedIndexLookUp;
		}
		
		/**
		 * The amount of joints used when joint indices have been condensed.
		 */
		public function get numCondensedJoints():uint
		{
			return _numCondensedJoints;
		}
		
		/**
		 * The animated vertex positions when set explicitly if the skinning transformations couldn't be performed on GPU.
		 */
		public function get animatedData():Vector.<Number>
		{
			return _animatedData || _vertexData.concat();
		}
		
		public function updateAnimatedData(value:Vector.<Number>):void
		{
			_animatedData = value;
			invalidateBuffers(_vertexDataInvalid);
		}
		
		/**
		 * Assigns the attribute stream for joint weights
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		public function activateJointWeightsBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			var contextIndex:int = stage3DProxy._stage3DIndex;
			var context:Context3D = stage3DProxy._context3D;
			if (_jointWeightContext[contextIndex] != context || !_jointWeightsBuffer[contextIndex]) {
				_jointWeightsBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
				_jointWeightContext[contextIndex] = context;
				_jointWeightsInvalid[contextIndex] = true;
			}
			if (_jointWeightsInvalid[contextIndex]) {
				_jointWeightsBuffer[contextIndex].uploadFromVector(_jointWeightsData, 0, _jointWeightsData.length/_jointsPerVertex);
				_jointWeightsInvalid[contextIndex] = false;
			}
			context.setVertexBufferAt(index, _jointWeightsBuffer[contextIndex], 0, _bufferFormat);
		}
		
		/**
		 * Assigns the attribute stream for joint indices
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		public function activateJointIndexBuffer(index:int, stage3DProxy:Stage3DProxy):void
		{
			var contextIndex:int = stage3DProxy._stage3DIndex;
			var context:Context3D = stage3DProxy._context3D;
			
			if (_jointIndexContext[contextIndex] != context || !_jointIndexBuffer[contextIndex]) {
				_jointIndexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
				_jointIndexContext[contextIndex] = context;
				_jointIndicesInvalid[contextIndex] = true;
			}
			if (_jointIndicesInvalid[contextIndex]) {
				_jointIndexBuffer[contextIndex].uploadFromVector(_numCondensedJoints > 0? _condensedJointIndexData : _jointIndexData, 0, _jointIndexData.length/_jointsPerVertex);
				_jointIndicesInvalid[contextIndex] = false;
			}
			context.setVertexBufferAt(index, _jointIndexBuffer[contextIndex], 0, _bufferFormat);
		}
		
		override protected function uploadData(contextIndex:int):void
		{
			if (_animatedData) {
				_activeBuffer.uploadFromVector(_animatedData, 0, _numVertices);
				_vertexDataInvalid[contextIndex] = _activeDataInvalid = false;
			} else
				super.uploadData(contextIndex);
		}
		
		/**
		 * Clones the current object.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone():ISubGeometry
		{
			var clone:SkinnedSubGeometry = new SkinnedSubGeometry(_jointsPerVertex);
			clone.updateData(_vertexData.concat());
			clone.updateIndexData(_indices.concat());
			clone.updateJointIndexData(_jointIndexData.concat());
			clone.updateJointWeightsData(_jointWeightsData.concat());
			clone._autoDeriveVertexNormals = _autoDeriveVertexNormals;
			clone._autoDeriveVertexTangents = _autoDeriveVertexTangents;
			clone._numCondensedJoints = _numCondensedJoints;
			clone._condensedIndexLookUp = _condensedIndexLookUp;
			clone._condensedJointIndexData = _condensedJointIndexData;
			return clone;
		}
		
		/**
		 * Cleans up any resources used by this object.
		 */
		override public function dispose():void
		{
			super.dispose();
			disposeVertexBuffers(_jointWeightsBuffer);
			disposeVertexBuffers(_jointIndexBuffer);
		}
		
		/**
		 */
		arcane function condenseIndexData():void
		{
			var len:int = _jointIndexData.length;
			var oldIndex:int;
			var newIndex:int = 0;
			var dic:Dictionary = new Dictionary();
			
			_condensedJointIndexData = new Vector.<Number>(len, true);
			_condensedIndexLookUp = new Vector.<uint>();
			
			for (var i:int = 0; i < len; ++i) {
				oldIndex = _jointIndexData[i];
				
				// if we encounter a new index, assign it a new condensed index
				if (dic[oldIndex] == undefined) {
					dic[oldIndex] = newIndex;
					_condensedIndexLookUp[newIndex++] = oldIndex;
					_condensedIndexLookUp[newIndex++] = oldIndex + 1;
					_condensedIndexLookUp[newIndex++] = oldIndex + 2;
				}
				_condensedJointIndexData[i] = dic[oldIndex];
			}
			_numCondensedJoints = newIndex/3;
			
			invalidateBuffers(_jointIndicesInvalid);
		}
		
		/**
		 * The raw joint weights data.
		 */
		arcane function get jointWeightsData():Vector.<Number>
		{
			return _jointWeightsData;
		}
		
		arcane function updateJointWeightsData(value:Vector.<Number>):void
		{
			// invalidate condensed stuff
			_numCondensedJoints = 0;
			_condensedIndexLookUp = null;
			_condensedJointIndexData = null;
			
			_jointWeightsData = value;
			invalidateBuffers(_jointWeightsInvalid);
		}
		
		/**
		 * The raw joint index data.
		 */
		arcane function get jointIndexData():Vector.<Number>
		{
			return _jointIndexData;
		}
		
		arcane function updateJointIndexData(value:Vector.<Number>):void
		{
			_jointIndexData = value;
			invalidateBuffers(_jointIndicesInvalid);
		}
	}
}
