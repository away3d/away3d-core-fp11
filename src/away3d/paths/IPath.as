package away3d.paths
{
	import flash.geom.Vector3D;

	public interface IPath
	{
		// TODO: pointOnPath(phase : Number)	--> samplePoint
		// TODO: move pointData to (some) implementations

		// TODO: getSegmentAt vs get segments
		// TODO: what is worldAxis?

		/**
		 * A list of <code>Vector3D</code> objects, which must be in the following order:
		 * a1, b1, c1, d1, a2, b2, c2, d2 ... where a = start point, b = first control point, c = second control point and d = end control point.
		 * To avoid a broken path d1 and a2 must be equal.
		 */
		function set pointData(data:Vector.<Vector3D>):void;

		/**
		 * The number of <code>CubicPathSegment</code> instances in the path.
		 */
		function get numSegments():uint;


		/**
		 * The <code>IPathSegment</code> instances which make up this path.
		 */
		function get segments():Vector.<IPathSegment>;


		/**
		 * The world axis.
		 */
		function get worldAxis():Vector3D;

		function set worldAxis(value:Vector3D):void;


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
		function getPointsOnCurve(numSegments : uint) : Vector.<Vector.<Vector3D>>;
	}
}