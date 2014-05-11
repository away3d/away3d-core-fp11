package away3d.prefabs
{
	import away3d.arcane;
	import away3d.core.base.LineSubGeometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;

	use namespace arcane;
	
	/**
	 * A UV Sphere primitive mesh.
	 */
	public class PrimitiveSpherePrefab extends PrimitivePrefabBase
	{
		private var _radius:Number;
		private var _segmentsW:uint;
		private var _segmentsH:uint;
		private var _yUp:Boolean;
		
		/**
		 * Creates a new Sphere object.
		 * @param radius The radius of the sphere.
		 * @param segmentsW Defines the Number of horizontal segments that make up the sphere.
		 * @param segmentsH Defines the Number of vertical segments that make up the sphere.
		 * @param yUp Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function PrimitiveSpherePrefab(radius:Number = 50, segmentsW:uint = 16, segmentsH:uint = 12, yUp:Boolean = true)
		{
			super();
			
			_radius = radius;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_yUp = yUp;
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function buildGeometry(target:SubGeometryBase, geometryType:String):void
		{
			var indices:Vector.<uint>;
			var positions:Vector.<Number>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;

			var i:Number;
			var j:Number;
			var vidx:Number, fidx:Number; // indices

			var comp1:Number;
			var comp2:Number;
			var numVertices:Number;

			var horangle:Number;
			var z:Number;
			var ringradius:Number;
			var verangle:Number;
			var x:Number;
			var y:Number;

			if (geometryType == "triangleSubGeometry") {

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				numVertices = (_segmentsH + 1) * (_segmentsW + 1);

				if (numVertices == triangleGeometry.numVertices && triangleGeometry.indices != null) {
					indices = triangleGeometry.indices;
					positions = triangleGeometry.positions;
					normals = triangleGeometry.vertexNormals;
					tangents = triangleGeometry.vertexTangents;
				} else {
					indices = new Vector.<uint>((_segmentsH - 1) * _segmentsW * 6);
					positions = new Vector.<Number>(numVertices * 3);
					normals = new Vector.<Number>(numVertices * 3);
					tangents = new Vector.<Number>(numVertices * 3);

					invalidateUVs();
				}

				vidx = 0;
				fidx = 0;

				var startIndex:Number;
				var t1:Number;
				var t2:Number;

				for (j = 0; j <= _segmentsH; ++j) {

					startIndex = vidx;

					horangle = Math.PI * j / _segmentsH;
					z = -_radius * Math.cos(horangle);
					ringradius = _radius * Math.sin(horangle);

					for (i = 0; i <= _segmentsW; ++i) {
						verangle = 2 * Math.PI * i / _segmentsW;
						x = ringradius * Math.cos(verangle);
						y = ringradius * Math.sin(verangle);
						var normLen:Number = 1 / Math.sqrt(x * x + y * y + z * z);
						var tanLen:Number = Math.sqrt(y * y + x * x);

						if (_yUp) {

							t1 = 0;
							t2 = tanLen > .007 ? x / tanLen : 0;
							comp1 = -z;
							comp2 = y;

						} else {
							t1 = tanLen > .007 ? x / tanLen : 0;
							t2 = 0;
							comp1 = y;
							comp2 = z;
						}

						if (i == _segmentsW) {
							positions[vidx] = positions[startIndex];
							positions[vidx + 1] = positions[startIndex + 1];
							positions[vidx + 2] = positions[startIndex + 2];
							normals[vidx] = normals[startIndex] + (x * normLen) * .5;
							normals[vidx + 1] = normals[startIndex + 1] + ( comp1 * normLen) * .5;
							normals[vidx + 2] = normals[startIndex + 2] + (comp2 * normLen) * .5;
							tangents[vidx] = tanLen > .007 ? -y / tanLen : 1;
							tangents[vidx + 1] = t1;
							tangents[vidx + 2] = t2;

						} else {

							positions[vidx] = x;
							positions[vidx + 1] = comp1;
							positions[vidx + 2] = comp2;
							normals[vidx] = x * normLen;
							normals[vidx + 1] = comp1 * normLen;
							normals[vidx + 2] = comp2 * normLen;
							tangents[vidx] = tanLen > .007 ? -y / tanLen : 1;
							tangents[vidx + 1] = t1;
							tangents[vidx + 2] = t2;
						}

						if (i > 0 && j > 0) {

							var a:Number = (_segmentsW + 1) * j + i;
							var b:Number = (_segmentsW + 1) * j + i - 1;
							var c:Number = (_segmentsW + 1) * (j - 1) + i - 1;
							var d:Number = (_segmentsW + 1) * (j - 1) + i;

							if (j == _segmentsH) {

								positions[vidx] = positions[startIndex];
								positions[vidx + 1] = positions[startIndex + 1];
								positions[vidx + 2] = positions[startIndex + 2];

								indices[fidx++] = a;
								indices[fidx++] = c;
								indices[fidx++] = d;

							} else if (j == 1) {

								indices[fidx++] = a;
								indices[fidx++] = b;
								indices[fidx++] = c;

							} else {
								indices[fidx++] = a;
								indices[fidx++] = b;
								indices[fidx++] = c;
								indices[fidx++] = a;
								indices[fidx++] = c;
								indices[fidx++] = d;
							}
						}

						vidx += 3;
					}
				}

				triangleGeometry.updateIndices(indices);
				triangleGeometry.updatePositions(positions);
				triangleGeometry.updateVertexNormals(normals);
				triangleGeometry.updateVertexTangents(tangents);

			} else if (geometryType == GeometryType.LINE) {

				var lineGeometry:LineSubGeometry = target as LineSubGeometry;

				var numSegments:Number = (_segmentsH - 1) * _segmentsW * 2;
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

				for (j = 0; j <= _segmentsH; ++j) {

					horangle = Math.PI * j / _segmentsH;
					z = -_radius * Math.cos(horangle);
					ringradius = _radius * Math.sin(horangle);

					for (i = 0; i <= _segmentsW; ++i) {
						verangle = 2 * Math.PI * i / _segmentsW;
						x = ringradius * Math.cos(verangle);
						y = ringradius * Math.sin(verangle);

						if (_yUp) {
							comp1 = -z;
							comp2 = y;

						} else {
							comp1 = y;
							comp2 = z;
						}

						if (i > 0 && j > 0) {
							//horizonal lines
							if (j < _segmentsH) {
								endPositions[vidx] = x;
								endPositions[vidx + 1] = comp1;
								endPositions[vidx + 2] = comp2;

								thickness[fidx++] = 1;

								vidx += 3;
							}

							//vertical lines
							startPositions[vidx] = endPositions[vidx - _segmentsW * 6];
							startPositions[vidx + 1] = endPositions[vidx + 1 - _segmentsW * 6];
							startPositions[vidx + 2] = endPositions[vidx + 2 - _segmentsW * 6];

							endPositions[vidx] = x;
							endPositions[vidx + 1] = comp1;
							endPositions[vidx + 2] = comp2;

							thickness[fidx++] = 1;

							vidx += 3;
						}

						if (i < _segmentsW && j > 0 && j < _segmentsH) {
							startPositions[vidx] = x;
							startPositions[vidx + 1] = comp1;
							startPositions[vidx + 2] = comp2;
						}
					}
				}

				// build real data from raw data
				lineGeometry.updatePositions(startPositions, endPositions);
				lineGeometry.updateThickness(thickness);
			}
		}

		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target:SubGeometryBase, geometryType:String):void
		{
			var i:Number, j:Number;
			var numVertices:Number = (_segmentsH + 1) * (_segmentsW + 1);
			var uvs:Vector.<Number>;


			if (geometryType == "triangleSubGeometry") {

				numVertices = (_segmentsH + 1) * (_segmentsW + 1);

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				if (numVertices == triangleGeometry.numVertices && triangleGeometry.uvs != null) {
					uvs = triangleGeometry.uvs;
				} else {
					uvs = new Vector.<Number>(numVertices * 2);
				}

				var index:Number = 0;
				for (j = 0; j <= _segmentsH; ++j) {
					for (i = 0; i <= _segmentsW; ++i) {
						uvs[index++] = ( i / _segmentsW ) * triangleGeometry.scaleU;
						uvs[index++] = ( j / _segmentsH ) * triangleGeometry.scaleV;
					}
				}

				triangleGeometry.updateUVs(uvs);

			} else if (geometryType == GeometryType.LINE) {
				//nothing to do here
			}
		}
		
		/**
		 * The radius of the sphere.
		 */
		public function get radius():Number
		{
			return _radius;
		}
		
		public function set radius(value:Number):void
		{
			_radius = value;
			invalidateGeometry();
		}
		
		/**
		 * Defines the Number of horizontal segments that make up the sphere. Defaults to 16.
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
		 * Defines the Number of vertical segments that make up the sphere. Defaults to 12.
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
		 * Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
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
	}
}
