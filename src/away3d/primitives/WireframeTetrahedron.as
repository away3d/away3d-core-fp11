package away3d.primitives
{
	import flash.geom.Vector3D;
	
	import away3d.primitives.WireframePrimitiveBase;
	
	/**
	 * A WireframeTetrahedron primitive mesh
	 */
	public class WireframeTetrahedron extends WireframePrimitiveBase
	{
		
		public static const ORIENTATION_YZ:String = "yz";
		public static const ORIENTATION_XY:String = "xy";
		public static const ORIENTATION_XZ:String = "xz";
		
		private var _width:Number;
		private var _height:Number;
		private var _orientation:String;
		
		/**
		 * Creates a new WireframeTetrahedron object.
		 * @param width The size of the tetrahedron buttom size.
		 * @param height The size of the tetranhedron height.
		 * @param color The color of the wireframe lines.
		 * @param thickness The thickness of the wireframe lines.
		 */
		public function WireframeTetrahedron(width:Number, height:Number, color:uint = 0xffffff, thickness:Number = 1, orientation:String = "yz")
		{
			super(color, thickness);
			
			_width = width;
			_height = height;
			
			_orientation = orientation;
		}
		
		/**
		 * The orientation in which the plane lies
		 */
		public function get orientation():String
		{
			return _orientation;
		}
		
		public function set orientation(value:String):void
		{
			_orientation = value;
			invalidateGeometry();
		}
		
		/**
		 * The size of the tetrahedron bottom.
		 */
		public function get width():Number
		{
			return _width;
		}
		
		public function set width(value:Number):void
		{
			if (value <= 0)
				throw new Error("Value needs to be greater than 0");
			_width = value;
			invalidateGeometry();
		}
		
		/**
		 * The size of the tetrahedron height.
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
		 * @inheritDoc
		 */
		override protected function buildGeometry():void
		{
			
			var bv0:Vector3D;
			var bv1:Vector3D;
			var bv2:Vector3D;
			var bv3:Vector3D;
			var top:Vector3D;
			const hw:Number = _width*0.5;
			
			switch (_orientation) {
				case ORIENTATION_XY:
					bv0 = new Vector3D(-hw, hw, 0);
					bv1 = new Vector3D(hw, hw, 0);
					bv2 = new Vector3D(hw, -hw, 0);
					bv3 = new Vector3D(-hw, -hw, 0);
					top = new Vector3D(0, 0, _height);
					break;
				case ORIENTATION_XZ:
					bv0 = new Vector3D(-hw, 0, hw);
					bv1 = new Vector3D(hw, 0, hw);
					bv2 = new Vector3D(hw, 0, -hw);
					bv3 = new Vector3D(-hw, 0, -hw);
					top = new Vector3D(0, _height, 0);
					break;
				case ORIENTATION_YZ:
					bv0 = new Vector3D(0, -hw, hw);
					bv1 = new Vector3D(0, hw, hw);
					bv2 = new Vector3D(0, hw, -hw);
					bv3 = new Vector3D(0, -hw, -hw);
					top = new Vector3D(_height, 0, 0);
					break;
			}
			//bottom
			updateOrAddSegment(0, bv0, bv1);
			updateOrAddSegment(1, bv1, bv2);
			updateOrAddSegment(2, bv2, bv3);
			updateOrAddSegment(3, bv3, bv0);
			//bottom to top
			updateOrAddSegment(4, bv0, top);
			updateOrAddSegment(5, bv1, top);
			updateOrAddSegment(6, bv2, top);
			updateOrAddSegment(7, bv3, top);
		}
	}
}
