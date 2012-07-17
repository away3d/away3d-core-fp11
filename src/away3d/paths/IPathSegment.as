package away3d.paths
{
	import flash.geom.Vector3D;

	public interface IPathSegment
	{
		/**
		 * Destroys the segment
		 */
		function dispose():void;

		/**
		 * Calculates the position of the curve on this segment.
		 *
		 * @param phase The ratio between the start and end point.
		 * @param target An optional target to store the calculation, to prevent creating a new Vector3D object.
		 * @return
		 */
		function getPointOnSegment(phase:Number, target:Vector3D = null):Vector3D;
	}
	
}