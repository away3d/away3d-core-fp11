package away3d.core.pool {
	import away3d.core.managers.Stage3DProxy;

	import flash.display.Stage3D;
	import flash.display3D.IndexBuffer3D;
	import flash.geom.Vector3D;

	public class IndexData {
		private static const LIMIT_VERTS:uint = 0xffff;
		private static const LIMIT_INDICES:uint = 0xffffff;

		private var _dataDirty:Boolean = true;
		public var invalid:Vector.<Boolean> = new Vector.<Boolean>(8);
		public var stage3Ds:Vector.<Stage3DProxy> = new Vector.<Stage3DProxy>(8);
		public var buffers:Array = [];
		public var data:Vector.<uint>;
		public var indexMappings:Vector.<uint>;
		public var originalIndices:Vector.<uint>;
		public var offset:uint;
		public var level:uint;

		public function IndexData(level:uint) {
			this.level = level;
		}

		public function updateData(offset:Number, indices:Vector.<uint>, numVertices:Number):void
		{
			if (_dataDirty) {
				_dataDirty = false;

				if (indices.length < IndexData.LIMIT_INDICES && numVertices < IndexData.LIMIT_VERTS) {
					//shortcut for those buffers that fit into the maximum buffer sizes
					indexMappings = null;
					originalIndices = null;
					setData(indices);
					this.offset = indices.length;
				} else {
					var i:uint;
					var len:uint;
					var outIndex:uint;
					var j:uint;
					var k:uint;
					var splitIndices:Vector.<uint> = new Vector.<uint>();

					indexMappings = new Vector.<uint>(indices.length);
					originalIndices = new Vector.<uint>();

					i = indexMappings.length;

					while (i--)
						indexMappings[i] = -1;

					var originalIndex:Number;
					var splitIndex:Number;

					// Loop over all triangles
					outIndex = 0;
					len = indices.length;
					i = offset;
					k = 0;
					while (i < len && outIndex + 3 < IndexData.LIMIT_INDICES && k + 3 < IndexData.LIMIT_VERTS) {
						// Loop over all vertices in a triangle //TODO ensure this works for segments or any grouping
						for (j = 0; j < 3; j++) {

							originalIndex = indices[i + j];

							if (indexMappings[originalIndex] >= 0) {
								splitIndex = indexMappings[originalIndex];
							} else {

								// This vertex does not yet exist in the split list and
								// needs to be copied from the long list.
								splitIndex = k++;
								indexMappings[originalIndex] = splitIndex;
								originalIndices.push(originalIndex);
							}

							// Store new index, which may have come from the mapping look-up,
							// or from copying a new set of vertex data from the original vector
							splitIndices[outIndex + j] = splitIndex;
						}

						outIndex += 3;
						i += 3
					}

					setData(splitIndices);
					this.offset = i;
				}
			}
		}

		public function invalidateData():void
		{
			_dataDirty = true;
		}

		public function dispose():void
		{
			for (var i:uint = 0; i < 8; ++i) {
				if (stage3Ds[i]) {
					stage3Ds[i].disposeIndexData(this);
					stage3Ds[i] = null
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
		 * @param value
		 * @private
		 */
		private function setData(value:Vector.<uint>):void
		{
			if (value && value.length != value.length)
				disposeBuffers();
			else
				invalidateBuffers();

			data = value;
		}
	}
}
