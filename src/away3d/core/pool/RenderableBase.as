package away3d.core.pool
{
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.SubGeometryBase;
	import away3d.entities.IEntity;
	import away3d.errors.AbstractMethodError;
	import away3d.events.SubGeometryEvent;
	import away3d.materials.MaterialBase;

	import flash.geom.Matrix3D;

	use namespace arcane;

	public class RenderableBase implements IRenderable
	{
		public var cascaded:Boolean;
		public var renderSceneTransform:Matrix3D;
		public var material:MaterialBase;

		protected var _vertexDataDirty:Object = {};

		private var _subGeometry:SubGeometryBase;
		private var _geometryDirty:Boolean = true;
		private var _indexData:IndexData;
		private var _indexDataDirty:Boolean = true;
		private var _vertexData:Object = {};
		private var _vertexOffset:Object = {};

		private var _next:IRenderable;
		private var _materialId:int;
		private var _renderOrderId:int;
		private var _zIndex:Number;
		private var _materialOwner:IMaterialOwner;
		private var _sourceEntity:IEntity;

		private var _level:Number;
		private var _indexOffset:Number;
		private var _overflow:RenderableBase;
		private var _numTriangles:Number;
		private var _concatenateArrays:Boolean;
		private var _pool:RenderablePool;

		public function get overflow():RenderableBase
		{
			if (_indexDataDirty)
				updateIndexData();

			return _overflow;
		}


		public function get numTriangles():Number
		{
			return _numTriangles;
		}

		public function getIndexData():IndexData
		{
			if (_indexDataDirty)
				updateIndexData();

			return _indexData;
		}

		public function getVertexData(dataType:String):VertexData
		{
			if (_indexDataDirty)
				updateIndexData();

			if (_vertexDataDirty[dataType])
				updateVertexData(dataType);

			var key:String = _concatenateArrays ? SubGeometryBase.VERTEX_DATA : dataType;
			return _vertexData[key];
		}

		/**
		 *
		 */
		public function getVertexOffset(dataType:String):Number
		{
			if (_indexDataDirty)
				updateIndexData();

			if (_vertexDataDirty[dataType])
				updateVertexData(dataType);

			return _vertexOffset[dataType];
		}

		public function RenderableBase(pool:RenderablePool, sourceEntity:IEntity, materialOwner:IMaterialOwner, level:Number = 0, indexOffset:Number = 0)
		{
			_pool = pool;

			//reference to level of overflow
			_level = level;

			//reference to the offset on indices (if this is an overflow renderable)
			_indexOffset = indexOffset;

			this._sourceEntity = sourceEntity;
			this._materialOwner = materialOwner;
		}

		public function dispose():void
		{
			_pool.disposeItem(_materialOwner);

			_indexData.dispose();
			_indexData = null;

			for (var dataType:* in _vertexData) {
				(_vertexData[dataType] as VertexData).dispose();
				_vertexData[dataType] = null;
			}

			if (_overflow) {
				_overflow.dispose();
				_overflow = null;
			}
		}

		public function invalidateGeometry():void
		{
			_geometryDirty = true;

			//invalidate indices
			if (_level == 0)
				_indexDataDirty = true;

			if (_overflow)
				_overflow.invalidateGeometry();
		}

		public function invalidateIndexData():void
		{
			_indexDataDirty = true;
		}

		public function invalidateVertexData(dataType:String):void
		{
			_vertexDataDirty[dataType] = true;
		}

		protected function getSubGeometry():SubGeometryBase
		{
			throw new AbstractMethodError();
		}

		arcane function fillIndexData(indexOffset:Number):void
		{
			if (_geometryDirty)
				updateGeometry();

			_indexData = IndexDataPool.getItem(_subGeometry, _level, indexOffset);

			_numTriangles = _indexData.data.length / 3;

			indexOffset = _indexData.offset;

			//check if there is more to split
			if (indexOffset < _subGeometry.indices.length) {
				if (!_overflow)
					_overflow = getOverflowRenderable(_pool, _materialOwner, indexOffset, _level + 1);

				_overflow.fillIndexData(indexOffset);
			} else
				if (_overflow) {
					_overflow.dispose();
					_overflow = null;
				}
		}

		protected function getOverflowRenderable(pool:RenderablePool, materialOwner:IMaterialOwner, level:Number, indexOffset:Number):RenderableBase
		{
			throw new AbstractMethodError();
		}

		/**
		 * //TODO
		 *
		 * @private
		 */
		private function updateGeometry():void
		{
			if (_subGeometry) {
				if (_level == 0)
					_subGeometry.removeEventListener(SubGeometryEvent.INDICES_UPDATED, onIndicesUpdated);
				_subGeometry.removeEventListener(SubGeometryEvent.VERTICES_UPDATED, onVerticesUpdated);
			}

			_subGeometry = getSubGeometry();

			_concatenateArrays = _subGeometry.concatenateArrays;

			if (_subGeometry) {
				if (_level == 0)
					_subGeometry.addEventListener(SubGeometryEvent.INDICES_UPDATED, onIndicesUpdated);
				_subGeometry.addEventListener(SubGeometryEvent.VERTICES_UPDATED, onVerticesUpdated);
			}

			//dispose
			//			if (_indexData) {
			//				_indexData.dispose(); //TODO where is a good place to dispose?
			//				_indexData = null;
			//			}

			//			for (var dataType in _vertexData) {
			//				(<VertexData> _vertexData[dataType]).dispose(); //TODO where is a good place to dispose?
			//				_vertexData[dataType] = null;
			//			}

			_geometryDirty = false;

			//specific vertex data types have to be invalidated in the specific renderable
		}

		/**
		 * //TODO
		 *
		 * @private
		 */
		private function updateIndexData():void
		{
			fillIndexData(_indexOffset);
			_indexDataDirty = false;
		}

		/**
		 * //TODO
		 *
		 * @param dataType
		 * @private
		 */
		private function updateVertexData(dataType:String):void
		{
			_vertexOffset[dataType] = _subGeometry.getOffset(dataType);

			if (_subGeometry.concatenateArrays)
				dataType = SubGeometryBase.VERTEX_DATA;

			_vertexData[dataType] = VertexDataPool.getItem(_subGeometry, getIndexData(), dataType);

			_vertexDataDirty[dataType] = false;
		}

		/**
		 * //TODO
		 *
		 * @param event
		 * @private
		 */
		private function onIndicesUpdated(event:SubGeometryEvent):void
		{
			invalidateIndexData();
		}

		/**
		 * //TODO
		 *
		 * @param event
		 * @private
		 */
		private function onVerticesUpdated(event:SubGeometryEvent):void
		{
			_concatenateArrays = (event.target as SubGeometryBase).concatenateArrays;
			invalidateVertexData(event.dataType);
		}

		public function get materialId():int
		{
			return _materialId;
		}

		public function set materialId(value:int):void
		{
			_materialId = value;
		}

		public function get renderOrderId():int
		{
			return _renderOrderId;
		}

		public function set renderOrderId(value:int):void
		{
			_renderOrderId = value;
		}

		public function get materialOwner():IMaterialOwner
		{
			return _materialOwner;
		}

		public function set materialOwner(value:IMaterialOwner):void
		{
			_materialOwner = value;
		}

		public function get next():IRenderable
		{
			return _next;
		}

		public function set next(value:IRenderable):void
		{
			_next = value;
		}

		public function get sourceEntity():IEntity
		{
			return _sourceEntity;
		}

		public function set sourceEntity(value:IEntity):void
		{
			_sourceEntity = value;
		}

		public function get zIndex():Number
		{
			return _zIndex;
		}

		public function set zIndex(value:Number):void
		{
			_zIndex = value;
		}
	}
}