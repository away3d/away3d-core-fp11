package away3d.paths
{
	import flash.geom.Vector3D;

	public interface IPath
	{
		// TODO: pointOnPath(phase : Number)	--> samplePoint
		// TODO: getSegmentAt vs get segments


		/**
		 * The number of <code>CubicPathSegment</code> instances in the path.
		 */
		function get numSegments():uint;


		/**
		 * The <code>IPathSegment</code> instances which make up this path.
		 */
		function get segments():Vector.<IPathSegment>;

		/**
		 * Returns the <code>CubicPathSegment</code> at the specified index
		 * @param index The index of the segment
		 * @return A <code>CubicPathSegment</code> instance
		 */
		function getSegmentAt(index:uint):IPathSegment;


		/**
		 * Adds a <code>CubicPathSegment</code> to the end of the path
		 * @param segment
		 */
		function addSegment(segment:IPathSegment):void;


		/**
		 * Removes a segment from the path
		 * @param index The index of the <code>CubicPathSegment</code> to be removed
		 * @param join Determines if the segments on either side of the removed segment should be adjusted so there is no gap.
		 */
		function removeSegment(index:uint, join:Boolean = false):void;


		/**
		 * Disposes the path and all the segments
		 */
		function dispose():void;

		/**
		 * Discretizes the segment into a set of sample points.
		 *
		 * @param numSegments The amount of segments to split the sampling in. The amount of points returned is numSegments + 1
		 *
		 * TODO: is this really even necessary? We should be able to simply call samplePoint(t) instead
		 */
		function getPointsOnCurvePerSegment(numSegments : uint) : Vector.<Vector.<Vector3D>>;
	}
}