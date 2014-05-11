package away3d.prefabs
{
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.library.assets.IAsset;

	/**
	 * A Capsule primitive.
	 */
	public class PrimitiveCapsulePrefab extends PrimitivePrefabBase
	{
		private var _radius:Number;
		private var _height:Number;
		private var _segmentsW:uint;
		private var _segmentsH:uint;
		private var _yUp:Boolean;
		private var _numVertices:uint = 0;
		
		/**
		 * Creates a new Capsule object.
		 * @param radius The radius of the capsule.
		 * @param height The height of the capsule.
		 * @param segmentsW Defines the number of horizontal segments that make up the capsule. Defaults to 16.
		 * @param segmentsH Defines the number of vertical segments that make up the capsule. Defaults to 15. Must be uneven value.
		 * @param yUp Defines whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function PrimitiveCapsulePrefab(radius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 15, yUp:Boolean = true)
		{
			super();
			
			_radius = radius;
			_height = height;
			_segmentsW = segmentsW;
			_segmentsH = (segmentsH%2 == 0)? segmentsH + 1 : segmentsH;
			_yUp = yUp;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function buildGeometry(target:SubGeometryBase, geometryType:String):void
		{
			var indices:Vector.<uint> /*uint*/;
			var positions:Vector.<Number>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;

			var i:uint, j:uint, triIndex:uint;
			var index:uint = 0;
			var startIndex:uint;
			var comp1:Number, comp2:Number, t1:Number, t2:Number;
			var numIndices:Number = 0;
			if (geometryType == "triangleSubGeometry") {
				var triangleGeometry:TriangleSubGeometry = target as TriangleSubGeometry;

				// evaluate target number of vertices, triangles and indices
				_numVertices = (_segmentsH + 1)*(_segmentsW + 1); // segmentsH + 1 because of closure, segmentsW + 1 because of closure
				numIndices = (_segmentsH - 1)*_segmentsW*6; // each level has segmentH quads, each of 2 triangles
				// need to initialize raw arrays or can be reused?
				if (_numVertices == triangleGeometry.numVertices) {
					indices = triangleGeometry.indices;
					positions = triangleGeometry.positions;
					normals = triangleGeometry.vertexNormals;
					tangents = triangleGeometry.vertexTangents;
				} else {
					indices = new Vector.<uint>(numIndices)
					positions = new Vector.<Number>(_numVertices*3);
					normals = new Vector.<Number>(_numVertices*3);
					tangents = new Vector.<Number>(_numVertices*3);

					invalidateUVs();
				}

				for (j = 0; j <= _segmentsH; ++j) {

					var horangle:Number = Math.PI*j/_segmentsH;
					var z:Number = -_radius*Math.cos(horangle);
					var ringradius:Number = _radius*Math.sin(horangle);
					startIndex = index;

					for (i = 0; i <= _segmentsW; ++i) {
						var verangle:Number = 2*Math.PI*i/_segmentsW;
						var x:Number = ringradius*Math.cos(verangle);
						var offset:Number = j > _segmentsH/2? _height/2 : -_height/2;
						var y:Number = ringradius*Math.sin(verangle);
						var normLen:Number = 1/Math.sqrt(x*x + y*y + z*z);
						var tanLen:Number = Math.sqrt(y*y + x*x);

						if (_yUp) {
							t1 = 0;
							t2 = tanLen > .007? x/tanLen : 0;
							comp1 = -z;
							comp2 = y;

						} else {
							t1 = tanLen > .007? x/tanLen : 0;
							t2 = 0;
							comp1 = y;
							comp2 = z;
						}

						if (i == _segmentsW) {

							positions[index] = positions[startIndex];
							positions[index + 1] = positions[startIndex + 1];
							positions[index + 2] = positions[startIndex + 2];
							normals[index] = (normals[startIndex] + (x*normLen))*.5;
							normals[index + 1] = (normals[startIndex + 1] + ( comp1*normLen))*.5;
							normals[index + 2] = (normals[startIndex + 2] + (comp2*normLen))*.5;
							tangents[index] = (tangents[startIndex] + (tanLen > .007? -y/tanLen : 1))*.5;
							tangents[index + 1] = (tangents[startIndex + 1] + t1)*.5;
							tangents[index + 2] = (tangents[startIndex + 2] + t2)*.5;

						} else {
							// vertex
							positions[index] = x;
							positions[index + 1] = (_yUp)? comp1 - offset : comp1;
							positions[index + 2] = (_yUp)? comp2 : comp2 + offset;
							// normal
							normals[index] = x*normLen;
							normals[index + 1] = comp1*normLen;
							normals[index + 2] = comp2*normLen;
							// tangent
							tangents[index] = tanLen > .007? -y/tanLen : 1;
							tangents[index + 1] = t1;
							tangents[index + 2] = t2;
						}

						if (i > 0 && j > 0) {
							var a:int = (_segmentsW + 1)*j + i;
							var b:int = (_segmentsW + 1)*j + i - 1;
							var c:int = (_segmentsW + 1)*(j - 1) + i - 1;
							var d:int = (_segmentsW + 1)*(j - 1) + i;

							if (j == _segmentsH) {
								positions[index] = positions[startIndex];
								positions[index + 1] = positions[startIndex + 1];
								positions[index + 2] = positions[startIndex + 2];

								indices[triIndex++] = a;
								indices[triIndex++] = c;
								indices[triIndex++] = d;

							} else if (j == 1) {
								indices[triIndex++] = a;
								indices[triIndex++] = b;
								indices[triIndex++] = c;

							} else {
								indices[triIndex++] = a;
								indices[triIndex++] = b;
								indices[triIndex++] = c;
								indices[triIndex++] = a;
								indices[triIndex++] = c;
								indices[triIndex++] = d;
							}
						}

						index += 3;
					}
				}
				// build real data from raw data
				triangleGeometry.updateIndices(indices);

				triangleGeometry.updatePositions(positions);
				triangleGeometry.updateVertexNormals(normals);
				triangleGeometry.updateVertexTangents(tangents);
			}else if(geometryType == GeometryType.LINE) {
				//TODO:
			}
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target:SubGeometryBase, geometryType:String):void
		{
			var i:Number, j:Number;
			var uvs:Vector.<Number>;


			if (geometryType == GeometryType.TRIANGLES) {

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
				for (j = 0; j <= _segmentsH; ++j) {
					for (i = 0; i <= _segmentsW; ++i) {
						// revolution vertex
						uvs[index++] = ( i / _segmentsW ) * triangleGeometry.scaleU;
						uvs[index++] = ( j / _segmentsH ) * triangleGeometry.scaleV;
					}
				}

				// build real data from raw data
				triangleGeometry.updateUVs(uvs);
			}
		}

		/**
		 * The radius of the capsule.
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
		 * The height of the capsule.
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
		 * Defines the number of horizontal segments that make up the capsule. Defaults to 16.
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
		 * Defines the number of vertical segments that make up the capsule. Defaults to 15. Must be uneven.
		 */
		public function get segmentsH():uint
		{
			return _segmentsH;
		}
		
		public function set segmentsH(value:uint):void
		{
			_segmentsH = (value%2 == 0)? value + 1 : value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
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
