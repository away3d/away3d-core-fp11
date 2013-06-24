package away3d.primitives
{
	import flash.geom.Vector3D;
	
	/**
	 * A WireframeRegularPolygon primitive mesh.
	 */
	public class WireframeRegularPolygon extends WireframePrimitiveBase
	{
		public static const ORIENTATION_YZ:String = "yz";
		public static const ORIENTATION_XY:String = "xy";
		public static const ORIENTATION_XZ:String = "xz";
		
		private var _radius:Number;
		private var _sides:int;
		private var _orientation:String;
		
		/**
		 * Creates a new WireframeRegularPolygon object.
		 * @param radius The radius of the polygon.
		 * @param sides The number of sides on the polygon.
		 * @param color The colour of the wireframe lines
		 * @param thickness The thickness of the wireframe lines
		 * @param orientation The orientaion in which the plane lies.
		 */
		public function WireframeRegularPolygon(radius:Number, sides:int, color:uint = 0xFFFFFF, thickness:Number = 1, orientation:String = "yz")
		{
			super(color, thickness);
			
			_radius = radius;
			_sides = sides;
			_orientation = orientation;
		}
		
		/**
		 * The orientaion in which the polygon lies.
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
		 * The radius of the regular polygon.
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
		 * The number of sides to the regular polygon.
		 */
		public function get sides():int
		{
			return _sides;
		}
		
		public function set sides(value:int):void
		{
			_sides = value;
			removeAllSegments();
			invalidateGeometry();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function buildGeometry():void
		{
			var v0:Vector3D = new Vector3D();
			var v1:Vector3D = new Vector3D();
			var index:int;
			var s:int;
			
			if (_orientation == ORIENTATION_XY) {
				v0.z = 0;
				v1.z = 0;
				
				for (s = 0; s < _sides; ++s) {
					v0.x = _radius*Math.cos(2*Math.PI*s/_sides);
					v0.y = _radius*Math.sin(2*Math.PI*s/_sides);
					v1.x = _radius*Math.cos(2*Math.PI*(s + 1)/_sides);
					v1.y = _radius*Math.sin(2*Math.PI*(s + 1)/_sides);
					updateOrAddSegment(index++, v0, v1);
				}
			}
			
			else if (_orientation == ORIENTATION_XZ) {
				v0.y = 0;
				v1.y = 0;
				
				for (s = 0; s < _sides; ++s) {
					v0.x = _radius*Math.cos(2*Math.PI*s/_sides);
					v0.z = _radius*Math.sin(2*Math.PI*s/_sides);
					v1.x = _radius*Math.cos(2*Math.PI*(s + 1)/_sides);
					v1.z = _radius*Math.sin(2*Math.PI*(s + 1)/_sides);
					updateOrAddSegment(index++, v0, v1);
				}
			}
			
			else if (_orientation == ORIENTATION_YZ) {
				v0.x = 0;
				v1.x = 0;
				
				for (s = 0; s < _sides; ++s) {
					v0.z = _radius*Math.cos(2*Math.PI*s/_sides);
					v0.y = _radius*Math.sin(2*Math.PI*s/_sides);
					v1.z = _radius*Math.cos(2*Math.PI*(s + 1)/_sides);
					v1.y = _radius*Math.sin(2*Math.PI*(s + 1)/_sides);
					updateOrAddSegment(index++, v0, v1);
				}
			}
		}
	
	}
}
