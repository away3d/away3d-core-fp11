package away3d.primitives {
	import away3d.primitives.Cylinder;
	import away3d.materials.MaterialBase;

	/**
	 * @author Greg
	 */
	public class RegularPolygon extends Cylinder {
		public function RegularPolygon(material : MaterialBase = null, radius : Number = 100, sides : uint = 16, subdivisions : uint = 1, yUp : Boolean = true) {
			super(material, 0.0000001, radius, 0, sides, subdivisions, false, false, yUp);
		}
	}
}
