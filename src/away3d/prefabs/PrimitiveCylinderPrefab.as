package away3d.prefabs
{
	import away3d.arcane;
	import away3d.core.base.LineSubGeometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;

	use namespace arcane;

	/**
	 * A Cylinder primitive mesh.
	 */
	public class PrimitiveCylinderPrefab extends PrimitivePrefabBase
	{
		protected var _topRadius:Number;
		protected var _bottomRadius:Number;
		protected var _height:Number;
		protected var _segmentsW:uint;
		protected var _segmentsH:uint;

		protected var _topClosed:Boolean;
		protected var _bottomClosed:Boolean;
		protected var _surfaceClosed:Boolean;
		protected var _yUp:Boolean;
		private var _numVertices:uint;

		/**
		 * Creates a new Cylinder object.
		 * @param topRadius The radius of the top end of the cylinder.
		 * @param bottomRadius The radius of the bottom end of the cylinder
		 * @param height The radius of the bottom end of the cylinder
		 * @param segmentsW Defines the Number of horizontal segments that make up the cylinder. Defaults to 16.
		 * @param segmentsH Defines the Number of vertical segments that make up the cylinder. Defaults to 1.
		 * @param topClosed Defines whether the top end of the cylinder is closed (true) or open.
		 * @param bottomClosed Defines whether the bottom end of the cylinder is closed (true) or open.
		 * @param yUp Defines whether the cone poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function PrimitiveCylinderPrefab(topRadius:Number = 50, bottomRadius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 1, topClosed:Boolean = true, bottomClosed:Boolean = true, surfaceClosed:Boolean = true, yUp:Boolean = true)
		{
			super();

			_topRadius = topRadius;
			_bottomRadius = bottomRadius;
			_height = height;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_topClosed = topClosed;
			_bottomClosed = bottomClosed;
			_surfaceClosed = surfaceClosed;
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
			var x:Number;
			var y:Number;
			var z:Number;
			var vidx:Number;
			var fidx:Number;

			var radius:Number;
			var revolutionAngle:Number;

			var dr:Number;
			var latNormElev:Number;
			var latNormBase:Number;
			var numIndices:Number = 0;

			var comp1:Number;
			var comp2:Number;
			var startIndex:Number = 0;
			var nextVertexIndex:Number = 0;

			var t1:Number;
			var t2:Number;

			// reset utility variables
			_numVertices = 0;

			// evaluate revolution steps
			var revolutionAngleDelta:Number = 2 * Math.PI / _segmentsW;

			if (geometryType == GeometryType.TRIANGLES) {

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				// evaluate target Number of vertices, triangles and indices
				if (_surfaceClosed) {
					_numVertices += (_segmentsH + 1) * (_segmentsW + 1); // segmentsH + 1 because of closure, segmentsW + 1 because of UV unwrapping
					numIndices += _segmentsH * _segmentsW * 6; // each level has segmentW quads, each of 2 triangles
				}
				if (_topClosed) {
					_numVertices += 2 * (_segmentsW + 1); // segmentsW + 1 because of unwrapping
					numIndices += _segmentsW * 3; // one triangle for each segment
				}
				if (_bottomClosed) {
					_numVertices += 2 * (_segmentsW + 1);
					numIndices += _segmentsW * 3;
				}

				// need to initialize raw arrays or can be reused?
				if (_numVertices == triangleGeometry.numVertices) {
					indices = triangleGeometry.indices;
					positions = triangleGeometry.positions;
					normals = triangleGeometry.vertexNormals;
					tangents = triangleGeometry.vertexTangents;
				} else {
					indices = new Vector.<uint>(numIndices)
					positions = new Vector.<Number>(_numVertices * 3);
					normals = new Vector.<Number>(_numVertices * 3);
					tangents = new Vector.<Number>(_numVertices * 3);

					invalidateUVs();
				}

				vidx = 0;
				fidx = 0;

				// top
				if (_topClosed && _topRadius > 0) {

					z = -0.5 * _height;

					for (i = 0; i <= _segmentsW; ++i) {
						// central vertex
						if (_yUp) {
							t1 = 1;
							t2 = 0;
							comp1 = -z;
							comp2 = 0;

						} else {
							t1 = 0;
							t2 = -1;
							comp1 = 0;
							comp2 = z;
						}

						positions[vidx] = 0;
						positions[vidx + 1] = comp1;
						positions[vidx + 2] = comp2;
						normals[vidx] = 0;
						normals[vidx + 1] = t1;
						normals[vidx + 2] = t2;
						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						// revolution vertex
						revolutionAngle = i * revolutionAngleDelta;
						x = _topRadius * Math.cos(revolutionAngle);
						y = _topRadius * Math.sin(revolutionAngle);

						if (_yUp) {
							comp1 = -z;
							comp2 = y;
						} else {
							comp1 = y;
							comp2 = z;
						}

						if (i == _segmentsW) {
							positions[vidx] = positions[startIndex + 3];
							positions[vidx + 1] = positions[startIndex + 4];
							positions[vidx + 2] = positions[startIndex + 5];

						} else {
							positions[vidx] = x;
							positions[vidx + 1] = comp1;
							positions[vidx + 2] = comp2;
						}

						normals[vidx] = 0;
						normals[vidx + 1] = t1;
						normals[vidx + 2] = t2;
						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						if (i > 0) {
							// add triangle
							indices[fidx++] = nextVertexIndex;
							indices[fidx++] = nextVertexIndex + 1;
							indices[fidx++] = nextVertexIndex + 2;

							nextVertexIndex += 2;
						}
					}

					nextVertexIndex += 2;
				}

				// bottom
				if (_bottomClosed && _bottomRadius > 0) {

					z = 0.5 * _height;

					startIndex = nextVertexIndex * 3;

					for (i = 0; i <= _segmentsW; ++i) {
						if (_yUp) {
							t1 = -1;
							t2 = 0;
							comp1 = -z;
							comp2 = 0;
						} else {
							t1 = 0;
							t2 = 1;
							comp1 = 0;
							comp2 = z;
						}

						positions[vidx] = 0;
						positions[vidx + 1] = comp1;
						positions[vidx + 2] = comp2;
						normals[vidx] = 0;
						normals[vidx + 1] = t1;
						normals[vidx + 2] = t2;
						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						// revolution vertex
						revolutionAngle = i * revolutionAngleDelta;
						x = _bottomRadius * Math.cos(revolutionAngle);
						y = _bottomRadius * Math.sin(revolutionAngle);

						if (_yUp) {
							comp1 = -z;
							comp2 = y;
						} else {
							comp1 = y;
							comp2 = z;
						}

						if (i == _segmentsW) {
							positions[vidx] = positions[startIndex + 3];
							positions[vidx + 1] = positions[startIndex + 4];
							positions[vidx + 2] = positions[startIndex + 5];
						} else {
							positions[vidx] = x;
							positions[vidx + 1] = comp1;
							positions[vidx + 2] = comp2;
						}

						normals[vidx] = 0;
						normals[vidx + 1] = t1;
						normals[vidx + 2] = t2;
						tangents[vidx] = 1;
						tangents[vidx + 1] = 0;
						tangents[vidx + 2] = 0;
						vidx += 3;

						if (i > 0) {
							// add triangle
							indices[fidx++] = nextVertexIndex;
							indices[fidx++] = nextVertexIndex + 2;
							indices[fidx++] = nextVertexIndex + 1;

							nextVertexIndex += 2;
						}
					}

					nextVertexIndex += 2;
				}

				// The normals on the lateral surface all have the same incline, i.e.
				// the "elevation" component (Y or Z depending on yUp) is constant.
				// Same principle goes for the "base" of these vectors, which will be
				// calculated such that a vector [base,elev] will be a unit vector.
				dr = (_bottomRadius - _topRadius);
				latNormElev = dr / _height;
				latNormBase = (latNormElev == 0) ? 1 : _height / dr;

				// lateral surface
				if (_surfaceClosed) {
					var a:Number;
					var b:Number;
					var c:Number;
					var d:Number;
					var na0:Number, na1:Number, naComp1:Number, naComp2:Number;

					for (j = 0; j <= _segmentsH; ++j) {
						radius = _topRadius - ((j / _segmentsH) * (_topRadius - _bottomRadius));
						z = -(_height / 2) + (j / _segmentsH * _height);

						startIndex = nextVertexIndex * 3;

						for (i = 0; i <= _segmentsW; ++i) {
							// revolution vertex
							revolutionAngle = i * revolutionAngleDelta;
							x = radius * Math.cos(revolutionAngle);
							y = radius * Math.sin(revolutionAngle);
							na0 = latNormBase * Math.cos(revolutionAngle);
							na1 = latNormBase * Math.sin(revolutionAngle);

							if (_yUp) {
								t1 = 0;
								t2 = -na0;
								comp1 = -z;
								comp2 = y;
								naComp1 = latNormElev;
								naComp2 = na1;

							} else {
								t1 = -na0;
								t2 = 0;
								comp1 = y;
								comp2 = z;
								naComp1 = na1;
								naComp2 = latNormElev;
							}

							if (i == _segmentsW) {
								positions[vidx] = positions[startIndex];
								positions[vidx + 1] = positions[startIndex + 1];
								positions[vidx + 2] = positions[startIndex + 2];
								normals[vidx] = na0;
								normals[vidx + 1] = latNormElev;
								normals[vidx + 2] = na1;
								tangents[vidx] = na1;
								tangents[vidx + 1] = t1;
								tangents[vidx + 2] = t2;
							} else {
								positions[vidx] = x;
								positions[vidx + 1] = comp1;
								positions[vidx + 2] = comp2;
								normals[vidx] = na0;
								normals[vidx + 1] = naComp1;
								normals[vidx + 2] = naComp2;
								tangents[vidx] = -na1;
								tangents[vidx + 1] = t1;
								tangents[vidx + 2] = t2;
							}
							vidx += 3;

							// close triangle
							if (i > 0 && j > 0) {
								a = nextVertexIndex; // current
								b = nextVertexIndex - 1; // previous
								c = b - _segmentsW - 1; // previous of last level
								d = a - _segmentsW - 1; // current of last level

								indices[fidx++] = a;
								indices[fidx++] = b;
								indices[fidx++] = c;

								indices[fidx++] = a;
								indices[fidx++] = c;
								indices[fidx++] = d;
							}

							nextVertexIndex++;
						}
					}
				}

				// build real data from raw data
				triangleGeometry.updateIndices(indices);

				triangleGeometry.updatePositions(positions);
				triangleGeometry.updateVertexNormals(normals);
				triangleGeometry.updateVertexTangents(tangents);

			} else
				if (geometryType == GeometryType.LINE) {
					var lineGeometry:LineSubGeometry = target as LineSubGeometry;

					var numSegments:Number = (_segmentsH + 1) * (_segmentsW) + _segmentsW;
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

					//horizonal lines

					for (j = 0; j <= _segmentsH; ++j) {
						radius = _topRadius - ((j / _segmentsH) * (_topRadius - _bottomRadius));
						z = _height * (j / _segmentsH - 0.5);

						for (i = 0; i <= _segmentsW; ++i) {
							// revolution vertex
							revolutionAngle = i * revolutionAngleDelta;
							x = radius * Math.cos(revolutionAngle);
							y = radius * Math.sin(revolutionAngle);

							if (_yUp) {
								comp1 = -z;
								comp2 = y;
							} else {
								comp1 = y;
								comp2 = z;
							}

							if (i > 0) {
								endPositions[vidx] = x;
								endPositions[vidx + 1] = comp1;
								endPositions[vidx + 2] = comp2;

								thickness[fidx++] = 1;

								vidx += 3;

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

							if (i < _segmentsW) {
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
			var i:Number;
			var j:Number;
			var x:Number;
			var y:Number;
			var revolutionAngle:Number;
			var uvs:Vector.<Number>;

			if (geometryType == GeometryType.TRIANGLES) {

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				// need to initialize raw array or can be reused?
				if (triangleGeometry.uvs && _numVertices == triangleGeometry.numVertices) {
					uvs = triangleGeometry.uvs;
				} else {
					uvs = new Vector.<Number>(_numVertices * 2);
				}

				// evaluate revolution steps
				var revolutionAngleDelta:Number = 2 * Math.PI / _segmentsW;

				// current uv component index
				var index:Number = 0;

				// top
				if (_topClosed) {
					for (i = 0; i <= _segmentsW; ++i) {

						revolutionAngle = i * revolutionAngleDelta;
						x = 0.5 + 0.5 * -Math.cos(revolutionAngle);
						y = 0.5 + 0.5 * Math.sin(revolutionAngle);

						uvs[index++] = 0.5 * triangleGeometry.scaleU; // central vertex
						uvs[index++] = 0.5 * triangleGeometry.scaleV;

						uvs[index++] = x * triangleGeometry.scaleU; // revolution vertex
						uvs[index++] = y * triangleGeometry.scaleV;
					}
				}

				// bottom
				if (_bottomClosed) {
					for (i = 0; i <= _segmentsW; ++i) {

						revolutionAngle = i * revolutionAngleDelta;
						x = 0.5 + 0.5 * Math.cos(revolutionAngle);
						y = 0.5 + 0.5 * Math.sin(revolutionAngle);

						uvs[index++] = 0.5 * triangleGeometry.scaleU; // central vertex
						uvs[index++] = 0.5 * triangleGeometry.scaleV;

						uvs[index++] = x * triangleGeometry.scaleU; // revolution vertex
						uvs[index++] = y * triangleGeometry.scaleV;
					}
				}

				// lateral surface
				if (_surfaceClosed) {
					for (j = 0; j <= _segmentsH; ++j) {
						for (i = 0; i <= _segmentsW; ++i) {
							// revolution vertex
							uvs[index++] = ( i / _segmentsW ) * triangleGeometry.scaleU;
							uvs[index++] = ( j / _segmentsH ) * triangleGeometry.scaleV;
						}
					}
				}

				// build real data from raw data
				triangleGeometry.updateUVs(uvs);

			} else
				if (geometryType == GeometryType.LINE) {
					//nothing to do here
				}
		}

		/**
		 * The radius of the top end of the cylinder.
		 */
		public function get topRadius():Number
		{
			return _topRadius;
		}

		public function set topRadius(value:Number):void
		{
			_topRadius = value;
			invalidateGeometry();
		}

		/**
		 * The radius of the bottom end of the cylinder.
		 */
		public function get bottomRadius():Number
		{
			return _bottomRadius;
		}

		public function set bottomRadius(value:Number):void
		{
			_bottomRadius = value;
			invalidateGeometry();
		}

		/**
		 * The radius of the top end of the cylinder.
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
		 * Defines the Number of horizontal segments that make up the cylinder. Defaults to 16.
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
		 * Defines the Number of vertical segments that make up the cylinder. Defaults to 1.
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
		 * Defines whether the top end of the cylinder is closed (true) or open.
		 */
		public function get topClosed():Boolean
		{
			return _topClosed;
		}

		public function set topClosed(value:Boolean):void
		{
			_topClosed = value;
			invalidateGeometry();
		}

		/**
		 * Defines whether the bottom end of the cylinder is closed (true) or open.
		 */
		public function get bottomClosed():Boolean
		{
			return _bottomClosed;
		}

		public function set bottomClosed(value:Boolean):void
		{
			_bottomClosed = value;
			invalidateGeometry();
		}

		/**
		 * Defines whether the cylinder poles should lay on the Y-axis (true) or on the Z-axis (false).
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
