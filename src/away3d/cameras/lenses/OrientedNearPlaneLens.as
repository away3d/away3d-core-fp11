package away3d.cameras.lenses
{
	import away3d.arcane;
	import away3d.core.math.Plane3D;
	import away3d.events.LensEvent;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class OrientedNearPlaneLens extends LensBase
	{
		private var _baseLens : LensBase;
		private var _plane : Plane3D;

		public function OrientedNearPlaneLens(baseLens : LensBase, plane : Plane3D)
		{
			this.baseLens = baseLens;
		}


		override public function get frustumCorners() : Vector.<Number>
		{
			return _baseLens.frustumCorners;
		}

		override public function get near() : Number
		{
			return _baseLens.near;
		}

		override public function set near(value : Number) : void
		{
			_baseLens.near = value;
		}

		override public function get far() : Number
		{
			return _baseLens.far;
		}

		override public function set far(value : Number) : void
		{
			_baseLens.far = value;
		}

		override arcane function get aspectRatio() : Number
		{
			return _baseLens.aspectRatio;
		}

		override arcane function set aspectRatio(value : Number) : void
		{
			_baseLens.aspectRatio = value;
		}

		public function get plane() : Plane3D
		{
			return _plane;
		}

		public function set plane(value : Plane3D) : void
		{
			_plane = value;
			invalidateMatrix();
		}

		public function set baseLens(value : LensBase)
		{
			if (_baseLens)
				_baseLens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

			_baseLens = value;

			if (_baseLens)
				_baseLens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

			invalidateMatrix();
		}

		private function onLensMatrixChanged(event : LensEvent) : void
		{
			invalidateMatrix();
		}

		override protected function updateMatrix() : void
		{
			_matrix.identity();
			_matrix.copyFrom(_baseLens.matrix);
			var vec : Vector3D = new Vector3D();
			// z component must contain the distance to near plane, with far maximum
			vec.x = _plane.a;
			vec.y = _plane.b;
			vec.z = _plane.c;
			vec.w = -_plane.d;

			// problem is, z is placed on w, doesn't match z range after projection

			_matrix.copyRowFrom(2, vec);
		}
	}
}
