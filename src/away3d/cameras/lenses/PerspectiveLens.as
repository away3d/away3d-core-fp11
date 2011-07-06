package away3d.cameras.lenses
{
	import away3d.core.math.Matrix3DUtils;

	import flash.geom.Matrix3D;

	/**
	 * The PerspectiveLens object provides a projection matrix that projects 3D geometry with perspective distortion.
	 */
	public class PerspectiveLens extends LensBase
	{
		private var _fieldOfView : Number;
		private var _focalLengthInv : Number;
		private var _yMax : Number;
		private var _xMax : Number;

		/**
		 * Creates a new PerspectiveLens object.
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function PerspectiveLens(fieldOfView : Number = 60)
		{
			super();
			this.fieldOfView = fieldOfView;
		}

		/**
		 * The vertical field of view of the projection.
		 */
		public function get fieldOfView() : Number
		{
			return _fieldOfView;
		}

		public function set fieldOfView(value : Number) : void
		{
			if (value == _fieldOfView) return;
			_fieldOfView = value;
			// tan(fov/2)
			_focalLengthInv = Math.tan(_fieldOfView*Math.PI/360);
			invalidateMatrix();
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateMatrix() : void
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;

			_yMax = _near*_focalLengthInv;
			_xMax = _yMax*_aspectRatio;

			// assume symmetric frustum
			raw[uint(0)] = _near/_xMax;
			raw[uint(5)] = _near/_yMax;
			raw[uint(10)] = _far/(_far-_near);
			raw[uint(11)] = 1;
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
			raw[uint(6)] = raw[uint(7)] = raw[uint(8)] = raw[uint(9)] =
			raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
			raw[uint(14)] = -_near*raw[uint(10)];

			_matrix.copyRawDataFrom(raw);

			var yMaxFar : Number = _far*_focalLengthInv;
			var xMaxFar : Number = yMaxFar*_aspectRatio;

			_frustumCorners[0] = _frustumCorners[9] = -_xMax;
			_frustumCorners[3] = _frustumCorners[6] = _xMax;
			_frustumCorners[1] = _frustumCorners[4] = -_yMax;
			_frustumCorners[7] = _frustumCorners[10] = _yMax;

			_frustumCorners[12] = _frustumCorners[21] = -xMaxFar;
			_frustumCorners[15] = _frustumCorners[18] = xMaxFar;
			_frustumCorners[13] = _frustumCorners[16] = -yMaxFar;
			_frustumCorners[19] = _frustumCorners[22] = yMaxFar;

			_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
			_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
		}


		/**
		 * @inheritDoc
		 */
		override public function getSubFrustumMatrix(ratioLeft : Number, ratioRight : Number, ratioTop : Number, ratioBottom : Number, matrix : Matrix3D, corners : Vector.<Number>) : void
		{
			// trigger rebuild
			var source : Matrix3D = this.matrix;
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var l : Number, r : Number;
			var t : Number, b : Number;

			// figure out new locations
			l = 2*ratioLeft*_xMax -_xMax;
			r = 2*ratioRight*_xMax -_xMax;
			b = 2*ratioTop*_yMax -_yMax;
			t = 2*ratioBottom*_yMax -_yMax;

			raw[uint(0)] = 2.0*_near/(r-l);
			raw[uint(5)] = 2.0*_near/(t-b);
			raw[uint(8)] = (r+l)/(l-r);
			raw[uint(9)] = (t+b)/(b-t);
			raw[uint(10)] = _far/(_far-_near);
			raw[uint(11)] = 1;
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
			raw[uint(6)] = raw[uint(7)] = raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
			raw[uint(14)] = -_near*raw[uint(10)];

			matrix.copyRawDataFrom(raw);

			var yMaxFar : Number = _far*_focalLengthInv;
			var xMaxFar : Number = yMaxFar*_aspectRatio;

			// to do: scale and offset
			corners[0] = corners[9] = l;
			corners[3] = corners[6] = r;
			corners[1] = corners[4] = t;
			corners[7] = corners[10] = b;

			corners[12] = corners[21] = 2*ratioLeft*xMaxFar - xMaxFar;
			corners[15] = corners[18] = 2*ratioRight*xMaxFar - xMaxFar;
			corners[13] = corners[16] = 2*ratioTop*yMaxFar - yMaxFar;
			corners[19] = corners[22] = 2*ratioBottom*yMaxFar - yMaxFar;

			corners[2] = corners[5] = corners[8] = corners[11] = _near;
			corners[14] = corners[17] = corners[20] = corners[23] = _far;
		}
	}
}