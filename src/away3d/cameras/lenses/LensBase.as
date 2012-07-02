package away3d.cameras.lenses
{
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.events.LensEvent;

	import flash.events.EventDispatcher;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * An abstract base class for all lens classes. Lens objects provides a projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
	 */
	public class LensBase extends EventDispatcher
	{
		protected var _matrix : Matrix3D;

		protected var _near : Number = 20;
		protected var _far : Number = 3000;
		protected var _aspectRatio : Number = 1;

		protected var _matrixInvalid : Boolean = true;
		protected var _frustumCorners : Vector.<Number> = new Vector.<Number>(8*3, true);

		private var _unprojection : Matrix3D;
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

		public function set frustumCorners(frustumCorners : Vector.<Number>) : void
		{
			_frustumCorners = frustumCorners;
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
		
				
		public function set matrix(value : Matrix3D) : void
		{
			_matrix = value;
			invalidateMatrix();
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

		public function project(point3d : Vector3D) : Vector3D
		{
			var v : Vector3D = matrix.transformVector(point3d);
			v.x = v.x/v.w;
			v.y = -v.y/v.w;
			return v;
		}

		public function get unprojectionMatrix() : Matrix3D
		{
			if (_unprojectionInvalid) {
				_unprojection ||= new Matrix3D();
				_unprojection.copyFrom(matrix);
				_unprojection.invert();
				_unprojectionInvalid = false;
			}

			return _unprojection;
		}

		/**
		 * Calculates the position of the given normalized coordinates relative to the camera.
		 * @param mX The x coordinate relative to the View3D. -1 corresponds to the utter left side of the viewport, 1 to the right.
		 * @param mY The y coordinate relative to the View3D. -1 corresponds to the top side of the viewport, 1 to the bottom.
		 * @param mZ The distance from the projection plane.
		 * @return The scene position of the given screen coordinates.
		 */
		public function unproject(mX:Number, mY:Number, mZ : Number):Vector3D
		{
			var v : Vector3D = new Vector3D(mX, -mY, mZ, 1.0);

			v = unprojectionMatrix.transformVector(v);

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
			dispatchEvent(new LensEvent(LensEvent.MATRIX_CHANGED, this));
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