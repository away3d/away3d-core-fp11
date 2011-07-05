package away3d.primitives
{
	import flash.geom.Vector3D;

	/**
	* Class WireFrameGrid generates a grid of lines on a given plane<code>WireFrameGrid</code>
	* @param	subDivision		[optional] uint . Default is 10;
	* @param	gridSize				[optional] uint . Default is 100;
	* @param	color					[optional] uint . Default is 0xFFFFFF;
	* @param	thickness			[optional] Number . Default is 1;
	* @param	plane					[optional] String . Default is PLANE_XZ;
	* @param	worldPlanes		[optional] Boolean . Default is false.
	* If true, class displays the 3 world planes, at 0,0,0. with subDivision, thickness and and gridSize. Overrides color and plane settings.
	*/
		
	public class WireframeCube extends WireframePrimitiveBase
	{
		private var _width : Number;
		private var _height : Number;
		private var _depth : Number;

		public function WireframeCube(width : Number, height : Number, depth : Number, color:uint = 0xFFFFFF, thickness:Number = 1) {
			super(color, thickness);

			_width = width;
			_height = height;
			_depth = depth;
		}

		public function get width() : Number
		{
			return _width;
		}

		public function set width(value : Number) : void
		{
			_width = value;
			invalidateGeometry();
		}

		public function get height() : Number
		{
			return _height;
		}

		public function set height(value : Number) : void
		{
			if (value <= 0) throw new Error("Value needs to be greater than 0");
			_height = value;
			invalidateGeometry();
		}

		public function get depth() : Number
		{
			return _depth;
		}

		public function set depth(value : Number) : void
		{
			_depth = value;
			invalidateGeometry();
		}

		override protected function buildGeometry() : void
		{
			var v0 : Vector3D = new Vector3D();
			var v1 : Vector3D = new Vector3D();
			var hw : Number = _width*.5;
			var hh : Number = _height*.5;
			var hd : Number = _depth*.5;

			v0.x = -hw;	v0.y = hh; v0.z = -hd;
			v1.x = -hw; v1.y = -hh; v1.z = -hd;

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

			v0.x = -hw;	v0.y = -hh; v0.z = -hd;
			v1.x = hw; v1.y = -hh; v1.z = -hd;
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

			v0.x = -hw;	v0.y = -hh; v0.z = -hd;
			v1.x = -hw; v1.y = -hh; v1.z = hd;
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
