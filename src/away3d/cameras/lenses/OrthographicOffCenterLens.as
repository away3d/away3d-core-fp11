package away3d.cameras.lenses
{
	import away3d.core.math.Matrix3DUtils;
	
	import flash.geom.Vector3D;
	
	/**
	 * The PerspectiveLens object provides a projection matrix that projects 3D geometry isometrically. This entails
	 * there is no perspective distortion, and lines that are parallel in the scene will remain parallel on the screen.
	 */
	public class OrthographicOffCenterLens extends LensBase
	{
		private var _minX:Number;
		private var _maxX:Number;
		private var _minY:Number;
		private var _maxY:Number;
		
		/**
		 * Creates a new OrthogonalLens object.
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function OrthographicOffCenterLens(minX:Number, maxX:Number, minY:Number, maxY:Number)
		{
			super();
			_minX = minX;
			_maxX = maxX;
			_minY = minY;
			_maxY = maxY;
		}
		
		public function get minX():Number
		{
			return _minX;
		}
		
		public function set minX(value:Number):void
		{
			_minX = value;
			invalidateMatrix();
		}
		
		public function get maxX():Number
		{
			return _maxX;
		}
		
		public function set maxX(value:Number):void
		{
			_maxX = value;
			invalidateMatrix();
		}
		
		public function get minY():Number
		{
			return _minY;
		}
		
		public function set minY(value:Number):void
		{
			_minY = value;
			invalidateMatrix();
		}
		
		public function get maxY():Number
		{
			return _maxY;
		}
		
		public function set maxY(value:Number):void
		{
			_maxY = value;
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

			Matrix3DUtils.transformVector(unprojectionMatrix,v,v);
			
			//z is unaffected by transform
			v.z = sZ;
			
			return v;
		}
		
		override public function clone():LensBase
		{
			var clone:OrthographicOffCenterLens = new OrthographicOffCenterLens(_minX, _maxX, _minY, _maxY);
			clone._near = _near;
			clone._far = _far;
			clone._aspectRatio = _aspectRatio;
			return clone;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateMatrix():void
		{
			var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var w:Number = 1/(_maxX - _minX);
			var h:Number = 1/(_maxY - _minY);
			var d:Number = 1/(_far - _near);
			
			raw[0] = 2*w;
			raw[5] = 2*h;
			raw[10] = d;
			raw[12] = -(_maxX + _minX)*w;
			raw[13] = -(_maxY + _minY)*h;
			raw[14] = -_near*d;
			raw[15] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] =
				raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;
			_matrix.copyRawDataFrom(raw);
			
			_frustumCorners[0] = _frustumCorners[9] = _frustumCorners[12] = _frustumCorners[21] = _minX;
			_frustumCorners[3] = _frustumCorners[6] = _frustumCorners[15] = _frustumCorners[18] = _maxX;
			_frustumCorners[1] = _frustumCorners[4] = _frustumCorners[13] = _frustumCorners[16] = _minY;
			_frustumCorners[7] = _frustumCorners[10] = _frustumCorners[19] = _frustumCorners[22] = _maxY;
			_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
			_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
			
			_matrixInvalid = false;
		}
	}
}
