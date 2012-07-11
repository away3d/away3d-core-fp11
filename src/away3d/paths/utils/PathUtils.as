package away3d.paths.utils
{
	import away3d.core.math.MathConsts;

	import flash.geom.Vector3D;

	/**
	 * Geometry handlers for classes using Path objects
	 */
	public class PathUtils
	{

		public static function step(startVal : Vector3D, endVal : Vector3D, subdivision : int) : Vector.<Vector3D>
		{
			var vTween : Vector.<Vector3D> = new Vector.<Vector3D>();

			var stepx : Number = (endVal.x - startVal.x) / subdivision;
			var stepy : Number = (endVal.y - startVal.y) / subdivision;
			var stepz : Number = (endVal.z - startVal.z) / subdivision;

			var step : int = 1;
			var scalestep : Vector3D;

			while (step < subdivision) {
				scalestep = new Vector3D();
				scalestep.x = startVal.x + (stepx * step);
				scalestep.y = startVal.y + (stepy * step);
				scalestep.z = startVal.z + (stepz * step);
				vTween.push(scalestep);

				step++;
			}

			vTween.push(endVal);

			return vTween;
		}

		public static function rotatePoint(aPoint : Vector3D, rotation : Vector3D) : Vector3D
		{
			if (rotation.x != 0 || rotation.y != 0 || rotation.z != 0) {

				var x1 : Number;
				var y1 : Number;

				var rad : Number = MathConsts.DEGREES_TO_RADIANS;
				var rotx : Number = rotation.x * rad;
				var roty : Number = rotation.y * rad;
				var rotz : Number = rotation.z * rad;

				var sinx : Number = Math.sin(rotx);
				var cosx : Number = Math.cos(rotx);
				var siny : Number = Math.sin(roty);
				var cosy : Number = Math.cos(roty);
				var sinz : Number = Math.sin(rotz);
				var cosz : Number = Math.cos(rotz);

				var x : Number = aPoint.x;
				var y : Number = aPoint.y;
				var z : Number = aPoint.z;

				y1 = y;
				y = y1 * cosx + z * -sinx;
				z = y1 * sinx + z * cosx;

				x1 = x;
				x = x1 * cosy + z * siny;
				z = x1 * -siny + z * cosy;

				x1 = x;
				x = x1 * cosz + y * -sinz;
				y = x1 * sinz + y * cosz;

				aPoint.x = x;
				aPoint.y = y;
				aPoint.z = z;
			}

			return aPoint;
		}
	}
}