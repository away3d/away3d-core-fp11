package away3d.cameras.lenses
{
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * An abstract base class for all lens classes. Lens objects provides a projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
	 */
	public class LensBase
	{
		protected var _matrix : Matrix3D;

		protected var _near : Number = 20;
		protected var _far : Number = 3000;
		protected var _aspectRatio : Number = 1;

		private var _matrixInvalid : Boolean = true;
		protected var _frustumCorners : Vector.<Number> = new Vector.<Number>(8*3, true);

		// todo: consider signals instead, single callback is dirty
		arcane var onInvalidateMatrix : Function;

		private var _unprojection : Matrix3D = new Matrix3D();
		private var _unprojectionInvalid : Boolean = true;

		/**
		 * Creates a new LensBase object.
		 */
		public function LensBase()
		{
			_matrix = new Matrix3D();
		}

		/**
		 * Retrieves the corner points of the lens frustum.
		 */
		public function get frustumCorners() : Vector.<Number>
		{
			return _frustumCorners;
		}

		/**
		 * The projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
		 */
		public function get matrix() : Matrix3D
		{
			if (_matrixInvalid) {
				updateMatrix();
				_matrixInvalid = false;
			}
			return _matrix;
		}

		/**
		 * The distance to the near plane of the frustum. Anything behind near plane will not be rendered.
		 */
		public function get near() : Number
		{
			return _near;
		}

		public function set near(value : Number) : void
		{
			if (value == _near) return;
			_near = value;
			invalidateMatrix();
		}

		/**
		 * The distance to the far plane of the frustum. Anything beyond the far plane will not be rendered.
		 */
		public function get far() : Number
		{
			return _far;
		}

		public function set far(value : Number) : void
		{
			if (value == _far) return;
			_far = value;
			invalidateMatrix();
		}

		public function unproject(mX:Number, mY:Number, mZ : Number):Vector3D
		{
			if (_unprojectionInvalid) {
				_unprojection.copyFrom(matrix);
				_unprojection.invert();
				_unprojectionInvalid = false;
			}

			var v : Vector3D = new Vector3D(mX, -mY, mZ, 1.0);

			v = _unprojection.transformVector(v);

			var inv : Number = 1/v.w;

            v.x *= inv;
            v.y *= inv;
            v.z *= inv;
			v.w = 1.0;

			return v;
		}

		/**
		 * The aspect ratio (width/height) of the view. Set by the renderer.
		 * @private
		 */
		arcane function get aspectRatio() : Number
		{
			return _aspectRatio;
		}

		arcane function set aspectRatio(value : Number) : void
		{
			if (_aspectRatio == value) return;
			_aspectRatio = value;
			invalidateMatrix();
		}

		/**
		 * Invalidates the projection matrix, which will cause it to be updated on the next request.
		 */
		protected function invalidateMatrix() : void
		{
			_matrixInvalid = true;
			_unprojectionInvalid = true;
			// notify the camera that the lens matrix is changing. this will mark the 
			// viewProjectionMatrix in the camera as invalid, and force the matrix to
			// be re-queried from the lens, and therefore rebuilt.
			if (onInvalidateMatrix != null) onInvalidateMatrix();
		}

		/**
		 * Updates the matrix
		 */
		protected function updateMatrix() : void
		{
			throw new AbstractMethodError();
		}
	}
}