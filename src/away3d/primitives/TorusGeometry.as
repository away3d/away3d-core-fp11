package away3d.primitives
{
	import away3d.arcane;
	import away3d.core.base.SubGeometry;

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
		private var _rawVertexPositions:Vector.<Number>;
		private var _rawVertexNormals:Vector.<Number>;
		private var _rawVertexTangents:Vector.<Number>;
		private var _rawUvs:Vector.<Number>;
		private var _rawIndices:Vector.<uint>;
		private var _nextVertexIndex:uint;
		private var _currentIndex:uint;
		private var _currentTriangleIndex:uint;
		private var _numVertices:uint;
		private var _numTriangles:uint;

		private function addVertex(px:Number, py:Number, pz:Number,
								   nx:Number, ny:Number, nz:Number,
								   tx:Number, ty:Number, tz:Number):void
		{
			var compVertInd:uint = _nextVertexIndex * 3; // current component vertex index
			_rawVertexPositions[compVertInd]     = px;
			_rawVertexPositions[compVertInd + 1] = py;
			_rawVertexPositions[compVertInd + 2] = pz;
			_rawVertexNormals[compVertInd]       = nx;
			_rawVertexNormals[compVertInd + 1]   = ny;
			_rawVertexNormals[compVertInd + 2]   = nz;
			_rawVertexTangents[compVertInd]      = tx;
			_rawVertexTangents[compVertInd + 1]  = ty;
			_rawVertexTangents[compVertInd + 2]  = tz;
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
		protected override function buildGeometry(target : SubGeometry) : void
		{
			var i:uint, j:uint;
			var x:Number, y:Number, z:Number, nx:Number, ny:Number, nz:Number, revolutionAngleR:Number, revolutionAngleT:Number;

			// reset utility variables
			_numVertices = 0;
			_numTriangles = 0;
			_nextVertexIndex = 0;
			_currentIndex = 0;
			_currentTriangleIndex = 0;

			// evaluate target number of vertices, triangles and indices
			_numVertices = (_segmentsT + 1) * (_segmentsR + 1); // segmentsT + 1 because of closure, segmentsR + 1 because of closure
			_numTriangles = _segmentsT * _segmentsR * 2; // each level has segmentR quads, each of 2 triangles

			// need to initialize raw arrays or can be reused?
			if (_numVertices == target.numVertices) {
				_rawVertexPositions = target.vertexData;
				_rawVertexNormals = target.vertexNormalData;
				_rawVertexTangents = target.vertexTangentData;
				_rawIndices = target.indexData;
			}
			else {
				var numVertComponents:uint = _numVertices * 3;
				_rawVertexPositions = new Vector.<Number>(numVertComponents, true);
				_rawVertexNormals = new Vector.<Number>(numVertComponents, true);
				_rawVertexTangents = new Vector.<Number>(numVertComponents, true);
				_rawIndices = new Vector.<uint>(_numTriangles * 3, true);
			}

			// evaluate revolution steps
			var revolutionAngleDeltaR:Number = 2 * Math.PI / _segmentsR;
			var revolutionAngleDeltaT:Number = 2 * Math.PI / _segmentsT;

			// surface
			var a:uint, b:uint, c:uint, d:uint, length:Number;

			for(j = 0; j <= _segmentsT; ++j)
			{
				for(i = 0; i <= _segmentsR; ++i)
				{
					// revolution vertex
					revolutionAngleR = i * revolutionAngleDeltaR;
					revolutionAngleT = j * revolutionAngleDeltaT;
					
					length = Math.cos(revolutionAngleT);
					nx = length * Math.cos(revolutionAngleR);
					ny = length * Math.sin(revolutionAngleR);
					nz = Math.sin(revolutionAngleT);
					
					x = _radius * Math.cos(revolutionAngleR) + _tubeRadius * nx;
					y = _radius * Math.sin(revolutionAngleR) + _tubeRadius * ny;
					z = _tubeRadius * nz;
					
					
					if(_yUp)
						addVertex(x, -z, y,
								  nx, -nz, ny,
								  -(length? ny/length : y/_radius), 0, (length? nx/length : x/_radius));
					else
						addVertex(x, y, z,
								  nx, ny, nz,
								  -(length? ny/length : y/_radius), (length? nx/length : x/_radius), 0);

					// close triangle
					if(i > 0 && j > 0)
					{
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
			target.updateVertexData(_rawVertexPositions);
			target.updateVertexNormalData(_rawVertexNormals);
			target.updateVertexTangentData(_rawVertexTangents);
			target.updateIndexData(_rawIndices);
		}

		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target : SubGeometry) : void
		{
			var i:int, j:int;

			// evaluate num uvs
			var numUvs:uint = _numVertices * 2;

			// need to initialize raw array or can be reused?
			if (target.UVData && numUvs == target.UVData.length)
				_rawUvs = target.UVData;
			else
				_rawUvs = new Vector.<Number>(numUvs, true);
			
			// current uv component index
			var currentUvCompIndex:uint = 0;
			
			// surface
			for(j = 0; j <= _segmentsT; ++j)
			{
				for(i = 0; i <= _segmentsR; ++i)
				{
					// revolution vertex
					_rawUvs[currentUvCompIndex++] = i / _segmentsR;
					_rawUvs[currentUvCompIndex++] = j / _segmentsT;
				}
			}

			// build real data from raw data
			target.updateUVData(_rawUvs);
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