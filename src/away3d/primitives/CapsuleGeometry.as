package away3d.primitives
{

	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SubGeometry;

	/**
	 * A UV Capsule primitive mesh.
	 */
	public class CapsuleGeometry extends PrimitiveBase
	{
		private var _radius:Number;
		private var _height:Number;
		private var _segmentsW:uint;
		private var _segmentsH:uint;
		private var _yUp:Boolean;

		/**
		 * Creates a new Capsule object.
		 * @param radius The radius of the capsule.
		 * @param height The height of the capsule.
		 * @param segmentsW Defines the number of horizontal segments that make up the capsule. Defaults to 16.
		 * @param segmentsH Defines the number of vertical segments that make up the capsule. Defaults to 12.
		 * @param yUp Defines whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function CapsuleGeometry(radius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 12, yUp:Boolean = true)
		{
			super();

			_radius = radius;
			_height = height;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_yUp = yUp;
		}

		/**
		 * @inheritDoc
		 */
		protected override function buildGeometry(target:CompactSubGeometry):void
		{
			var data:Vector.<Number>;
			var indices:Vector.<uint>;
			var i:uint, j:uint, triIndex:uint;
			var numVerts:uint 	= (_segmentsH + 1)*(_segmentsW + 1);
			var stride:uint = target.vertexStride;
			var skip:uint = stride - 9;

			if(numVerts == target.numVertices)
			{
				data = target.vertexData;
				indices = target.indexData || new Vector.<uint>((_segmentsH - 1)*_segmentsW*6, true);
			}
			else
			{
				data = new Vector.<Number>(numVerts*stride, true);
				indices = new Vector.<uint>((_segmentsH - 1)*_segmentsW*6, true);
				invalidateUVs();
			}

			var index : uint = 0;
			for(j = 0; j <= _segmentsH; ++j)
			{
				var horangle:Number = Math.PI*j/_segmentsH;
				var z:Number = -_radius*Math.cos(horangle);
				var ringradius:Number = _radius*Math.sin(horangle);

				for(i = 0; i <= _segmentsW; ++i)
				{
					var verangle:Number = 2*Math.PI*i/_segmentsW;
					var x:Number = ringradius*Math.cos(verangle);
					var offset:Number = j > _segmentsH/2 ? _height/2 : -_height/2;
					var y:Number = ringradius*Math.sin(verangle);
					var normLen:Number = 1/Math.sqrt(x*x + y*y + z*z);
					var tanLen:Number = Math.sqrt(y*y + x*x);

					if(_yUp)
					{
						// vertex
						data[index++] = x;
						data[index++] = -z - offset;
						data[index++] = y;
						// normal
						data[index++] = x*normLen;
						data[index++] = -z*normLen;
						data[index++] = y*normLen;
						// tangent
						data[index++] = tanLen > .007 ? -y/tanLen : 1;
						data[index++] = 0;
						data[index++] = tanLen > .007 ? x/tanLen : 0;
					}
					else
					{
						// vertex
						data[index++] = x;
						data[index++] = y;
						data[index++] = z + offset;
						// normal
						data[index++] = x*normLen;
						data[index++] = y*normLen;
						data[index++] = z*normLen;
						// tangent
						data[index++] = tanLen > .007 ? -y/tanLen : 1;
						data[index++] = tanLen > .007 ? x/tanLen : 0;
						data[index++] = 0;
					}

					index += skip;

					if(i > 0 && j > 0)
					{
						var a:int = (_segmentsW + 1)*j + i;
						var b:int = (_segmentsW + 1)*j + i - 1;
						var c:int = (_segmentsW + 1)*(j - 1) + i - 1;
						var d:int = (_segmentsW + 1)*(j - 1) + i;

						if(j == _segmentsH)
						{
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
						}
						else if(j == 1)
						{
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
						}
						else
						{
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
						}
					}
				}
			}

			target.updateData(data);
			target.updateIndexData(indices);
		}

		/**
		 * @inheritDoc
		 */
		protected override function buildUVs(target:CompactSubGeometry):void
		{
			var i:int, j:int;
			var index : uint;
			var data:Vector.<Number>;
			var stride:uint = target.UVStride;
			var UVlen:uint = (_segmentsH + 1)*(_segmentsW + 1)*stride;
			var skip:uint = stride - 2;

			if(target.UVData && UVlen == target.UVData.length)
				data = target.UVData;
			else {
				data = new Vector.<Number>(UVlen, true);
				invalidateGeometry();
			}

			index = target.UVOffset;
			for(j = 0; j <= _segmentsH; ++j)
			{
				for(i = 0; i <= _segmentsW; ++i)
				{
					data[index++] = i/_segmentsW;
					data[index++] = j/_segmentsH;
					index += skip;
				}
			}

			target.updateData(data);
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
		 * Defines the number of vertical segments that make up the capsule. Defaults to 12.
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
