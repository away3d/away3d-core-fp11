package away3d.cameras.lenses {
	import away3d.arcane;

	use namespace arcane;

	/**
	 * FreeMatrixLens provides a projection lens that exposes a full projection matrix, rather than provide one through
	 * more user-friendly settings. Whenever the matrix is updated, it needs to be reset in order to trigger an update.
	 */
	public class FreeMatrixLens extends LensBase
	{
		/**
		 * Creates a new FreeMatrixLens object.
		 */
		public function FreeMatrixLens()
		{
			super();
			_matrix.copyFrom(new PerspectiveLens().matrix);
		}

		override public function set near(value : Number) : void
		{
			_near = value;
		}

		override public function set far(value : Number) : void
		{
			_far = value;
		}

		arcane override function set aspectRatio(value : Number) : void
		{
			_aspectRatio = value;
		}

		override public function clone() : LensBase
		{
			var clone : FreeMatrixLens = new FreeMatrixLens();
			clone._matrix.copyFrom(_matrix);
			clone._near = _near;
			clone._far = _far;
			clone._aspectRatio = _aspectRatio;
			clone.invalidateMatrix();
			return clone;
		}

		override protected function updateMatrix() : void
		{
			_matrixInvalid = false;
		}
	}
}