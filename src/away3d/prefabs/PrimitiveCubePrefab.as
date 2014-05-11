package away3d.prefabs
{
	import away3d.arcane;
	import away3d.core.base.LineSubGeometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;

	use namespace arcane;
	
	/**
	 * A Cube primitive mesh.
	 */
	public class PrimitiveCubePrefab extends PrimitivePrefabBase
	{
		private var _width:Number;
		private var _height:Number;
		private var _depth:Number;
		private var _tile6:Boolean;
		
		private var _segmentsW:Number;
		private var _segmentsH:Number;
		private var _segmentsD:Number;
		
		/**
		 * Creates a new Cube object.
		 * @param width The size of the cube along its X-axis.
		 * @param height The size of the cube along its Y-axis.
		 * @param depth The size of the cube along its Z-axis.
		 * @param segmentsW The Number of segments that make up the cube along the X-axis.
		 * @param segmentsH The Number of segments that make up the cube along the Y-axis.
		 * @param segmentsD The Number of segments that make up the cube along the Z-axis.
		 * @param tile6 The type of uv mapping to use. When true, a texture will be subdivided in a 2x3 grid, each used for a single face. When false, the entire image is mapped on each face.
		 */
		public function PrimitiveCubePrefab(width:Number = 100, height:Number = 100, depth:Number = 100, segmentsW:uint = 1, segmentsH:uint = 1, segmentsD:uint = 1, tile6:Boolean = true)
		{
			super();
			
			_width = width;
			_height = height;
			_depth = depth;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_segmentsD = segmentsD;
			_tile6 = tile6;
		}
		
		/**
		 * The size of the cube along its X-axis.
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
		 * The size of the cube along its Y-axis.
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
		 * The size of the cube along its Z-axis.
		 */
		public function get depth():Number
		{
			return _depth;
		}
		
		public function set depth(value:Number):void
		{
			_depth = value;
			invalidateGeometry();
		}
		
		/**
		 * The type of uv mapping to use. When false, the entire image is mapped on each face.
		 * When true, a texture will be subdivided in a 3x2 grid, each used for a single face.
		 * Reading the tiles from left to right, top to bottom they represent the faces of the
		 * cube in the following order: bottom, top, back, left, front, right. This creates
		 * several shared edges (between the top, front, left and right faces) which simplifies
		 * texture painting.
		 */
		public function get tile6():Boolean
		{
			return _tile6;
		}
		
		public function set tile6(value:Boolean):void
		{
			_tile6 = value;
			invalidateUVs();
		}
		
		/**
		 * The Number of segments that make up the cube along the X-axis. Defaults to 1.
		 */
		public function get segmentsW():Number
		{
			return _segmentsW;
		}
		
		public function set segmentsW(value:Number):void
		{
			_segmentsW = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * The Number of segments that make up the cube along the Y-axis. Defaults to 1.
		 */
		public function get segmentsH():Number
		{
			return _segmentsH;
		}
		
		public function set segmentsH(value:Number):void
		{
			_segmentsH = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * The Number of segments that make up the cube along the Z-axis. Defaults to 1.
		 */
		public function get segmentsD():Number
		{
			return _segmentsD;
		}
		
		public function set segmentsD(value:Number):void
		{
			_segmentsD = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function buildGeometry(target:SubGeometryBase, geometryType:String):void
		{
			var indices:Vector.<uint> /*uint*/;
			var positions:Vector.<Number>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;

			var tl:Number, tr:Number, bl:Number, br:Number;
			var i:Number, j:Number, inc:Number = 0;

			var vidx:Number, fidx:Number; // indices
			var hw:Number, hh:Number, hd:Number; // halves
			var dw:Number, dh:Number, dd:Number; // deltas

			var outer_pos:Number;
			var numIndices:Number;
			var numVertices:Number;

			// half cube dimensions
			hw = _width / 2;
			hh = _height / 2;
			hd = _depth / 2;

			if (geometryType == GeometryType.TRIANGLES) {

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				numVertices = ((_segmentsW + 1) * (_segmentsH + 1) + (_segmentsW + 1) * (_segmentsD + 1) + (_segmentsH + 1) * (_segmentsD + 1)) * 2;

				numIndices = ((_segmentsW * _segmentsH + _segmentsW * _segmentsD + _segmentsH * _segmentsD) * 12);

				if (numVertices == triangleGeometry.numVertices && triangleGeometry.indices != null) {
					indices = triangleGeometry.indices;
					positions = triangleGeometry.positions;
					normals = triangleGeometry.vertexNormals;
					tangents = triangleGeometry.vertexTangents;
				} else {
					indices = new Vector.<uint>(numIndices);
					positions = new Vector.<Number>(numVertices * 3);
					normals = new Vector.<Number>(numVertices * 3);
					tangents = new Vector.<Number>(numVertices * 3);

					invalidateUVs();
				}

				vidx = 0;
				fidx = 0;

				// Segment dimensions
				dw = _width / _segmentsW;
				dh = _height / _segmentsH;
				dd = _depth / _segmentsD;

				for (i = 0; i <= _segmentsW; i++) {
					outer_pos = -hw + i * dw;

					for (j = 0; j <= _segmentsH; j++) {
						// front
						positions[vidx] = outer_pos;
						positions[vidx + 1] = -hh + j * dh;
						positions[vidx + 2] = -hd;
						normals[vidx] = 0;
						normals[vidx + 1] = 0;
						normals[vidx + 2] = -1;
						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						// back
						positions[vidx] = outer_pos;
						positions[vidx + 1] = -hh + j * dh;
						positions[vidx + 2] = hd;
						normals[vidx] = 0;
						normals[vidx + 1] = 0;
						normals[vidx + 2] = 1;
						tangents[vidx] = -1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						if (i && j) {
							tl = 2 * ((i - 1) * (_segmentsH + 1) + (j - 1));
							tr = 2 * (i * (_segmentsH + 1) + (j - 1));
							bl = tl + 2;
							br = tr + 2;

							indices[fidx++] = tl;
							indices[fidx++] = bl;
							indices[fidx++] = br;
							indices[fidx++] = tl;
							indices[fidx++] = br;
							indices[fidx++] = tr;
							indices[fidx++] = tr + 1;
							indices[fidx++] = br + 1;
							indices[fidx++] = bl + 1;
							indices[fidx++] = tr + 1;
							indices[fidx++] = bl + 1;
							indices[fidx++] = tl + 1;
						}
					}
				}

				inc += 2 * (_segmentsW + 1) * (_segmentsH + 1);

				for (i = 0; i <= _segmentsW; i++) {
					outer_pos = -hw + i * dw;

					for (j = 0; j <= _segmentsD; j++) {
						// top
						positions[vidx] = outer_pos;
						positions[vidx + 1] = hh;
						positions[vidx + 2] = -hd + j * dd;
						normals[vidx] = 0;
						normals[vidx + 1] = 1;
						normals[vidx + 2] = 0;
						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						// bottom
						positions[vidx] = outer_pos;
						positions[vidx + 1] = -hh;
						positions[vidx + 2] = -hd + j * dd;
						normals[vidx] = 0;
						normals[vidx + 1] = -1;
						normals[vidx + 2] = 0;
						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						if (i && j) {
							tl = inc + 2 * ((i - 1) * (_segmentsD + 1) + (j - 1));
							tr = inc + 2 * (i * (_segmentsD + 1) + (j - 1));
							bl = tl + 2;
							br = tr + 2;

							indices[fidx++] = tl;
							indices[fidx++] = bl;
							indices[fidx++] = br;
							indices[fidx++] = tl;
							indices[fidx++] = br;
							indices[fidx++] = tr;
							indices[fidx++] = tr + 1;
							indices[fidx++] = br + 1;
							indices[fidx++] = bl + 1;
							indices[fidx++] = tr + 1;
							indices[fidx++] = bl + 1;
							indices[fidx++] = tl + 1;
						}
					}
				}

				inc += 2 * (_segmentsW + 1) * (_segmentsD + 1);

				for (i = 0; i <= _segmentsD; i++) {
					outer_pos = hd - i * dd;

					for (j = 0; j <= _segmentsH; j++) {
						// left
						positions[vidx] = -hw;
						positions[vidx + 1] = -hh + j * dh;
						positions[vidx + 2] = outer_pos;
						normals[vidx] = -1;
						normals[vidx + 1] = 0;
						normals[vidx + 2] = 0;
						tangents[vidx] = 0;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = -1;
						vidx += 3;

						// right
						positions[vidx] = hw;
						positions[vidx + 1] = -hh + j * dh;
						positions[vidx + 2] = outer_pos;
						normals[vidx] = 1;
						normals[vidx + 1] = 0;
						normals[vidx + 2] = 0;
						tangents[vidx] = 0;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 1;
						vidx += 3;

						if (i && j) {
							tl = inc + 2 * ((i - 1) * (_segmentsH + 1) + (j - 1));
							tr = inc + 2 * (i * (_segmentsH + 1) + (j - 1));
							bl = tl + 2;
							br = tr + 2;

							indices[fidx++] = tl;
							indices[fidx++] = bl;
							indices[fidx++] = br;
							indices[fidx++] = tl;
							indices[fidx++] = br;
							indices[fidx++] = tr;
							indices[fidx++] = tr + 1;
							indices[fidx++] = br + 1;
							indices[fidx++] = bl + 1;
							indices[fidx++] = tr + 1;
							indices[fidx++] = bl + 1;
							indices[fidx++] = tl + 1;
						}
					}
				}

				triangleGeometry.updateIndices(indices);

				triangleGeometry.updatePositions(positions);
				triangleGeometry.updateVertexNormals(normals);
				triangleGeometry.updateVertexTangents(tangents);

			} else if (geometryType == GeometryType.LINE) {
				var lineGeometry:LineSubGeometry = target as LineSubGeometry;

				var numSegments:Number = _segmentsH * 4 + _segmentsW * 4 + _segmentsD * 4;
				var startPositions:Vector.<Number>;
				var endPositions:Vector.<Number>;
				var thickness:Vector.<Number>;

				if (lineGeometry.indices != null && numSegments == lineGeometry.numSegments) {
					startPositions = lineGeometry.startPositions;
					endPositions = lineGeometry.endPositions;
					thickness = lineGeometry.thickness;
				} else {
					startPositions = new Vector.<Number>(numSegments * 3);
					endPositions = new Vector.<Number>(numSegments * 3);
					thickness = new Vector.<Number>(numSegments);
				}

				vidx = 0;

				fidx = 0;

				//front/back face
				for (i = 0; i < _segmentsH; ++i) {
					startPositions[vidx] = -hw;
					startPositions[vidx + 1] = i * _height / _segmentsH - hh;
					startPositions[vidx + 2] = -hd;

					endPositions[vidx] = hw;
					endPositions[vidx + 1] = i * _height / _segmentsH - hh
					endPositions[vidx + 2] = -hd;

					thickness[fidx++] = 1;

					vidx += 3;

					startPositions[vidx] = -hw;
					startPositions[vidx + 1] = hh - i * _height / _segmentsH;
					startPositions[vidx + 2] = hd;

					endPositions[vidx] = hw;
					endPositions[vidx + 1] = hh - i * _height / _segmentsH;
					endPositions[vidx + 2] = hd;

					thickness[fidx++] = 1;

					vidx += 3;
				}

				for (i = 0; i < _segmentsW; ++i) {
					startPositions[vidx] = i * _width / _segmentsW - hw;
					startPositions[vidx + 1] = -hh;
					startPositions[vidx + 2] = -hd;

					endPositions[vidx] = i * _width / _segmentsW - hw;
					endPositions[vidx + 1] = hh;
					endPositions[vidx + 2] = -hd;

					thickness[fidx++] = 1;

					vidx += 3;

					startPositions[vidx] = hw - i * _width / _segmentsW;
					startPositions[vidx + 1] = -hh;
					startPositions[vidx + 2] = hd;

					endPositions[vidx] = hw - i * _width / _segmentsW;
					endPositions[vidx + 1] = hh;
					endPositions[vidx + 2] = hd;

					thickness[fidx++] = 1;

					vidx += 3;
				}

				//left/right face
				for (i = 0; i < _segmentsH; ++i) {
					startPositions[vidx] = -hw;
					startPositions[vidx + 1] = i * _height / _segmentsH - hh;
					startPositions[vidx + 2] = -hd;

					endPositions[vidx] = -hw;
					endPositions[vidx + 1] = i * _height / _segmentsH - hh
					endPositions[vidx + 2] = hd;

					thickness[fidx++] = 1;

					vidx += 3;

					startPositions[vidx] = hw;
					startPositions[vidx + 1] = hh - i * _height / _segmentsH;
					startPositions[vidx + 2] = -hd;

					endPositions[vidx] = hw;
					endPositions[vidx + 1] = hh - i * _height / _segmentsH;
					endPositions[vidx + 2] = hd;

					thickness[fidx++] = 1;

					vidx += 3;
				}

				for (i = 0; i < _segmentsD; ++i) {
					startPositions[vidx] = hw
					startPositions[vidx + 1] = -hh;
					startPositions[vidx + 2] = i * _depth / _segmentsD - hd;

					endPositions[vidx] = hw;
					endPositions[vidx + 1] = hh;
					endPositions[vidx + 2] = i * _depth / _segmentsD - hd;

					thickness[fidx++] = 1;

					vidx += 3;

					startPositions[vidx] = -hw;
					startPositions[vidx + 1] = -hh;
					startPositions[vidx + 2] = hd - i * _depth / _segmentsD;

					endPositions[vidx] = -hw;
					endPositions[vidx + 1] = hh;
					endPositions[vidx + 2] = hd - i * _depth / _segmentsD;

					thickness[fidx++] = 1;

					vidx += 3;
				}


				//top/bottom face
				for (i = 0; i < _segmentsD; ++i) {
					startPositions[vidx] = -hw;
					startPositions[vidx + 1] = -hh;
					startPositions[vidx + 2] = hd - i * _depth / _segmentsD;

					endPositions[vidx] = hw;
					endPositions[vidx + 1] = -hh;
					endPositions[vidx + 2] = hd - i * _depth / _segmentsD;

					thickness[fidx++] = 1;

					vidx += 3;

					startPositions[vidx] = -hw;
					startPositions[vidx + 1] = hh;
					startPositions[vidx + 2] = i * _depth / _segmentsD - hd;

					endPositions[vidx] = hw;
					endPositions[vidx + 1] = hh;
					endPositions[vidx + 2] = i * _depth / _segmentsD - hd;

					thickness[fidx++] = 1;

					vidx += 3;
				}

				for (i = 0; i < _segmentsW; ++i) {
					startPositions[vidx] = hw - i * _width / _segmentsW;
					startPositions[vidx + 1] = -hh;
					startPositions[vidx + 2] = -hd;

					endPositions[vidx] = hw - i * _width / _segmentsW;
					endPositions[vidx + 1] = -hh;
					endPositions[vidx + 2] = hd;

					thickness[fidx++] = 1;

					vidx += 3;

					startPositions[vidx] = i * _width / _segmentsW - hw;
					startPositions[vidx + 1] = hh;
					startPositions[vidx + 2] = -hd;

					endPositions[vidx] = i * _width / _segmentsW - hw;
					endPositions[vidx + 1] = hh;
					endPositions[vidx + 2] = hd;

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
		override protected function buildUVs(target:SubGeometryBase, geometryType:String):void {
			var i:Number, j:Number, index:Number;
			var uvs:Vector.<Number>;

			var u_tile_dim:Number, v_tile_dim:Number;
			var u_tile_step:Number, v_tile_step:Number;
			var tl0u:Number, tl0v:Number;
			var tl1u:Number, tl1v:Number;
			var du:Number, dv:Number;
			var numVertices:Number;

			if (geometryType == GeometryType.TRIANGLES) {

				numVertices = ((_segmentsW + 1) * (_segmentsH + 1) + (_segmentsW + 1) * (_segmentsD + 1) + (_segmentsH + 1) * (_segmentsD + 1)) * 2;

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				if (numVertices == triangleGeometry.numVertices && triangleGeometry.uvs != null) {
					uvs = triangleGeometry.uvs;
				} else {
					uvs = new Vector.<Number>(numVertices * 2);
				}

				if (_tile6) {
					u_tile_dim = u_tile_step = 1 / 3;
					v_tile_dim = v_tile_step = 1 / 2;
				} else {
					u_tile_dim = v_tile_dim = 1;
					u_tile_step = v_tile_step = 0;
				}

				// Create planes two and two, the same way that they were
				// constructed in the buildGeometry() function. First calculate
				// the top-left UV coordinate for both planes, and then loop
				// over the points, calculating the UVs from these Numbers.

				// When tile6 is true, the layout is as follows:
				//       .-----.-----.-----. (1,1)
				//       | Bot |  T  | Bak |
				//       |-----+-----+-----|
				//       |  L  |  F  |  R  |
				// (0,0)'-----'-----'-----'

				index = 0;

				// FRONT / BACK
				tl0u = 1 * u_tile_step;
				tl0v = 1 * v_tile_step;
				tl1u = 2 * u_tile_step;
				tl1v = 0 * v_tile_step;
				du = u_tile_dim / _segmentsW;
				dv = v_tile_dim / _segmentsH;
				for (i = 0; i <= _segmentsW; i++) {
					for (j = 0; j <= _segmentsH; j++) {
						uvs[index++] = ( tl0u + i * du ) * triangleGeometry.scaleU;
						uvs[index++] = ( tl0v + (v_tile_dim - j * dv)) * triangleGeometry.scaleV;

						uvs[index++] = ( tl1u + (u_tile_dim - i * du)) * triangleGeometry.scaleU;
						uvs[index++] = ( tl1v + (v_tile_dim - j * dv)) * triangleGeometry.scaleV;
					}
				}

				// TOP / BOTTOM
				tl0u = 1 * u_tile_step;
				tl0v = 0 * v_tile_step;
				tl1u = 0 * u_tile_step;
				tl1v = 0 * v_tile_step;
				du = u_tile_dim / _segmentsW;
				dv = v_tile_dim / _segmentsD;
				for (i = 0; i <= _segmentsW; i++) {
					for (j = 0; j <= _segmentsD; j++) {
						uvs[index++] = ( tl0u + i * du) * triangleGeometry.scaleU;
						uvs[index++] = ( tl0v + (v_tile_dim - j * dv)) * triangleGeometry.scaleV;

						uvs[index++] = ( tl1u + i * du) * triangleGeometry.scaleU;
						uvs[index++] = ( tl1v + j * dv) * triangleGeometry.scaleV;
					}
				}

				// LEFT / RIGHT
				tl0u = 0 * u_tile_step;
				tl0v = 1 * v_tile_step;
				tl1u = 2 * u_tile_step;
				tl1v = 1 * v_tile_step;
				du = u_tile_dim / _segmentsD;
				dv = v_tile_dim / _segmentsH;
				for (i = 0; i <= _segmentsD; i++) {
					for (j = 0; j <= _segmentsH; j++) {
						uvs[index++] = ( tl0u + i * du) * triangleGeometry.scaleU;
						uvs[index++] = ( tl0v + (v_tile_dim - j * dv)) * triangleGeometry.scaleV;

						uvs[index++] = ( tl1u + (u_tile_dim - i * du)) * triangleGeometry.scaleU;
						uvs[index++] = ( tl1v + (v_tile_dim - j * dv)) * triangleGeometry.scaleV;
					}
				}

				triangleGeometry.updateUVs(uvs);

			} else if (geometryType == GeometryType.LINE) {
				//nothing to do here
			}
		}
	}
}
