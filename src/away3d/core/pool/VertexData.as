package away3d.core.pool {
	import away3d.core.base.SubGeometryBase;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.SubGeometryEvent;

	public class VertexData {
		public var invalid:Vector.<Boolean> = new Vector.<Boolean>(8);
		public var buffers:Array = [];
		public var stage3Ds:Vector.<Stage3DProxy> = new Vector.<Stage3DProxy>(8);
		public var data:Vector.<Number> = new Vector.<Number>();
		public var dataPerVertex:int;

		private var _subGeometry:SubGeometryBase;
		private var _dataType:String;
		private var _dataDirty:Boolean = true;

		public function VertexData(subGeometry:SubGeometryBase, dataType:String) {
			_dataType = dataType;

			_subGeometry = subGeometry;
			_subGeometry.addEventListener(SubGeometryEvent.VERTICES_UPDATED, onVerticesUpdated);
		}

		public function updateData(originalIndices:Vector.<uint> = null, indexMappings:Vector.<uint> = null):void {
			if(!_dataDirty) return;
			_dataDirty = false;

			dataPerVertex = _subGeometry.getStride(_dataType);

			var vertices:Vector.<Number> = _subGeometry[_dataType];

			if (!indexMappings) {
				setData(vertices);
			} else {
				var splitVerts:Vector.<Number> = new Vector.<Number>(originalIndices.length*dataPerVertex);
				var originalIndex:uint;
				var splitIndex:uint;
				var i:uint = 0;
				var j:uint = 0;
				var len:uint = originalIndices.length;
				while(i < len) {
					originalIndex = originalIndices[i];
					splitIndex = indexMappings[originalIndex]*dataPerVertex;
					originalIndex *= dataPerVertex;
					for (j = 0; j < dataPerVertex; j++) {
						splitVerts[splitIndex + j] = vertices[originalIndex + j];
					}
					i++;
				}
				setData(splitVerts);
			}
		}
		public function dispose():void
		{
			for (var i:uint = 0; i < 8; ++i) {
				if (!stage3Ds[i]) continue;
				stage3Ds[i].disposeVertexData(this);
				stage3Ds[i] = null;
			}
		}
		/**
		 * @private
		 */
		private function disposeBuffers():void
		{
			for (var i:uint = 0; i < 8; ++i) {
				if (!buffers[i]) continue;
				buffers[i].dispose();
				buffers[i] = null;
			}
		}

		/**
		 * @private
		 */
		private function invalidateBuffers():void
		{
			for (var i:uint = 0; i < 8; ++i) {
				invalid[i] = true;
			}
		}

		private function setData(data:Vector.<Number>):void
		{
			if (data && data.length != data.length) {
				disposeBuffers();
			}else{
				invalidateBuffers();
			}
			this.data = data;
		}


		private function onVerticesUpdated(event:SubGeometryEvent):void {
			var dataType:String = _subGeometry.concatenateArrays ? SubGeometryBase.VERTEX_DATA : event.dataType;
			if (dataType == _dataType) {
				_dataDirty = true;
			}
		}
	}
}