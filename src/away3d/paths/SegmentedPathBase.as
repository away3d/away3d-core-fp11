package away3d.paths
{
	import away3d.errors.AbstractMethodError;

	import flash.geom.Vector3D;

	public class SegmentedPathBase implements IPath
	{
		private var _pointsPerSegment:uint;
		protected var _segments:Vector.<IPathSegment>;

		public function SegmentedPathBase(pointsPerSegment:uint, data:Vector.<Vector3D> = null)
		{
			_pointsPerSegment = pointsPerSegment;
			if(data) pointData = data;
		}

		public function set pointData(data:Vector.<Vector3D>):void
		{
			if (data.length < _pointsPerSegment)
				throw new Error("Path Vector.<Vector3D> must contain at least " + _pointsPerSegment + " Vector3D's");

			if (data.length % _pointsPerSegment != 0)
				throw new Error("Path Vector.<Vector3D> must contain series of " + _pointsPerSegment + " Vector3D's per segment");

			_segments = new Vector.<IPathSegment>();
			for (var i:uint = 0, len:int = data.length; i < len; i += _pointsPerSegment)
				_segments.push(createSegmentFromArrayEntry(data, i));
		}

		// factory method
		protected function createSegmentFromArrayEntry(data : Vector.<Vector3D>, offset : uint) : IPathSegment
		{
			throw new AbstractMethodError();
		}

		/**
		 * The number of segments in the Path
		 */
		public function get numSegments():uint
		{
			return _segments.length;
		}

		/**
		 * returns the Vector.&lt;PathSegment&gt; holding the elements (PathSegment) of the path
		 *
		 * @return	a Vector.&lt;PathSegment&gt;: holding the elements (PathSegment) of the path
		 */
		public function get segments():Vector.<IPathSegment>
		{
			return _segments;
		}

		/**
		 * returns a given PathSegment from the path (PathSegment holds 3 Vector3D's)
		 *
		 * @param	 indice uint. the indice of a given PathSegment
		 * @return	given PathSegment from the path
		 */
		public function getSegmentAt(index : uint) : IPathSegment
		{
			return _segments[index];
		}

		public function addSegment(segment:IPathSegment):void
		{
			_segments.push(segment);
		}

		/**
		 * removes a segment in the path according to id.
		 *
		 * @param	 index	int. The index in path of the to be removed curvesegment
		 * @param	 join 		Boolean. If true previous and next segments coordinates are reconnected
		 */
		public function removeSegment(index:uint, join:Boolean = false):void
		{
			if(_segments.length == 0 || index >= _segments.length - 1)
				return;

			if (join && index > 0 && index < _segments.length - 1)
				stitchSegment(_segments[index-1], _segments[index], _segments[index+1]);

			_segments.splice(index, 1);
		}

		/**
		 * Stitches two segments together based on a segment between them. This is an abstract method used by the template method removeSegment and must be overridden by concrete subclasses!
		 * @param start The section of which the end points must be connected with "end"
		 * @param middle The section that was removed and forms the position hint
		 * @param end The section of which the start points must be connected with "start"
		 */
		protected function stitchSegment(start : IPathSegment, middle : IPathSegment, end : IPathSegment) : void
		{
			throw new AbstractMethodError();
		}

		public function dispose():void
		{
			for (var i : uint, len : uint = _segments.length; i < len; ++i)
				_segments[i].dispose();

			_segments = null;
		}

		public function getPointOnCurve(t : Number, target : Vector3D = null) : Vector3D
		{
			var numSegments : int = _segments.length;
			t *= numSegments;
			var segment : int = int(t);

			if (segment == numSegments) {
				segment = numSegments-1;
				t = 1;
			}
			else
				t -= segment;

			return _segments[segment].getPointOnSegment(t, target);
		}

		public function getPointsOnCurvePerSegment(subdivision:uint):Vector.<Vector.<Vector3D>>
		{
			var points:Vector.<Vector.<Vector3D>> = new Vector.<Vector.<Vector3D>>();

			for (var i:uint = 0, len:uint = _segments.length; i < len; ++i)
				points[i] = getSegmentPoints(_segments[i], subdivision, (i == len - 1));

			return points;
		}

		protected function getSegmentPoints(segment : IPathSegment, n : uint, last : Boolean) : Vector.<Vector3D>
		{
			var points : Vector.<Vector3D> = new Vector.<Vector3D>();

			for (var i : uint = 0; i < n + ((last) ? 1 : 0); ++i)
				points[i] = segment.getPointOnSegment(i / n);

			return points;
		}
	}
}
