package away3d.primitives
{
	/**
	 * A UV RegularPolygon primitive mesh.
	 */
	public class RegularPolygonGeometry extends CylinderGeometry {

		/**
		 * The radius of the regular polygon.
		 */
		public function get radius() : Number
		{
			return _bottomRadius;
		}
		
		public function set radius(value : Number) : void
		{
			_bottomRadius = value;
			invalidateGeometry();
		}


		/**
		 * The number of sides of the regular polygon.
		 */
		public function get sides() : uint
		{
			return _segmentsW;
		}
		
		public function set sides(value : uint) : void
		{
			segmentsW = value;
		}
		
		/**
		 * The number of subdivisions from the edge to the center of the regular polygon.
		 */
		public function get subdivisions() : uint
		{
			return _segmentsH;
		}
		
		public function set subdivisions(value : uint) : void
		{
			segmentsH = value;
		}
		
		/**
		 * Creates a new RegularPolygon disc object.
		 * @param radius The radius of the regular polygon
		 * @param sides Defines the number of sides of the regular polygon.
		 * @param yUp Defines whether the regular polygon should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function RegularPolygonGeometry(radius : Number = 100, sides : uint = 16, yUp : Boolean = true) {
			super(radius, 0, 0, sides, 1, true, false, false, yUp);
		}
	}
}
