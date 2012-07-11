package away3d.paths
{
	import flash.geom.Vector3D;

	/**
	 * Defines a cubic path. Each segment of the path has two control points as opposed to <code>CubicPathSegment</code> which being quadratic, has one control point.
	 * @see away3d.animators.CubicPathAnimator
	 * @see away3d.paths.CubicPathSegment
	 */
	public class CubicPath extends SegmentedPathBase implements IPath
	{
		/**
		 * Creates a new CubicPath instance.
		 * @param data See <code>pointData</code>
		 */
		public function CubicPath(data:Vector.<Vector3D> = null)
		{
			super(4, data);
		}

		override protected function createSegmentFromArrayEntry(data : Vector.<Vector3D>, offset : uint) : IPathSegment
		{
			return new CubicPathSegment(data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);
		}

		override protected function stitchSegment(start : IPathSegment, middle : IPathSegment, end : IPathSegment) : void
		{
			var seg : CubicPathSegment = CubicPathSegment(middle);
			var prevSeg : CubicPathSegment = CubicPathSegment(start);
			var nextSeg : CubicPathSegment = CubicPathSegment(end);

			prevSeg.control1.x = (prevSeg.control1.x + seg.control1.x) * 0.5;
			prevSeg.control1.y = (prevSeg.control1.y + seg.control1.y) * 0.5;
			prevSeg.control1.z = (prevSeg.control1.z + seg.control1.z) * 0.5;

			nextSeg.control1.x = (nextSeg.control1.x + seg.control1.x) * 0.5;
			nextSeg.control1.y = (nextSeg.control1.y + seg.control1.y) * 0.5;
			nextSeg.control1.z = (nextSeg.control1.z + seg.control1.z) * 0.5;

			prevSeg.control2.x = (prevSeg.control2.x + seg.control2.x) * 0.5;
			prevSeg.control2.y = (prevSeg.control2.y + seg.control2.y) * 0.5;
			prevSeg.control2.z = (prevSeg.control2.z + seg.control2.z) * 0.5;

			nextSeg.control2.x = (nextSeg.control2.x + seg.control2.x) * 0.5;
			nextSeg.control2.y = (nextSeg.control2.y + seg.control2.y) * 0.5;
			nextSeg.control2.z = (nextSeg.control2.z + seg.control2.z) * 0.5;

			prevSeg.end.x = (seg.start.x + seg.end.x) * 0.5;
			prevSeg.end.y = (seg.start.y + seg.end.y) * 0.5;
			prevSeg.end.z = (seg.start.z + seg.end.z) * 0.5;

			nextSeg.start.x = prevSeg.end.x;
			nextSeg.start.y = prevSeg.end.y;
			nextSeg.start.z = prevSeg.end.z;
		}
	}
}