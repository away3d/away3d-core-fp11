package away3d.primitives
{
	import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	
	use namespace arcane;
	
	/**
	 * A UV Sphere primitive mesh.
	 */
	public class SphereGeometry extends PrimitiveBase
	{
		private var _radius:Number;
		private var _segmentsW:uint;
		private var _segmentsH:uint;
		private var _yUp:Boolean;
		
		/**
		 * Creates a new Sphere object.
		 * @param radius The radius of the sphere.
		 * @param segmentsW Defines the number of horizontal segments that make up the sphere.
		 * @param segmentsH Defines the number of vertical segments that make up the sphere.
		 * @param yUp Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function SphereGeometry(radius:Number = 50, segmentsW:uint = 16, segmentsH:uint = 12, yUp:Boolean = true)
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
		protected override function buildGeometry(target:CompactSubGeometry):void
		{
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var i:uint, j:uint, triIndex:uint;
			var numVerts:uint = (_segmentsH + 1)*(_segmentsW + 1);
			var stride:uint = target.vertexStride;
			var skip:uint = stride - 9;
			
			if (numVerts == target.numVertices) {
				vertices = target.vertexData;
				indices = target.indexData || new Vector.<uint>((_segmentsH - 1)*_segmentsW*6, true);
			} else {
				vertices = new Vector.<Number>(numVerts*stride, true);
				indices = new Vector.<uint>((_segmentsH - 1)*_segmentsW*6, true);
				invalidateGeometry();
			}
			
			var startIndex:uint;
			var index:uint = target.vertexOffset;
			var comp1:Number, comp2:Number, t1:Number, t2:Number;
			
			for (j = 0; j <= _segmentsH; ++j) {
				
				startIndex = index;
				
				var horangle:Number = Math.PI*j/_segmentsH;
				var z:Number = -_radius*Math.cos(horangle);
				var ringradius:Number = _radius*Math.sin(horangle);
				
				for (i = 0; i <= _segmentsW; ++i) {
					var verangle:Number = 2*Math.PI*i/_segmentsW;
					var x:Number = ringradius*Math.cos(verangle);
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
						vertices[index++] = vertices[startIndex];
						vertices[index++] = vertices[startIndex + 1];
						vertices[index++] = vertices[startIndex + 2];
						vertices[index++] = vertices[startIndex + 3] + (x*normLen)*.5;
						vertices[index++] = vertices[startIndex + 4] + ( comp1*normLen)*.5;
						vertices[index++] = vertices[startIndex + 5] + (comp2*normLen)*.5;
						vertices[index++] = tanLen > .007? -y/tanLen : 1;
						vertices[index++] = t1;
						vertices[index++] = t2;
						
					} else {
						vertices[index++] = x;
						vertices[index++] = comp1;
						vertices[index++] = comp2;
						vertices[index++] = x*normLen;
						vertices[index++] = comp1*normLen;
						vertices[index++] = comp2*normLen;
						vertices[index++] = tanLen > .007? -y/tanLen : 1;
						vertices[index++] = t1;
						vertices[index++] = t2;
					}
					
					if (i > 0 && j > 0) {
						var a:int = (_segmentsW + 1)*j + i;
						var b:int = (_segmentsW + 1)*j + i - 1;
						var c:int = (_segmentsW + 1)*(j - 1) + i - 1;
						var d:int = (_segmentsW + 1)*(j - 1) + i;
						
						if (j == _segmentsH) {
							vertices[index - 9] = vertices[startIndex];
							vertices[index - 8] = vertices[startIndex + 1];
							vertices[index - 7] = vertices[startIndex + 2];
							
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
					
					index += skip;
				}
			}
			
			target.updateData(vertices);
			target.updateIndexData(indices);
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target:CompactSubGeometry):void
		{
			var i:int, j:int;
			var stride:uint = target.UVStride;
			var numUvs:uint = (_segmentsH + 1)*(_segmentsW + 1)*stride;
			var data:Vector.<Number>;
			var skip:uint = stride - 2;
			
			if (target.UVData && numUvs == target.UVData.length)
				data = target.UVData;
			else {
				data = new Vector.<Number>(numUvs, true);
				invalidateGeometry();
			}
			
			var index:int = target.UVOffset;
			for (j = 0; j <= _segmentsH; ++j) {
				for (i = 0; i <= _segmentsW; ++i) {
					data[index++] = ( i/_segmentsW )*target.scaleU;
					data[index++] = ( j/_segmentsH )*target.scaleV;
					index += skip;
				}
			}
			
			target.updateData(data);
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
		 * Defines the number of horizontal segments that make up the sphere. Defaults to 16.
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
		 * Defines the number of vertical segments that make up the sphere. Defaults to 12.
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
