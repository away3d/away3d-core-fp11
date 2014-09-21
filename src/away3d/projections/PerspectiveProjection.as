package away3d.projections
{
	import away3d.core.geom.Matrix3DUtils;

	import flash.geom.Vector3D;

	/**
	 * The PerspectiveProjection object provides a projection matrix that projects 3D geometry with perspective distortion.
	 */
	public class PerspectiveProjection extends ProjectionBase
	{
		private var _fieldOfView:Number = 60;
		private var _focalLength:Number = 1000;
		private var _hFieldOfView:Number = 60;
		private var _hFocalLength:Number = 1000;
		private var _preserveAspectRatio:Boolean = true;
		private var _preserveFocalLength:Boolean = false;

		/**
		 * Creates a new PerspectiveProjection object.
		 *
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function PerspectiveProjection(fieldOfView:Number = 60, coordinateSystem:uint = CoordinateSystem.LEFT_HANDED)
		{
			super(coordinateSystem);
			this.fieldOfView = fieldOfView;
		}
		
		/**
		 * The vertical field of view of the projection in degrees.
		 */
		public function get fieldOfView():Number
		{
			return _fieldOfView;
		}
		
		public function set fieldOfView(value:Number):void
		{
			if (value == _fieldOfView)
				return;
			
			_fieldOfView = value;

			invalidateMatrix();
		}
		
		/**
		 * The focal length of the projection in units of viewport height.
		 */
		public function get focalLength():Number
		{
			return _focalLength;
		}
		
		public function set focalLength(value:Number):void
		{
			if (value == _focalLength)
				return;
			
			_focalLength = value;
			
			invalidateMatrix();
		}
		
		/**
		 * Calculates the scene position relative to the camera of the given normalized coordinates in screen space.
		 *
		 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
		 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
		 * @param sZ The z coordinate in screen space, representing the distance into the screen.
		 * @param v The destination Vector3D object
		 * @return The scene position relative to the camera of the given screen coordinates.
		 */
		override public function unproject(nX:Number, nY:Number, sZ:Number, v:Vector3D = null):Vector3D
		{
			if(!v) v = new Vector3D();
			v.x = nX;
			v.y = -nY;
			v.z = sZ;
			v.w = 1;

			v.x *= sZ;
			v.y *= sZ;
			
			Matrix3DUtils.transformVector(unprojectionMatrix, v, v);
			
			//z is unaffected by transform
			v.z = sZ;
			
			return v;
		}
		
		override public function clone():ProjectionBase
		{
			var clone:PerspectiveProjection = new PerspectiveProjection(_fieldOfView, _coordinateSystem);
			clone.near = _near;
			clone.far = _far;
			clone.aspectRatio = _aspectRatio;
			clone.hFieldOfView = _hFieldOfView;
			clone.preserveAspectRatio = _preserveAspectRatio;
			clone.preserveFocalLength = _preserveFocalLength;
			return clone;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateMatrix():void
		{
			var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;

			if (_preserveFocalLength) {
				if (_preserveAspectRatio)
					_hFocalLength = _focalLength;

				_fieldOfView = Math.atan(0.5 * _scissorRect.height / _focalLength) * 360 / Math.PI;
				_hFieldOfView = Math.atan(0.5 * _scissorRect.width / _hFocalLength) * 360 / Math.PI;
			} else {
				_focalLength = 0.5 * _scissorRect.height / Math.tan(_fieldOfView * Math.PI / 360);

				if (_preserveAspectRatio)
					_hFocalLength = _focalLength;
				else
					_hFocalLength = 0.5 * _scissorRect.width / Math.tan(_hFieldOfView * Math.PI / 360);
			}

			var tanMinX:Number = -_originX/_hFocalLength;
			var tanMaxX:Number = (1 - _originX)/_hFocalLength;
			var tanMinY:Number = -_originY/_focalLength;
			var tanMaxY:Number = (1 - _originY)/_focalLength;

			var left:Number;
			var right:Number;
			var top:Number;
			var bottom:Number;

			// assume scissored frustum
			var center:Number = -((tanMinX - tanMaxX)*_scissorRect.x + tanMinX*_scissorRect.width);
			var middle:Number = ((tanMinY - tanMaxY)*_scissorRect.y + tanMinY*_scissorRect.height);

			left = center - (tanMaxX - tanMinX)*_viewPort.width;
			right = center;
			top = middle;
			bottom = middle + (tanMaxY - tanMinY)*_viewPort.height;

			raw[0] = 2/(right - left);
			raw[5] = 2/(bottom - top);
			raw[8] = (right + left)/(right - left);
			raw[9] = (bottom + top)/(bottom - top);
			raw[10] = (_far + _near)/(_far - _near);
			raw[11] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[12] = raw[13] = raw[15] = 0;
			raw[14] = -2*_far*_near/(_far - _near);

			if (_coordinateSystem == CoordinateSystem.RIGHT_HANDED)
				raw[5] = -raw[5];

			_matrix.copyRawDataFrom(raw);

			_frustumCorners[0] = _frustumCorners[9] = _near*left;
			_frustumCorners[3] = _frustumCorners[6] = _near*right;
			_frustumCorners[1] = _frustumCorners[4] = _near*top;
			_frustumCorners[7] = _frustumCorners[10] = _near*bottom;

			_frustumCorners[12] = _frustumCorners[21] = _far*left;
			_frustumCorners[15] = _frustumCorners[18] = _far*right;
			_frustumCorners[13] = _frustumCorners[16] = _far*top;
			_frustumCorners[19] = _frustumCorners[22] = _far*bottom;

			_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
			_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;

			_matrixInvalid = false;
		}

		public function get preserveAspectRatio():Boolean {
			return _preserveAspectRatio;
		}

		public function set preserveAspectRatio(value:Boolean):void {
			if(_preserveAspectRatio == value) return;
			_preserveAspectRatio = value;
			if(_preserveAspectRatio) invalidateMatrix();
		}

		public function get preserveFocalLength():Boolean {
			return _preserveFocalLength;
		}

		public function set preserveFocalLength(value:Boolean):void {
			if(_preserveFocalLength == value) return;
			_preserveFocalLength = value;
			if(_preserveFocalLength) invalidateMatrix();
		}

		public function get hFieldOfView():Number {
			return _hFieldOfView;
		}

		public function set hFieldOfView(value:Number):void {
			if(_hFieldOfView == value) return;
			_hFieldOfView = value;
			_hFocalLength = 1/Math.tan(_hFieldOfView*Math.PI/360);
			invalidateMatrix();
		}

		public function get hFocalLength():Number {
			return _hFocalLength;
		}

		public function set hFocalLength(value:Number):void {
			if (_hFocalLength == value) return;
			_hFocalLength = value;
			invalidateMatrix();
		}
	}
}
