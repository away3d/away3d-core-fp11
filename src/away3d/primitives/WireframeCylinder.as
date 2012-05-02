package away3d.primitives
{
	import flash.geom.Vector3D;

	/**
	 * Generates a wireframd cylinder primitive.
	 */
	public class WireframeCylinder extends WireframePrimitiveBase
	{
		private static const TWO_PI:Number = 2*Math.PI;

		private var _topRadius:Number;
		private var _bottomRadius:Number;
		private var _height:Number;
		private var _segmentsW:uint;
		private var _segmentsH:uint;

		/**
		 * Creates a new WireframeCylinder instance
		 * @param topRadius Top radius of the cylinder
		 * @param bottomRadius Bottom radius of the cylinder
		 * @param height The height of the cylinder
		 * @param segmentsW Number of radial segments
		 * @param segmentsH Number of vertical segments
		 * @param color The color of the wireframe lines
		 * @param thickness The thickness of the wireframe lines
		 */
		public function WireframeCylinder(topRadius:Number = 50, bottomRadius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 1, color:uint = 0xFFFFFF, thickness:Number = 1)
		{
			super(color, thickness);
			_topRadius = topRadius;
			_bottomRadius = bottomRadius;
			_height = height;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
		}


		override protected function buildGeometry():void
		{

			var i:uint, j:uint;
			var radius:Number = _topRadius;
			var revolutionAngle:Number;
			var revolutionAngleDelta:Number = TWO_PI/_segmentsW;
			var nextVertexIndex:int = 0;
			var x:Number, y:Number, z:Number;
			var lastLayer:Vector.<Vector.<Vector3D>> = new Vector.<Vector.<Vector3D>>(_segmentsH + 1, true);

			for (j = 0; j <= _segmentsH; ++j)
			{
				lastLayer[j] = new Vector.<Vector3D>(_segmentsW + 1, true);

				radius = _topRadius - ((j/_segmentsH)*(_topRadius - _bottomRadius));
				z = -(_height/2) + (j/_segmentsH*_height);

				var previousV:Vector3D = null;

				for (i = 0; i <= _segmentsW; ++i)
				{
					// revolution vertex
					revolutionAngle = i*revolutionAngleDelta;
					x = radius*Math.cos(revolutionAngle);
					y = radius*Math.sin(revolutionAngle);
					var vertex:Vector3D;
					if (previousV)
					{
						vertex = new Vector3D(x, -z, y);
						updateOrAddSegment(nextVertexIndex++, vertex, previousV);
						previousV = vertex;
					}
					else
					{
						previousV = new Vector3D(x, -z, y);
					}

					if (j > 0)
						updateOrAddSegment(nextVertexIndex++, vertex, lastLayer[j - 1][i]);
					lastLayer[j][i] = previousV;
				}
			}
		}


		/**
		 * Top radius of the cylinder
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
		 * Bottom radius of the cylinder
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
		 * The height of the cylinder
		 */
		public function get height():Number
		{
			return _height;
		}


		public function set height(value:Number):void
		{
			if (height <= 0)
				throw new Error('Height must be a value greater than zero.');
			_height = value;
			invalidateGeometry();
		}
	}
}
