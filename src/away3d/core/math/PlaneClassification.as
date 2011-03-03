/**
 * Author: David Lenaerts
 */
package away3d.core.math
{
	public class PlaneClassification
	{
		// "back" is synonymous with "in", but used for planes (back of plane is "inside" a solid volume walled by a plane)
		public static const BACK : int = 0;
		public static const FRONT : int = 1;

		public static const IN : int = 0;
		public static const OUT : int = 1;
		public static const INTERSECT : int = 2;
	}
}
