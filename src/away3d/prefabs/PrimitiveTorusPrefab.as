package away3d.prefabs
{
	import away3d.arcane;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.library.assets.IAsset;

	use namespace arcane;
	
	/**
	 * A UV Cylinder primitive mesh.
	 */
	public class PrimitiveTorusPrefab extends PrimitivePrefabBase implements IAsset
	{
		protected var _radius:Number;
		protected var _tubeRadius:Number;
		protected var _segmentsR:uint;
		protected var _segmentsT:uint;
		protected var _yUp:Boolean;
		private var _rawVertexData:Vector.<Number>;
		private var _rawIndices:Vector.<uint>;
		private var _nextVertexIndex:uint;
		private var _currentIndex:uint;
		private var _currentTriangleIndex:uint;
		private var _numVertices:uint;
		private var _vertexStride:uint;
		private var _vertexOffset:int;
		
		private function addVertex(px:Number, py:Number, pz:Number, nx:Number, ny:Number, nz:Number, tx:Number, ty:Number, tz:Number):void
		{
			var compVertInd:uint = _vertexOffset + _nextVertexIndex*_vertexStride; // current component vertex index
			_rawVertexData[compVertInd++] = px;
			_rawVertexData[compVertInd++] = py;
			_rawVertexData[compVertInd++] = pz;
			_rawVertexData[compVertInd++] = nx;
			_rawVertexData[compVertInd++] = ny;
			_rawVertexData[compVertInd++] = nz;
			_rawVertexData[compVertInd++] = tx;
			_rawVertexData[compVertInd++] = ty;
			_rawVertexData[compVertInd] = tz;
			_nextVertexIndex++;
		}
		
		private function addTriangleClockWise(cwVertexIndex0:uint, cwVertexIndex1:uint, cwVertexIndex2:uint):void
		{
			_rawIndices[_currentIndex++] = cwVertexIndex0;
			_rawIndices[_currentIndex++] = cwVertexIndex1;
			_rawIndices[_currentIndex++] = cwVertexIndex2;
			_currentTriangleIndex++;
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

			var i:Number, j:Number;
			var x:Number, y:Number, z:Number, nx:Number, ny:Number, nz:Number, revolutionAngleR:Number, revolutionAngleT:Number;
			var vidx:Number;
			var fidx:Number;
			var numIndices:Number = 0;

			if (geometryType == "triangleSubGeometry") {

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				// evaluate target Number of vertices, triangles and indices
				_numVertices = (_segmentsT + 1) * (_segmentsR + 1); // segmentsT + 1 because of closure, segmentsR + 1 because of closure
				numIndices = _segmentsT * _segmentsR * 6; // each level has segmentR quads, each of 2 triangles

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

				// evaluate revolution steps
				var revolutionAngleDeltaR:Number = 2 * Math.PI / _segmentsR;
				var revolutionAngleDeltaT:Number = 2 * Math.PI / _segmentsT;

				var comp1:Number, comp2:Number;
				var t1:Number, t2:Number, n1:Number, n2:Number;
				var startIndex:Number = 0;
				var nextVertexIndex:Number = 0;

				// surface
				var a:Number, b:Number, c:Number, d:Number, length:Number;

				for (j = 0; j <= _segmentsT; ++j) {

					startIndex = nextVertexIndex * 3;

					for (i = 0; i <= _segmentsR; ++i) {

						// revolution vertex
						revolutionAngleR = i * revolutionAngleDeltaR;
						revolutionAngleT = j * revolutionAngleDeltaT;

						length = Math.cos(revolutionAngleT);
						nx = length * Math.cos(revolutionAngleR);
						ny = length * Math.sin(revolutionAngleR);
						nz = Math.sin(revolutionAngleT);

						x = _radius * Math.cos(revolutionAngleR) + _tubeRadius * nx;
						y = _radius * Math.sin(revolutionAngleR) + _tubeRadius * ny;
						z = (j == _segmentsT) ? 0 : _tubeRadius * nz;

						if (_yUp) {

							n1 = -nz;
							n2 = ny;
							t1 = 0;
							t2 = (length ? nx / length : x / _radius);
							comp1 = -z;
							comp2 = y;

						} else {
							n1 = ny;
							n2 = nz;
							t1 = (length ? nx / length : x / _radius);
							t2 = 0;
							comp1 = y;
							comp2 = z;
						}

						if (i == _segmentsR) {
							positions[vidx] = x;
							positions[vidx + 1] = positions[startIndex + 1];
							positions[vidx + 2] = positions[startIndex + 2];
						} else {
							positions[vidx] = x;
							positions[vidx + 1] = comp1;
							positions[vidx + 2] = comp2;
						}

						normals[vidx] = nx;
						normals[vidx + 1] = n1;
						normals[vidx + 2] = n2;
						tangents[vidx] = -(length ? ny / length : y / _radius);
						tangents[vidx + 1] = t1;
						tangents[vidx + 2] = t2;

						vidx += 3;

						// close triangle
						if (i > 0 && j > 0) {
							a = nextVertexIndex; // current
							b = nextVertexIndex - 1; // previous
							c = b - _segmentsR - 1; // previous of last level
							d = a - _segmentsR - 1; // current of last level

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

				// build real data from raw data
				triangleGeometry.updateIndices(indices);

				triangleGeometry.updatePositions(positions);
				triangleGeometry.updateVertexNormals(normals);
				triangleGeometry.updateVertexTangents(tangents);

			} else if (geometryType == "lineSubGeometry") {
				//TODO
			}
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target:SubGeometryBase, geometryType:String):void
		{

			var i:Number, j:Number;
			var uvs:Vector.<Number>;

			if (geometryType == "triangleSubGeometry") {

				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				// need to initialize raw array or can be reused?
				if (triangleGeometry.uvs && _numVertices == triangleGeometry.numVertices) {
					uvs = triangleGeometry.uvs;
				} else {
					uvs = new Vector.<Number>(_numVertices * 2);
				}

				// current uv component index
				var index:Number = 0;

				// surface
				for (j = 0; j <= _segmentsT; ++j) {
					for (i = 0; i <= _segmentsR; ++i) {
						// revolution vertex
						uvs[index++] = ( i / _segmentsR ) * triangleGeometry.scaleU;
						uvs[index++] = ( j / _segmentsT ) * triangleGeometry.scaleV;
					}
				}

				// build real data from raw data
				triangleGeometry.updateUVs(uvs);

			} else if (geometryType == "lineSubGeometry") {
				//nothing to do here
			}
		}
		
		/**
		 * The radius of the torus.
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
		 * The radius of the inner tube of the torus.
		 */
		public function get tubeRadius():Number
		{
			return _tubeRadius;
		}
		
		public function set tubeRadius(value:Number):void
		{
			_tubeRadius = value;
			invalidateGeometry();
		}
		
		/**
		 * Defines the number of horizontal segments that make up the torus. Defaults to 16.
		 */
		public function get segmentsR():uint
		{
			return _segmentsR;
		}
		
		public function set segmentsR(value:uint):void
		{
			_segmentsR = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number of vertical segments that make up the torus. Defaults to 8.
		 */
		public function get segmentsT():uint
		{
			return _segmentsT;
		}
		
		public function set segmentsT(value:uint):void
		{
			_segmentsT = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
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
		 * Creates a new <code>Torus</code> object.
		 * @param radius The radius of the torus.
		 * @param tuebRadius The radius of the inner tube of the torus.
		 * @param segmentsR Defines the number of horizontal segments that make up the torus.
		 * @param segmentsT Defines the number of vertical segments that make up the torus.
		 * @param yUp Defines whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function PrimitiveTorusPrefab(radius:Number = 50, tubeRadius:Number = 50, segmentsR:uint = 16, segmentsT:uint = 8, yUp:Boolean = true)
		{
			super();
			
			_radius = radius;
			_tubeRadius = tubeRadius;
			_segmentsR = segmentsR;
			_segmentsT = segmentsT;
			_yUp = yUp;
		}
	}
}
