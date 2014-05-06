package away3d.core.base {
	import away3d.arcane;
	import away3d.events.SubGeometryEvent;

	import flash.display3D.Context3DVertexBufferFormat;

	use namespace arcane

	public class LineSubGeometry extends SubGeometryBase{
		public static const VERTEX_DATA:String = "vertices";
		public static const START_POSITION_DATA:String = "startPositions";
		public static const END_POSITION_DATA:String = "endPositions";
		public static const THICKNESS_DATA:String = "thickness";
		public static const COLOR_DATA:String = "colors";

		public static const POSITION_FORMAT:String = Context3DVertexBufferFormat.FLOAT_3;
		public static const COLOR_FORMAT:String = Context3DVertexBufferFormat.FLOAT_4;
		public static const THICKNESS_FORMAT:String = Context3DVertexBufferFormat.FLOAT_1;

		private var _positionsDirty:Boolean = true;
		private var _boundingPositionDirty:Boolean = true;
		private var _thicknessDirty:Boolean = true;
		private var _colorsDirty:Boolean = true;

		private var _startPositions:Vector.<Number>;
		private var _endPositions:Vector.<Number>;
		private var _boundingPositions:Vector.<Number>;
		private var _thickness:Vector.<Number>;
		private var _startColors:Vector.<Number>;
		private var _endColors:Vector.<Number>;

		private var _numSegments:Number;

		private var _positionsUpdated:SubGeometryEvent;
		private var _thicknessUpdated:SubGeometryEvent;
		private var _colorUpdated:SubGeometryEvent;

		override protected function updateStrideOffset():void
		{
			_offset[VERTEX_DATA] = 0;

			var stride:Number = 0;
			_offset[START_POSITION_DATA] = stride;
			stride += 3;

			_offset[END_POSITION_DATA] = stride;
			stride += 3;

			_offset[THICKNESS_DATA] = stride;
			stride += 1;

			_offset[COLOR_DATA] = stride;
			stride += 4;

			_stride[VERTEX_DATA] = stride;
			_stride[START_POSITION_DATA] = stride;
			_stride[END_POSITION_DATA] = stride;
			_stride[THICKNESS_DATA] = stride;
			_stride[COLOR_DATA] = stride;

			var len:Number = _numVertices*stride;

			if (_vertices == null)
				_vertices = new Vector.<Number>(len);
			else if (_vertices.length != len)
				_vertices.length = len;

			_strideOffsetDirty = false;
		}

		/**
		 *
		 */
		override public function get vertices():Vector.<Number>
		{
			if (_positionsDirty)
				updatePositions(_startPositions, _endPositions);

			if (_thicknessDirty)
				updateThickness(_thickness);

			if (_colorsDirty)
				updateColors(_startColors, _endColors);

			return _vertices;
		}

		/**
		 *
		 */
		public function get startPositions():Vector.<Number>
		{
			if (_positionsDirty)
				updatePositions(_startPositions, _endPositions);

			return _startPositions;
		}

		/**
		 *
		 */
		public function get endPositions():Vector.<Number>
		{
			if (_positionsDirty)
				updatePositions(_startPositions, _endPositions);

			return _endPositions;
		}

		/**
		 *
		 */
		public function get thickness():Vector.<Number>
		{
			if (_thicknessDirty)
				updateThickness(_thickness);

			return _thickness;
		}

		/**
		 *
		 */
		public function get startColors():Vector.<Number>
		{
			if (_colorsDirty)
				updateColors(_startColors, _endColors);

			return _startColors;
		}

		/**
		 *
		 */
		public function get endColors():Vector.<Number>
		{
			if (_colorsDirty)
				updateColors(_startColors, _endColors);

			return _endColors;
		}

		/**
		 * The total amount of segments in the TriangleSubGeometry.
		 */
		public function get numSegments():Number
		{
			return _numSegments;
		}

		/**
		 *
		 */
		public function LineSubGeometry()
		{
			super(true);

			_subMeshClass = LineSubMesh;
		}

		override public function getBoundingPositions():Vector.<Number>
		{
			if (_boundingPositionDirty)
				_boundingPositions = startPositions.concat(endPositions);

			return _boundingPositions;
		}

		/**
		 *
		 */
		public function updatePositions(startValues:Vector.<Number>, endValues:Vector.<Number>):void
		{
			var i:Number;
			var j:Number;
			var values:Vector.<Number>;
			var index:Number;
			var stride:Number;
			var positions:Vector.<Number>;
			var indices:Vector.<uint>;

			_startPositions = startValues;

			if (_startPositions == null)
				_startPositions = new Vector.<Number>();

			_endPositions = endValues;

			if (_endPositions == null)
				_endPositions = new Vector.<Number>();

			_boundingPositionDirty = true;

			_numSegments = _startPositions.length/3;

			_numVertices = _numSegments*4;

			var lenV:Number = _numVertices*getStride(VERTEX_DATA);

			if (_vertices == null)
				_vertices = new Vector.<Number>(lenV);
			else if (_vertices.length != lenV)
				_vertices.length = lenV;

			i = 0;
			j = 0;
			index = getOffset(START_POSITION_DATA);
			stride = getStride(START_POSITION_DATA);
			positions = _vertices;
			indices = new Vector.<uint>();

			while (i < startValues.length) {
				values = (index/stride & 1)? endValues : startValues;
				positions[index] = values[i];
				positions[index + 1] = values[i + 1];
				positions[index + 2] = values[i + 2];

				values = (index/stride & 1)? startValues : endValues;
				positions[index + 3] = values[i];
				positions[index + 4] = values[i + 1];
				positions[index + 5] = values[i + 2];

				if (++j == 4) {
					var o:Number = index/stride - 3;
					indices.push(o, o + 1, o + 2, o + 3, o + 2, o + 1);
					j = 0;
					i += 3;
				}

				index += stride;
			}

			updateIndices(indices);

			invalidateBounds();

			notifyPositionsUpdate();

			_positionsDirty = false;
		}

		/**
		 * Updates the thickness.
		 */
		public function updateThickness(values:Vector.<Number>):void
		{
			var i:Number;
			var j:Number;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var thickness:Vector.<Number>;

			_thickness = values;

			if (values != null) {
				i = 0;
				j = 0;
				offset = getOffset(THICKNESS_DATA);
				stride = getStride(THICKNESS_DATA);
				thickness = _vertices;

				index = offset
				while (i < values.length) {
					thickness[index] = (Math.floor(0.5*(index - offset)/stride + 0.5) & 1)? -values[i] : values[i];

					if (++j == 4) {
						j = 0;
						i++;
					}
					index += stride;
				}
			}

			notifyThicknessUpdate();

			_thicknessDirty = false;
		}

		/**
		 *
		 */
		public function updateColors(startValues:Vector.<Number>, endValues:Vector.<Number>):void
		{
			var i:Number;
			var j:Number;
			var values:Vector.<Number>
			var index:Number;
			var offset:Number;
			var stride:Number;
			var colors:Vector.<Number>;

			_startColors = startValues;

			_endColors = endValues;

			//default to white
			if (_startColors == null) {
				_startColors = new Vector.<Number>(_numSegments*4);

				i = 0;
				while (i < _startColors.length)
					_startColors[i++] = 1;
			}

			if (_endColors == null) {
				_endColors = new Vector.<Number>(_numSegments*4);

				i = 0;
				while (i < _endColors.length)
					_endColors[i++] = 1;
			}

			i = 0;
			j = 0;
			offset = getOffset(COLOR_DATA);
			stride = getStride(COLOR_DATA);
			colors = _vertices;

			index = offset;

			while (i < _startColors.length) {
				values = ((index - offset)/stride & 1)? _endColors : _startColors;
				colors[index] = values[i];
				colors[index + 1] = values[i + 1];
				colors[index + 2] = values[i + 2];
				colors[index + 3] = values[i + 3];

				if (++j == 4) {
					j = 0;
					i += 4;
				}

				index += stride;
			}

			notifyColorsUpdate();

			_colorsDirty = false;
		}

		/**
		 *
		 */
		override public function dispose():void
		{
			super.dispose();

			_startPositions = null;
			_endPositions = null;
			_thickness = null;
			_startColors = null;
			_endColors = null;
		}

		/**
		 * @protected
		 */
		override protected function invalidateBounds():void
		{
			if (parentGeometry)
				parentGeometry.invalidateBounds(this);
		}

		/**
		 * Clones the current object
		 * @return An exact duplicate of the current object.
		 */
		override public function clone():SubGeometryBase
		{
			var clone:LineSubGeometry = new LineSubGeometry();
			clone.updateIndices(_indices.concat());
			clone.updatePositions(_startPositions.concat(), _endPositions.concat());
			clone.updateThickness(_thickness.concat());
			clone.updatePositions(_startPositions.concat(), _endPositions.concat());

			return clone;
		}

		override protected function notifyVerticesUpdate():void
		{
			_strideOffsetDirty = true;

			notifyPositionsUpdate();
			notifyThicknessUpdate();
			notifyColorsUpdate();
		}

		private function notifyPositionsUpdate():void
		{
			if (_positionsDirty)
				return;

			_positionsDirty = true;

			if (!_positionsUpdated)
				_positionsUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, TriangleSubGeometry.POSITION_DATA);

			dispatchEvent(_positionsUpdated);
		}

		private function notifyThicknessUpdate():void
		{
			if (_thicknessDirty)
				return;

			_thicknessDirty = true;

			if (!_thicknessUpdated)
				_thicknessUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, THICKNESS_DATA);

			dispatchEvent(_thicknessUpdated);
		}

		private function notifyColorsUpdate():void
		{
			if (_colorsDirty)
				return;

			_colorsDirty = true;

			if (!_colorUpdated)
				_colorUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, COLOR_DATA);

			dispatchEvent(_colorUpdated);
		}
	}
}
