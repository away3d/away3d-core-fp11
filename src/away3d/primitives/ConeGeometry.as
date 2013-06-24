package away3d.primitives
{
	
	/**
	 * A UV Cone primitive mesh.
	 */
	public class ConeGeometry extends CylinderGeometry
	{
		
		/**
		 * The radius of the bottom end of the cone.
		 */
		public function get radius():Number
		{
			return _bottomRadius;
		}
		
		public function set radius(value:Number):void
		{
			_bottomRadius = value;
			invalidateGeometry();
		}
		
		/**
		 * Creates a new Cone object.
		 * @param radius The radius of the bottom end of the cone
		 * @param height The height of the cone
		 * @param segmentsW Defines the number of horizontal segments that make up the cone. Defaults to 16.
		 * @param segmentsH Defines the number of vertical segments that make up the cone. Defaults to 1.
		 * @param yUp Defines whether the cone poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function ConeGeometry(radius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 1, closed:Boolean = true, yUp:Boolean = true)
		{
			super(0, radius, height, segmentsW, segmentsH, false, closed, true, yUp);
		}
	}
}
