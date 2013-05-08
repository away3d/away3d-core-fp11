package away3d.cameras.lenses {
	import away3d.core.math.Matrix3DUtils;

	import flash.geom.Vector3D;

	/**
	 * The PerspectiveLens object provides a projection matrix that projects 3D geometry with perspective distortion.
	 */
	public class PerspectiveLens extends LensBase
	{
		private var _fieldOfView : Number;
		private var _focalLength : Number;
		private var _focalLengthInv : Number;
		private var _yMax : Number;
		private var _xMax : Number;


		/**
		 * Creates a new PerspectiveLens object.
		 * 
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function PerspectiveLens(fieldOfView : Number = 60)
		{
			super();
			this.fieldOfView = fieldOfView;
		}

		/**
		 * The vertical field of view of the projection in degrees.
		 */
		public function get fieldOfView() : Number
		{
			return _fieldOfView;
		}

		public function set fieldOfView(value : Number) : void
		{
			if (value == _fieldOfView)
				return;
			
			_fieldOfView = value;
			
			_focalLengthInv = Math.tan(_fieldOfView*Math.PI/360);
			_focalLength = 1/_focalLengthInv;
			
			invalidateMatrix();
		}
		
		/**
		 * The focal length of the projection in units of viewport height.
		 */
		public function get focalLength() : Number
		{
			return _focalLength;
		}
		
		public function set focalLength(value : Number) : void
		{
			if (value == _focalLength)
				return;
			
			_focalLength = value;
			
			_focalLengthInv = 1/_focalLength;
			_fieldOfView = Math.atan(_focalLengthInv)*360/Math.PI;
			
			invalidateMatrix();
		}

		/**
		 * Calculates the scene position relative to the camera of the given normalized coordinates in screen space.
		 * 
		 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
		 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
		 * @param sZ The z coordinate in screen space, representing the distance into the screen.
		 * @return The scene position relative to the camera of the given screen coordinates.
		 */
		override public function unproject(nX:Number, nY:Number, sZ : Number):Vector3D
		{
			var v : Vector3D = new Vector3D(nX, -nY, sZ, 1.0);
			
            v.x *= sZ;
            v.y *= sZ;
			
			v = unprojectionMatrix.transformVector(v);
			
			//z is unaffected by transform
            v.z = sZ;
			
			return v;
		}

		override public function clone() : LensBase
		{
			var clone : PerspectiveLens = new PerspectiveLens(_fieldOfView);
			clone._near = _near;
			clone._far = _far;
			clone._aspectRatio = _aspectRatio;
			return clone;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateMatrix() : void
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			
			_yMax = _near*_focalLengthInv;
			_xMax = _yMax*_aspectRatio;

			var left:Number, right:Number, top:Number, bottom:Number;

			if (_scissorRect.x == 0 && _scissorRect.y == 0 && _scissorRect.width == _viewPort.width && _scissorRect.height == _viewPort.height) {
				// assume unscissored frustum
				left = -_xMax;
				right = _xMax;
				top = -_yMax;
				bottom = _yMax;
				// assume unscissored frustum
				raw[uint(0)] = _near/_xMax;
				raw[uint(5)] = _near/_yMax;
				raw[uint(10)] = _far/(_far-_near);
				raw[uint(11)] = 1;
				raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
				raw[uint(6)] = raw[uint(7)] = raw[uint(8)] = raw[uint(9)] =
				raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
				raw[uint(14)] = -_near*raw[uint(10)];
			} else {
				// assume scissored frustum
				var xWidth:Number = _xMax * (_viewPort.width / _scissorRect.width);
				var yHgt:Number = _yMax * (_viewPort.height / _scissorRect.height);
				var center:Number = _xMax * (_scissorRect.x * 2 - _viewPort.width) / _scissorRect.width + _xMax;
				var middle:Number = -_yMax * (_scissorRect.y * 2 - _viewPort.height) / _scissorRect.height - _yMax;

				left = center - xWidth;
				right = center + xWidth;
				top = middle - yHgt;
				bottom = middle + yHgt;
				
				raw[uint(0)] = 2 * _near / (right - left);
				raw[uint(5)] = 2 * _near / (bottom - top);
				raw[uint(8)] = (right + left) / (right - left);
				raw[uint(9)] = (bottom + top) / (bottom - top);
				raw[uint(10)] = (_far + _near) / (_far - _near);
				raw[uint(11)] = 1;
				raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
				raw[uint(6)] = raw[uint(7)] = raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
				raw[uint(14)] = -2 * _far * _near / (_far - _near);
			}
			

			_matrix.copyRawDataFrom(raw);

			var yMaxFar : Number = _far*_focalLengthInv;
			var xMaxFar : Number = yMaxFar*_aspectRatio;

			_frustumCorners[0] = _frustumCorners[9] = left;
			_frustumCorners[3] = _frustumCorners[6] = right;
			_frustumCorners[1] = _frustumCorners[4] = top;
			_frustumCorners[7] = _frustumCorners[10] = bottom;

			_frustumCorners[12] = _frustumCorners[21] = -xMaxFar;
			_frustumCorners[15] = _frustumCorners[18] = xMaxFar;
			_frustumCorners[13] = _frustumCorners[16] = -yMaxFar;
			_frustumCorners[19] = _frustumCorners[22] = yMaxFar;

			_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
			_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;

			_matrixInvalid = false;
		}
	}
}
