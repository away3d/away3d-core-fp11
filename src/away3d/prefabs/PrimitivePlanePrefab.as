package away3d.prefabs
{
	import away3d.arcane;
	import away3d.core.base.LineSubGeometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.library.assets.IAsset;

	use namespace arcane;
	
	/**
	 * A Plane primitive mesh.
	 */
	public class PrimitivePlanePrefab extends PrimitivePrefabBase
	{
		private var _segmentsW:uint;
		private var _segmentsH:uint;
		private var _yUp:Boolean;
		private var _width:Number;
		private var _height:Number;
		private var _doubleSided:Boolean;
		
		/**
		 * Creates a new Plane object.
		 * @param width The width of the plane.
		 * @param height The height of the plane.
		 * @param segmentsW The Number of segments that make up the plane along the X-axis.
		 * @param segmentsH The Number of segments that make up the plane along the Y or Z-axis.
		 * @param yUp Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false).
		 * @param doubleSided Defines whether the plane will be visible from both sides, with correct vertex normals.
		 */
		public function PrimitivePlanePrefab(width:Number = 100, height:Number = 100, segmentsW:uint = 1, segmentsH:uint = 1, yUp:Boolean = true, doubleSided:Boolean = false)
		{
			super();
			
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_yUp = yUp;
			_width = width;
			_height = height;
			_doubleSided = doubleSided;
		}
		
		/**
		 * The Number of segments that make up the plane along the X-axis. Defaults to 1.
		 */
		public function get segmentsW():uint
		{
			return _segmentsW;
		}
		
		public function set segmentsW(value:uint):void
		{
			_segmentsW = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * The Number of segments that make up the plane along the Y or Z-axis, depending on whether yUp is true or
		 * false, respectively. Defaults to 1.
		 */
		public function get segmentsH():uint
		{
			return _segmentsH;
		}
		
		public function set segmentsH(value:uint):void
		{
			_segmentsH = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 *  Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false). Defaults to true.
		 */
		public function get yUp():Boolean
		{
			return _yUp;
		}
		
		public function set yUp(value:Boolean):void
		{
			_yUp = value;
			invalidateGeometry();
		}
		
		/**
		 * Defines whether the plane will be visible from both sides, with correct vertex normals (as opposed to bothSides on Material). Defaults to false.
		 */
		public function get doubleSided():Boolean
		{
			return _doubleSided;
		}
		
		public function set doubleSided(value:Boolean):void
		{
			_doubleSided = value;
			invalidateGeometry();
		}
		
		/**
		 * The width of the plane.
		 */
		public function get width():Number
		{
			return _width;
		}
		
		public function set width(value:Number):void
		{
			_width = value;
			invalidateGeometry();
		}
		
		/**
		 * The height of the plane.
		 */
		public function get height():Number
		{
			return _height;
		}
		
		public function set height(value:Number):void
		{
			_height = value;
			invalidateGeometry();
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function buildGeometry(target:SubGeometryBase, geometryType:String):void
		{
			var indices:Vector.<uint>;
			var x:Number, y:Number;
			var numIndices:Number;
			var base:Number;
			var tw:Number = _segmentsW + 1;
			var numVertices:Number;

			var vidx:Number, fidx:Number; // indices

			var xi:Number;
			var yi:Number;

			if (geometryType == GeometryType.TRIANGLES) {

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				numVertices = (_segmentsH + 1) * tw;
				var positions:Vector.<Number>;
				var normals:Vector.<Number>;
				var tangents:Vector.<Number>;

				if (_doubleSided)
					numVertices *= 2;

				numIndices = _segmentsH * _segmentsW * 6;

				if (_doubleSided)
					numIndices *= 2;

				if (triangleGeometry.indices != null && numIndices == triangleGeometry.indices.length) {
					indices = triangleGeometry.indices;
				} else {
					indices = new Vector.<uint>(numIndices);

					invalidateUVs();
				}

				if (numVertices == triangleGeometry.numVertices) {
					positions = triangleGeometry.positions;
					normals = triangleGeometry.vertexNormals;
					tangents = triangleGeometry.vertexTangents;
				} else {
					positions = new Vector.<Number>(numVertices * 3);
					normals = new Vector.<Number>(numVertices * 3);
					tangents = new Vector.<Number>(numVertices * 3);

					invalidateUVs();
				}

				fidx = 0;

				vidx = 0;

				for (yi = 0; yi <= _segmentsH; ++yi) {

					for (xi = 0; xi <= _segmentsW; ++xi) {
						x = (xi / _segmentsW - .5) * _width;
						y = (yi / _segmentsH - .5) * _height;

						positions[vidx] = x;
						if (_yUp) {
							positions[vidx + 1] = 0;
							positions[vidx + 2] = y;
						} else {
							positions[vidx + 1] = y;
							positions[vidx + 2] = 0;
						}

						normals[vidx] = 0;

						if (_yUp) {
							normals[vidx + 1] = 1;
							normals[vidx + 2] = 0;
						} else {
							normals[vidx + 1] = 0;
							normals[vidx + 2] = -1;
						}

						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;

						vidx += 3;

						// add vertex with same position, but with inverted normal & tangent
						if (_doubleSided) {

							for (var i:Number = vidx; i < vidx + 3; ++i) {
								positions[i] = positions[i - 3];
								normals[i] = -normals[i - 3];
								tangents[i] = -tangents[i - 3];
							}

							vidx += 3;

						}

						if (xi != _segmentsW && yi != _segmentsH) {

							base = xi + yi * tw;
							var mult:Number = _doubleSided ? 2 : 1;

							indices[fidx++] = base * mult;
							indices[fidx++] = (base + tw) * mult;
							indices[fidx++] = (base + tw + 1) * mult;
							indices[fidx++] = base * mult;
							indices[fidx++] = (base + tw + 1) * mult;
							indices[fidx++] = (base + 1) * mult;

							if (_doubleSided) {

								indices[fidx++] = (base + tw + 1) * mult + 1;
								indices[fidx++] = (base + tw) * mult + 1;
								indices[fidx++] = base * mult + 1;
								indices[fidx++] = (base + 1) * mult + 1;
								indices[fidx++] = (base + tw + 1) * mult + 1;
								indices[fidx++] = base * mult + 1;

							}
						}
					}
				}

				triangleGeometry.updateIndices(indices);

				triangleGeometry.updatePositions(positions);
				triangleGeometry.updateVertexNormals(normals);
				triangleGeometry.updateVertexTangents(tangents);

			} else if (geometryType == GeometryType.LINE) {
				var lineGeometry:LineSubGeometry = target as LineSubGeometry;

				var numSegments:Number = (_segmentsH + 1) + tw;
				var startPositions:Vector.<Number>;
				var endPositions:Vector.<Number>;
				var thickness:Vector.<Number>;

				var hw:Number = _width / 2;
				var hh:Number = _height / 2;


				if (lineGeometry.indices != null && numSegments == lineGeometry.numSegments) {
					startPositions = lineGeometry.startPositions;
					endPositions = lineGeometry.endPositions;
					thickness = lineGeometry.thickness;
				} else {
					startPositions = new Vector.<Number>(numSegments * 3);
					endPositions = new Vector.<Number>(numSegments * 3);
					thickness = new Vector.<Number>(numSegments);
				}

				fidx = 0;

				vidx = 0;

				for (yi = 0; yi <= _segmentsH; ++yi) {
					startPositions[vidx] = -hw;
					startPositions[vidx + 1] = 0;
					startPositions[vidx + 2] = yi * _height - hh;

					endPositions[vidx] = hw;
					endPositions[vidx + 1] = 0;
					endPositions[vidx + 2] = yi * _height - hh;

					thickness[fidx++] = 1;

					vidx += 3;
				}


				for (xi = 0; xi <= _segmentsW; ++xi) {
					startPositions[vidx] = xi * _width - hw;
					startPositions[vidx + 1] = 0;
					startPositions[vidx + 2] = -hh;

					endPositions[vidx] = xi * _width - hw;
					endPositions[vidx + 1] = 0;
					endPositions[vidx + 2] = hh;

					thickness[fidx++] = 1;

					vidx += 3;
				}

				// build real data from raw data
				lineGeometry.updatePositions(startPositions, endPositions);
				lineGeometry.updateThickness(thickness);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function buildUVs(target:SubGeometryBase, geometryType:String):void
		{
			var uvs:Vector.<Number>;
			var numVertices:Number;

			if (geometryType == GeometryType.TRIANGLES) {

				numVertices = ( _segmentsH + 1 ) * ( _segmentsW + 1 );

				if (_doubleSided)
					numVertices *= 2;

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				if (triangleGeometry.uvs && numVertices == triangleGeometry.numVertices) {
					uvs = triangleGeometry.uvs;
				} else {
					uvs = new Vector.<Number>(numVertices * 2);
					invalidateGeometry()
				}

				var index:Number = 0;

				for (var yi:Number = 0; yi <= _segmentsH; ++yi) {

					for (var xi:Number = 0; xi <= _segmentsW; ++xi) {
						uvs[index] = (xi / _segmentsW) * triangleGeometry.scaleU;
						uvs[index + 1] = (1 - yi / _segmentsH) * triangleGeometry.scaleV;
						index += 2;

						if (_doubleSided) {
							uvs[index] = (xi / _segmentsW) * triangleGeometry.scaleU;
							uvs[index + 1] = (1 - yi / _segmentsH) * triangleGeometry.scaleV;
							index += 2;
						}
					}
				}

				triangleGeometry.updateUVs(uvs);


			} else if (geometryType == GeometryType.LINE) {
				//nothing to do here
			}
		}
	}
}
