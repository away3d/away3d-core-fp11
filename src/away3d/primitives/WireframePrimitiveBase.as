package away3d.primitives
{
	import away3d.bounds.BoundingVolumeBase;
	import away3d.cameras.Camera3D;
	import away3d.entities.SegmentSet;
	import away3d.errors.AbstractMethodError;
	import away3d.primitives.data.Segment;

	import flash.geom.Vector3D;

	public class WireframePrimitiveBase extends SegmentSet
	{
		private var _geomDirty : Boolean = true;
		private var _color : uint;
		private var _thickness : Number;

		public function WireframePrimitiveBase(color : uint = 0xffffff, thickness : Number = 1)
		{
			if(thickness <= 0) thickness = 1;
			_color = color;
			_thickness = thickness;
		}

		public function get color() : uint
		{
			return _color;
		}

		public function set color(value : uint) : void
		{
			var numSegments : uint = _segments.length;

			_color = value;

			for (var i : int = 0; i < numSegments; ++i)
				_segments[i].startColor = _segments[i].endColor = value;
		}

		public function get thickness() : Number
		{
			return _thickness;
		}

		public function set thickness(value : Number) : void
		{
			var numSegments : uint = _segments.length;

			_thickness = value;

			for (var i : int = 0; i < numSegments; ++i)
				_segments[i].thickness = _segments[i].thickness = value;
		}

		override protected function clearSegments() : void
		{
			super.clearSegments();
		}

		override public function pushModelViewProjection(camera : Camera3D) : void
		{
			if (_geomDirty) updateGeometry();
			super.pushModelViewProjection(camera);
		}

		override public function get bounds() : BoundingVolumeBase
		{
			if (_geomDirty) updateGeometry();
			return super.bounds;
		}

		protected function buildGeometry() : void
		{
			throw new AbstractMethodError();
		}

		protected function invalidateGeometry() : void
		{
			_geomDirty = true;
			invalidateBounds();
		}

		private function updateGeometry() : void
		{
			buildGeometry();
			_geomDirty = false;
		}

		protected function updateOrAddSegment(index : uint, v0 : Vector3D, v1 : Vector3D) : void
		{
			var segment : Segment;
			var s : Vector3D, e : Vector3D;

			if (_segments.length > index) {
				segment = _segments[index];
				s = segment.start;
				e = segment.end;
				s.x = v0.x; s.y = v0.y; s.z = v0.z;
				e.x = v1.x; e.y = v1.y; e.z = v1.z;
				_segments[index].updateSegment(s, e, null, _color, _color, _thickness);
			}
			else {
				addSegment( new LineSegment(v0.clone(), v1.clone(), _color, _color, _thickness));
			}
		}
	}
}
