package away3d.primitives
{
	import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	
	use namespace arcane;
	
	/**
	 * A Cylinder primitive mesh.
	 */
	public class CylinderGeometry extends PrimitiveBase
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
		private var _rawData:Vector.<Number>;
		private var _rawIndices:Vector.<uint>;
		private var _nextVertexIndex:uint;
		private var _currentIndex:uint;
		private var _currentTriangleIndex:uint;
		private var _numVertices:uint;
		private var _stride:uint;
		private var _vertexOffset:uint;
		
		private function addVertex(px:Number, py:Number, pz:Number, nx:Number, ny:Number, nz:Number, tx:Number, ty:Number, tz:Number):void
		{
			var compVertInd:uint = _vertexOffset + _nextVertexIndex*_stride; // current component vertex index
			_rawData[compVertInd++] = px;
			_rawData[compVertInd++] = py;
			_rawData[compVertInd++] = pz;
			_rawData[compVertInd++] = nx;
			_rawData[compVertInd++] = ny;
			_rawData[compVertInd++] = nz;
			_rawData[compVertInd++] = tx;
			_rawData[compVertInd++] = ty;
			_rawData[compVertInd++] = tz;
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
		protected override function buildGeometry(target:CompactSubGeometry):void
		{
			var i:uint, j:uint;
			var x:Number, y:Number, z:Number, radius:Number, revolutionAngle:Number;
			var dr:Number, latNormElev:Number, latNormBase:Number;
			var numTriangles:uint = 0;
			
			var comp1:Number, comp2:Number;
			var startIndex:uint;
			//numvert:uint = 0;
			var t1:Number, t2:Number;
			
			_stride = target.vertexStride;
			_vertexOffset = target.vertexOffset;
			
			// reset utility variables
			_numVertices = 0;
			_nextVertexIndex = 0;
			_currentIndex = 0;
			_currentTriangleIndex = 0;
			
			// evaluate target number of vertices, triangles and indices
			if (_surfaceClosed) {
				_numVertices += (_segmentsH + 1)*(_segmentsW + 1); // segmentsH + 1 because of closure, segmentsW + 1 because of UV unwrapping
				numTriangles += _segmentsH*_segmentsW*2; // each level has segmentW quads, each of 2 triangles
			}
			if (_topClosed) {
				_numVertices += 2*(_segmentsW + 1); // segmentsW + 1 because of unwrapping
				numTriangles += _segmentsW; // one triangle for each segment
			}
			if (_bottomClosed) {
				_numVertices += 2*(_segmentsW + 1);
				numTriangles += _segmentsW;
			}
			
			// need to initialize raw arrays or can be reused?
			if (_numVertices == target.numVertices) {
				_rawData = target.vertexData;
				_rawIndices = target.indexData || new Vector.<uint>(numTriangles*3, true);
			} else {
				var numVertComponents:uint = _numVertices*_stride;
				_rawData = new Vector.<Number>(numVertComponents, true);
				_rawIndices = new Vector.<uint>(numTriangles*3, true);
			}
			
			// evaluate revolution steps
			var revolutionAngleDelta:Number = 2*Math.PI/_segmentsW;
			
			// top
			if (_topClosed && _topRadius > 0) {
				
				z = -0.5*_height;
				
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
					
					addVertex(0, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					// revolution vertex
					revolutionAngle = i*revolutionAngleDelta;
					x = _topRadius*Math.cos(revolutionAngle);
					y = _topRadius*Math.sin(revolutionAngle);
					
					if (_yUp) {
						comp1 = -z;
						comp2 = y;
					} else {
						comp1 = y;
						comp2 = z;
					}
					
					if (i == _segmentsW)
						addVertex(_rawData[startIndex + _stride], _rawData[startIndex + _stride + 1], _rawData[startIndex + _stride + 2], 0, t1, t2, 1, 0, 0);
					else
						addVertex(x, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					if (i > 0) // add triangle
						addTriangleClockWise(_nextVertexIndex - 1, _nextVertexIndex - 3, _nextVertexIndex - 2);
				}
			}
			
			// bottom
			if (_bottomClosed && _bottomRadius > 0) {
				
				z = 0.5*_height;
				
				startIndex = _vertexOffset + _nextVertexIndex*_stride;
				
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
					
					addVertex(0, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					// revolution vertex
					revolutionAngle = i*revolutionAngleDelta;
					x = _bottomRadius*Math.cos(revolutionAngle);
					y = _bottomRadius*Math.sin(revolutionAngle);
					
					if (_yUp) {
						comp1 = -z;
						comp2 = y;
					} else {
						comp1 = y;
						comp2 = z;
					}
					
					if (i == _segmentsW)
						addVertex(x, _rawData[startIndex + 1], _rawData[startIndex + 2], 0, t1, t2, 1, 0, 0);
					else
						addVertex(x, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					if (i > 0) // add triangle
						addTriangleClockWise(_nextVertexIndex - 2, _nextVertexIndex - 3, _nextVertexIndex - 1);
				}
			}
			
			// The normals on the lateral surface all have the same incline, i.e.
			// the "elevation" component (Y or Z depending on yUp) is constant.
			// Same principle goes for the "base" of these vectors, which will be
			// calculated such that a vector [base,elev] will be a unit vector.
			dr = (_bottomRadius - _topRadius);
			latNormElev = dr/_height;
			latNormBase = (latNormElev == 0)? 1 : _height/dr;
			
			// lateral surface
			if (_surfaceClosed) {
				var a:uint, b:uint, c:uint, d:uint;
				var na0:Number, na1:Number, naComp1:Number, naComp2:Number;
				
				for (j = 0; j <= _segmentsH; ++j) {
					radius = _topRadius - ((j/_segmentsH)*(_topRadius - _bottomRadius));
					z = -(_height/2) + (j/_segmentsH*_height);
					
					startIndex = _vertexOffset + _nextVertexIndex*_stride;
					
					for (i = 0; i <= _segmentsW; ++i) {
						// revolution vertex
						revolutionAngle = i*revolutionAngleDelta;
						x = radius*Math.cos(revolutionAngle);
						y = radius*Math.sin(revolutionAngle);
						na0 = latNormBase*Math.cos(revolutionAngle);
						na1 = latNormBase*Math.sin(revolutionAngle);
						
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
							addVertex(_rawData[startIndex], _rawData[startIndex + 1], _rawData[startIndex + 2],
								na0, latNormElev, na1,
								na1, t1, t2);
						} else {
							addVertex(x, comp1, comp2,
								na0, naComp1, naComp2,
								-na1, t1, t2);
						}
						
						// close triangle
						if (i > 0 && j > 0) {
							a = _nextVertexIndex - 1; // current
							b = _nextVertexIndex - 2; // previous
							c = b - _segmentsW - 1; // previous of last level
							d = a - _segmentsW - 1; // current of last level
							addTriangleClockWise(a, b, c);
							addTriangleClockWise(a, c, d);
						}
					}
				}
			}
			
			// build real data from raw data
			target.updateData(_rawData);
			target.updateIndexData(_rawIndices);
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target:CompactSubGeometry):void
		{
			var i:int, j:int;
			var x:Number, y:Number, revolutionAngle:Number;
			var stride:uint = target.UVStride;
			var skip:uint = stride - 2;
			var UVData:Vector.<Number>;
			
			// evaluate num uvs
			var numUvs:uint = _numVertices*stride;
			
			// need to initialize raw array or can be reused?
			if (target.UVData && numUvs == target.UVData.length)
				UVData = target.UVData;
			else {
				UVData = new Vector.<Number>(numUvs, true);
				invalidateGeometry();
			}
			
			// evaluate revolution steps
			var revolutionAngleDelta:Number = 2*Math.PI/_segmentsW;
			
			// current uv component index
			var currentUvCompIndex:uint = target.UVOffset;
			
			// top
			if (_topClosed) {
				for (i = 0; i <= _segmentsW; ++i) {
					
					revolutionAngle = i*revolutionAngleDelta;
					x = 0.5 + 0.5* -Math.cos(revolutionAngle);
					y = 0.5 + 0.5*Math.sin(revolutionAngle);
					
					UVData[currentUvCompIndex++] = 0.5*target.scaleU; // central vertex
					UVData[currentUvCompIndex++] = 0.5*target.scaleV;
					currentUvCompIndex += skip;
					UVData[currentUvCompIndex++] = x*target.scaleU; // revolution vertex
					UVData[currentUvCompIndex++] = y*target.scaleV;
					currentUvCompIndex += skip;
				}
			}
			
			// bottom
			if (_bottomClosed) {
				for (i = 0; i <= _segmentsW; ++i) {
					
					revolutionAngle = i*revolutionAngleDelta;
					x = 0.5 + 0.5*Math.cos(revolutionAngle);
					y = 0.5 + 0.5*Math.sin(revolutionAngle);
					
					UVData[currentUvCompIndex++] = 0.5*target.scaleU; // central vertex
					UVData[currentUvCompIndex++] = 0.5*target.scaleV;
					currentUvCompIndex += skip;
					UVData[currentUvCompIndex++] = x*target.scaleU; // revolution vertex
					UVData[currentUvCompIndex++] = y*target.scaleV;
					currentUvCompIndex += skip;
				}
			}
			
			// lateral surface
			if (_surfaceClosed) {
				for (j = 0; j <= _segmentsH; ++j) {
					for (i = 0; i <= _segmentsW; ++i) {
						// revolution vertex
						UVData[currentUvCompIndex++] = ( i/_segmentsW )*target.scaleU;
						UVData[currentUvCompIndex++] = ( j/_segmentsH )*target.scaleV;
						currentUvCompIndex += skip;
					}
				}
			}
			
			// build real data from raw data
			target.updateData(UVData);
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
		 * Defines the number of horizontal segments that make up the cylinder. Defaults to 16.
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
		 * Defines the number of vertical segments that make up the cylinder. Defaults to 1.
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
		
		/**
		 * Creates a new Cylinder object.
		 * @param topRadius The radius of the top end of the cylinder.
		 * @param bottomRadius The radius of the bottom end of the cylinder
		 * @param height The radius of the bottom end of the cylinder
		 * @param segmentsW Defines the number of horizontal segments that make up the cylinder. Defaults to 16.
		 * @param segmentsH Defines the number of vertical segments that make up the cylinder. Defaults to 1.
		 * @param topClosed Defines whether the top end of the cylinder is closed (true) or open.
		 * @param bottomClosed Defines whether the bottom end of the cylinder is closed (true) or open.
		 * @param yUp Defines whether the cone poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function CylinderGeometry(topRadius:Number = 50, bottomRadius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 1, topClosed:Boolean = true, bottomClosed:Boolean = true, surfaceClosed:Boolean = true, yUp:Boolean = true)
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
	}
}
