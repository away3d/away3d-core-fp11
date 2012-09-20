package away3d.cameras.lenses
{
	import away3d.arcane;
	import away3d.core.math.Plane3D;
	import away3d.events.LensEvent;

	import flash.geom.Matrix3D;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class ObliqueNearPlaneLens extends LensBase
	{
		private var _baseLens : LensBase;
		private var _plane : Plane3D;

		public function ObliqueNearPlaneLens(baseLens : LensBase, plane : Plane3D)
		{
			this.baseLens = baseLens;
			this.plane = plane;
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

		public function set baseLens(value : LensBase) : void
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
			_matrix.copyFrom(_baseLens.matrix);

			var cx : Number = _plane.a;
			var cy : Number = _plane.b;
			var cz : Number = _plane.c;
			var cw : Number = -_plane.d+.05;
			var signX : Number = cx >= 0 ? 1 : -1;
			var signY : Number = cy >= 0 ? 1 : -1;
			var p : Vector3D = new Vector3D(signX, signY, 1, 1);
			var inverse : Matrix3D = _matrix.clone();
			inverse.invert();
			var q : Vector3D = inverse.transformVector(p);
			_matrix.copyRowTo(3, p);
			var a : Number = (q.x*p.x + q.y*p.y + q.z*p.z + q.w*p.w)/(cx*q.x + cy*q.y+ cz*q.z + cw*q.w);
			_matrix.copyRowFrom(2, new Vector3D(cx*a, cy*a, cz*a, cw*a));
		}
	}
}
