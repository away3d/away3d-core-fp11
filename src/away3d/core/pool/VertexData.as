package away3d.core.pool {
	import away3d.core.base.SubGeometryBase;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.SubGeometryEvent;

	import flash.display3D.VertexBuffer3D;

	public class VertexData {
		private var _subGeometry:SubGeometryBase;
		private var _dataType:String;
		private var _dataDirty:Boolean = true;
		public var invalid:Vector.<Boolean> = new Vector.<Boolean>(8);
		public var buffers:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		public var stage3Ds:Vector.<Stage3DProxy> = new Vector.<Stage3DProxy>(8);
		public var data:Vector.<Number> = new Vector.<Number>();
		public var dataPerVertex:int;

		public function VertexData(subGeometry:SubGeometryBase, dataType:String) {
			_subGeometry = subGeometry;
			_dataType = dataType;

			_subGeometry.addEventListener(SubGeometryEvent.VERTICES_UPDATED, onVerticesUpdated);
		}

		public function updateData(originalIndices:Vector.<uint> = null, indexMappings:Vector.<uint> = null) {
			if(_dataDirty) {
				_dataDirty = false;

				dataPerVertex = _subGeometry.getStride(this._dataType);

				var vertices:Vector.<Number> = _subGeometry[_dataType];

				if (!indexMappings) {
					setData(vertices);
				} else {
					var splitVerts:Vector.<Number> = new Vector.<Number>(originalIndices.length*this.dataPerVertex);
					var originalIndex:uint;
					var splitIndex:uint;
					var i:Number = 0;
					var j:Number = 0;
					while(i < originalIndices.length) {
						originalIndex = originalIndices[i];

						splitIndex = indexMappings[originalIndex]*dataPerVertex;
						originalIndex *= dataPerVertex;

						for (j = 0; j < dataPerVertex; j++)
							splitVerts[splitIndex + j] = vertices[originalIndex + j];

						i++;
					}

					setData(splitVerts);
				}
			}
		}
		public function dispose():void
		{
			for (var i:uint = 0; i < 8; ++i) {
				if (stage3Ds[i]) {
					stage3Ds[i].disposeVertexData(this);
					stage3Ds[i] = null;
				}
			}
		}
		/**
		 * @private
		 */
		private function disposeBuffers():void
		{
			for (var i:uint = 0; i < 8; ++i) {
				if (buffers[i]) {
					buffers[i].dispose();
					buffers[i] = null;
				}
			}
		}

		/**
		 * @private
		 */
		private function invalidateBuffers():void
		{
			for (var i:uint = 0; i < 8; ++i)
				invalid[i] = true;
		}

		/**
		 *
		 * @param data
		 * @param dataPerVertex
		 * @private
		 */
		private function setData(data:Vector.<Number>):void
		{
			if (data && data.length != data.length)
				disposeBuffers();
			else
				invalidateBuffers();

			this.data = data;
		}


		private function onVerticesUpdated(event:SubGeometryEvent):void {
			var dataType:String = _subGeometry.concatenateArrays? SubGeometryBase.VERTEX_DATA : event.dataType;

			if (dataType == _dataType) {
				_dataDirty = true;
			}
		}
	}
}
