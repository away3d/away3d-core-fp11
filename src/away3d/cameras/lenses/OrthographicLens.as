package away3d.cameras.lenses
{
	import away3d.core.math.Matrix3DUtils;

	import flash.geom.Matrix3D;

	/**
	 * The PerspectiveLens object provides a projection matrix that projects 3D geometry isometrically. This entails
	 * there is no perspective distortion, and lines that are parallel in the scene will remain parallel on the screen.
	 */
	public class OrthographicLens extends LensBase
	{
		private var _projectionHeight : Number;
		private var _xMax : Number;
		private var _yMax : Number;

		/**
		 * Creates a new OrthogonalLens object.
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function OrthographicLens(projectionHeight : Number = 500)
		{
			super();
			_projectionHeight = projectionHeight;
		}

		/**
		 * The vertical field of view of the projection.
		 */
		public function get projectionHeight() : Number
		{
			return _projectionHeight;
		}

		public function set projectionHeight(value : Number) : void
		{
			if (value == _projectionHeight) return;
			_projectionHeight = value;
			invalidateMatrix();
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateMatrix() : void
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			_yMax = _projectionHeight*.5;
			_xMax = _yMax*_aspectRatio;

			// assume symmetric frustum
			raw[uint(0)] = 2/(_projectionHeight*_aspectRatio);
			raw[uint(5)] = 2/_projectionHeight;
			raw[uint(10)] = 1/(_far-_near);
			raw[uint(14)] = _near/(_near-_far);
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
			raw[uint(6)] = raw[uint(7)] = raw[uint(8)] = raw[uint(9)] =
			raw[uint(11)] = raw[uint(12)] = raw[uint(13)] = 0;
			raw[uint(15)] = 1;

			_frustumCorners[0] = _frustumCorners[9] = _frustumCorners[12] = _frustumCorners[21] = -_xMax;
			_frustumCorners[3] = _frustumCorners[6] = _frustumCorners[15] = _frustumCorners[18] = _xMax;
			_frustumCorners[1] = _frustumCorners[4] = _frustumCorners[13] = _frustumCorners[16] = -_yMax;
			_frustumCorners[7] = _frustumCorners[10] = _frustumCorners[19] = _frustumCorners[22] = _yMax;
			_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
			_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;

			_matrix.copyRawDataFrom(raw);
		}

		/**
		 * @inheritDoc
		 */
		override public function getSubFrustumMatrix(ratioLeft : Number, ratioRight : Number, ratioTop : Number, ratioBottom : Number, matrix : Matrix3D, corners : Vector.<Number>) : void
		{
			var source : Matrix3D = this.matrix;
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var l : Number, r : Number;
			var t : Number, b : Number;

			// figure out new locations
			l = 2*ratioLeft*_xMax -_xMax;
			r = 2*ratioRight*_xMax -_xMax;
			b = 2*ratioTop*_yMax -_yMax;
			t = 2*ratioBottom*_yMax -_yMax;

			raw[0] = 2/(r-l);
			raw[5] = 2/(t-b);
			raw[10] = 1/(_far-_near);
			raw[12] = (r + l)/(l-r);
			raw[13] = (t + b)/(b-t);
			raw[14] = _near/(_near-_far);
			raw[15] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] =
			raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;
			matrix.copyRawDataFrom(raw);

			corners[0] = corners[9] = corners[12] = corners[21] = l;
			corners[3] = corners[6] = corners[15] = corners[18] = r;
			corners[1] = corners[4] = corners[13] = corners[16] = t;
			corners[7] = corners[10] = corners[19] = corners[22] = b;
			corners[2] = corners[5] = corners[8] = corners[11] = _near;
			corners[14] = corners[17] = corners[20] = corners[23] = _far;
		}
	}
}