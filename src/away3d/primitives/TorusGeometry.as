package away3d.primitives {
	import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;

	use namespace arcane;

	/**
	 * A UV Cylinder primitive mesh.
	 */
	public class TorusGeometry extends PrimitiveBase
	{
		protected var _radius : Number;
		protected var _tubeRadius : Number;
		protected var _segmentsR : uint;
		protected var _segmentsT : uint;
		protected var _yUp : Boolean;
		private var _rawVertexData:Vector.<Number>;
		private var _rawIndices:Vector.<uint>;
		private var _nextVertexIndex:uint;
		private var _currentIndex:uint;
		private var _currentTriangleIndex:uint;
		private var _numVertices:uint;
		private var _vertexStride : uint;
		private var _vertexOffset : int;

		private function addVertex(px:Number, py:Number, pz:Number,
								   nx:Number, ny:Number, nz:Number,
								   tx:Number, ty:Number, tz:Number):void
		{
			var compVertInd:uint = _vertexOffset + _nextVertexIndex * _vertexStride; // current component vertex index
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
		protected override function buildGeometry(target : CompactSubGeometry) : void
		{
			var i : uint, j : uint;
			var x : Number, y : Number, z : Number, nx : Number, ny : Number, nz : Number, revolutionAngleR : Number, revolutionAngleT : Number;
			var numTriangles : uint;
			// reset utility variables
			_numVertices = 0;
			_nextVertexIndex = 0;
			_currentIndex = 0;
			_currentTriangleIndex = 0;
			_vertexStride = target.vertexStride;
			_vertexOffset = target.vertexOffset;

			// evaluate target number of vertices, triangles and indices
			_numVertices = (_segmentsT + 1) * (_segmentsR + 1); // segmentsT + 1 because of closure, segmentsR + 1 because of closure
			numTriangles = _segmentsT * _segmentsR * 2; // each level has segmentR quads, each of 2 triangles

			// need to initialize raw arrays or can be reused?
			if (_numVertices == target.numVertices) {
				_rawVertexData = target.vertexData;
				_rawIndices = target.indexData || new Vector.<uint>(numTriangles * 3, true);
			}
			else {
				var numVertComponents : uint = _numVertices * _vertexStride;
				_rawVertexData = new Vector.<Number>(numVertComponents, true);
				_rawIndices = new Vector.<uint>(numTriangles * 3, true);
				invalidateUVs();
			}

			// evaluate revolution steps
			var revolutionAngleDeltaR : Number = 2 * Math.PI / _segmentsR;
			var revolutionAngleDeltaT : Number = 2 * Math.PI / _segmentsT;
			
			var comp1 :Number, comp2 :Number;
			var t1:Number, t2:Number, n1:Number, n2:Number;
			var startIndex:uint;

			// surface
			var a : uint, b : uint, c : uint, d : uint, length : Number;

			for (j = 0; j <= _segmentsT; ++j) {
				
				startIndex = _vertexOffset + _nextVertexIndex * _vertexStride;
				 
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
					z =  (j == _segmentsT)? 0 : _tubeRadius * nz;

					if(_yUp){
						n1 = -nz;
						n2 = ny;
						t1 = 0;
						t2 = (length? nx/length : x/_radius);
						comp1 = -z;
						comp2 = y;
						
					} else {
						n1 = ny;
						n2 = nz;
						t1 = (length? nx/length : x/_radius);
						t2 = 0;
						comp1 = y;
						comp2 = z;
					}
					
					if (i == _segmentsR) {
						addVertex(		x, _rawVertexData[startIndex+1], _rawVertexData[startIndex+2],
								  			nx, n1, n2,
								  			-(length? ny/length : y/_radius), t1, t2);
					} else {
						addVertex(		x, comp1, comp2,
								  			nx, n1, n2,
								  			-(length? ny/length : y/_radius), t1, t2);
					}
					
					// close triangle
					if (i > 0 && j > 0) {
						a = _nextVertexIndex - 1; // current
						b = _nextVertexIndex - 2; // previous
						c = b - _segmentsR - 1; // previous of last level
						d = a - _segmentsR - 1; // current of last level
						addTriangleClockWise(a, b, c);
						addTriangleClockWise(a, c, d);
					}
				}
			}

			// build real data from raw data
			target.updateData(_rawVertexData);
			target.updateIndexData(_rawIndices);
		}

		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target : CompactSubGeometry) : void
		{
			var i:int, j:int;
			var data:Vector.<Number>;
			var stride : int = target.UVStride;
			var offset : int = target.UVOffset;
			var skip : int = target.UVStride - 2;

			// evaluate num uvs
			var numUvs:uint = _numVertices * stride;

			// need to initialize raw array or can be reused?
			if (target.UVData && numUvs == target.UVData.length)
				data = target.UVData;
			else {
				data = new Vector.<Number>(numUvs, true);
				invalidateGeometry();
			}
			
			// current uv component index
			var currentUvCompIndex:uint = offset;
			
			// surface
			for(j = 0; j <= _segmentsT; ++j)
			{
				for(i = 0; i <= _segmentsR; ++i)
				{
					// revolution vertex
					data[currentUvCompIndex++] = i / _segmentsR;
					data[currentUvCompIndex++] = j / _segmentsT;
					currentUvCompIndex += skip;
				}
			}

			// build real data from raw data
			target.updateData(data);
		}
		
		/**
		 * The radius of the torus.
		 */
		public function get radius() : Number
		{
			return _radius;
		}
		
		public function set radius(value : Number) : void
		{
			_radius = value;
			invalidateGeometry();
		}
		
		/**
		 * The radius of the inner tube of the torus.
		 */
		public function get tubeRadius() : Number
		{
			return _tubeRadius;
		}
		
		public function set tubeRadius(value : Number) : void
		{
			_tubeRadius = value;
			invalidateGeometry();
		}
		
		/**
		 * Defines the number of horizontal segments that make up the torus. Defaults to 16.
		 */
		public function get segmentsR() : uint
		{
			return _segmentsR;
		}
		
		public function set segmentsR(value : uint) : void
		{
			_segmentsR = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number of vertical segments that make up the torus. Defaults to 8.
		 */
		public function get segmentsT() : uint
		{
			return _segmentsT;
		}
		
		public function set segmentsT(value : uint) : void
		{
			_segmentsT = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function get yUp() : Boolean
		{
			return _yUp;
		}
		
		public function set yUp(value : Boolean) : void
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
		public function TorusGeometry(radius : Number = 50, tubeRadius : Number = 50, segmentsR : uint = 16, segmentsT : uint = 8, yUp : Boolean = true)
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