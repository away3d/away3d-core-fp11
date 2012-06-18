package away3d.extrusions.utils
{
	import flash.geom.Vector3D;

	/**
	 * Defines a single segment of a cubic path
	 * @see away3d.extrusions.utils.CubicPath
	 */
	public class CubicPathSegment implements IPathSegment
	{
		/**
		 * The first anchor point.
		 */
		public var start:Vector3D;

		/**
		 * The first control point.
		 */
		public var control1:Vector3D;

		/**
		 * The second control point.
		 */
		public var control2:Vector3D;

		/**
		 * The last anchor point.
		 */
		public var end:Vector3D;

		/**
		 *
		 * @param start The first anchor point.
		 * @param control1 The first control point.
		 * @param control2 The second control point.
		 * @param end The last anchor point.
		 */
		public function CubicPathSegment(start:Vector3D, control1:Vector3D, control2:Vector3D, end:Vector3D)
		{
			this.start = start;
			this.control1 = control1;
			this.control2 = control2;
			this.end = end;
		}


		public function toString():String
		{
			return start + ", " + control1 + ", " + control2 + ", " + end;
		}


		public function dispose():void
		{
			start = control1 = control2 = end = null;
		}

	}
}