package away3d.primitives {
	import away3d.materials.MaterialBase;

	/**
	 * A UV RegularPolygon primitive mesh.
	 */
	public class RegularPolygon extends Cylinder {

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
		 * @param material The material with which to render the regular polygon.
		 * @param radius The radius of the regular polygon
		 * @param sides Defines the number of sides of the regular polygon. Defaults to 16.
		 * @param subdivisions Defines the number of subdivisions of the regular polygon from the edge to the center. Defaults to 1.
		 * @param yUp Defines whether the regular polygon should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function RegularPolygon(material : MaterialBase = null, radius : Number = 100, sides : uint = 16, subdivisions : uint = 1, yUp : Boolean = true) {
			super(material, 0.0000001, radius, 0, sides, subdivisions, false, false, yUp);
		}
	}
}
