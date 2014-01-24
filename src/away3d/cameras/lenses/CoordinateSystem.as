package away3d.cameras.lenses
{
	/**
	 * Provides constant values for camera lens projection options use the the <code>coordinateSystem</code> property
	 * 
	 * @see away3d.cameras.lenses.PerspectiveLens#coordinateSystem
	 */
	public class CoordinateSystem
	{
		/**
		 * Default option, projects to a left-handed coordinate system
		 */
		public static const LEFT_HANDED:uint = 0;
		
		/**
		 * Projects to a right-handed coordinate system
		 */
		public static const RIGHT_HANDED:uint = 1;
	}
}