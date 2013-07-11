package away3d.primitives
{
	import flash.geom.Vector3D;
	
	/**
	 * A WirefameCube primitive mesh.
	 */
	public class WireframeCube extends WireframePrimitiveBase
	{
		private var _width:Number;
		private var _height:Number;
		private var _depth:Number;
		
		/**
		 * Creates a new WireframeCube object.
		 * @param width The size of the cube along its X-axis.
		 * @param height The size of the cube along its Y-axis.
		 * @param depth The size of the cube along its Z-axis.
		 * @param color The colour of the wireframe lines
		 * @param thickness The thickness of the wireframe lines
		 */
		public function WireframeCube(width:Number = 100, height:Number = 100, depth:Number = 100, color:uint = 0xFFFFFF, thickness:Number = 1)
		{
			super(color, thickness);
			
			_width = width;
			_height = height;
			_depth = depth;
		}
		
		/**
		 * The size of the cube along its X-axis.
		 */
		public function get width():Number
		{
			return _width;
		}
		
		public function set width(value:Number):void
		{
			_width = value;
			invalidateGeometry();
		}
		
		/**
		 * The size of the cube along its Y-axis.
		 */
		public function get height():Number
		{
			return _height;
		}
		
		public function set height(value:Number):void
		{
			if (value <= 0)
				throw new Error("Value needs to be greater than 0");
			_height = value;
			invalidateGeometry();
		}
		
		/**
		 * The size of the cube along its Z-axis.
		 */
		public function get depth():Number
		{
			return _depth;
		}
		
		public function set depth(value:Number):void
		{
			_depth = value;
			invalidateGeometry();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function buildGeometry():void
		{
			var v0:Vector3D = new Vector3D();
			var v1:Vector3D = new Vector3D();
			var hw:Number = _width*.5;
			var hh:Number = _height*.5;
			var hd:Number = _depth*.5;
			
			v0.x = -hw;
			v0.y = hh;
			v0.z = -hd;
			v1.x = -hw;
			v1.y = -hh;
			v1.z = -hd;
			
			updateOrAddSegment(0, v0, v1);
			v0.z = hd;
			v1.z = hd;
			updateOrAddSegment(1, v0, v1);
			v0.x = hw;
			v1.x = hw;
			updateOrAddSegment(2, v0, v1);
			v0.z = -hd;
			v1.z = -hd;
			updateOrAddSegment(3, v0, v1);
			
			v0.x = -hw;
			v0.y = -hh;
			v0.z = -hd;
			v1.x = hw;
			v1.y = -hh;
			v1.z = -hd;
			updateOrAddSegment(4, v0, v1);
			v0.y = hh;
			v1.y = hh;
			updateOrAddSegment(5, v0, v1);
			v0.z = hd;
			v1.z = hd;
			updateOrAddSegment(6, v0, v1);
			v0.y = -hh;
			v1.y = -hh;
			updateOrAddSegment(7, v0, v1);
			
			v0.x = -hw;
			v0.y = -hh;
			v0.z = -hd;
			v1.x = -hw;
			v1.y = -hh;
			v1.z = hd;
			updateOrAddSegment(8, v0, v1);
			v0.y = hh;
			v1.y = hh;
			updateOrAddSegment(9, v0, v1);
			v0.x = hw;
			v1.x = hw;
			updateOrAddSegment(10, v0, v1);
			v0.y = -hh;
			v1.y = -hh;
			updateOrAddSegment(11, v0, v1);
		}
	}
}
