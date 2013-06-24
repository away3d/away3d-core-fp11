package away3d.cameras.lenses
{
	import away3d.core.math.*;
	
	import flash.geom.Vector3D;
	
	/**
	 * The PerspectiveLens object provides a projection matrix that projects 3D geometry with perspective distortion.
	 */
	public class PerspectiveOffCenterLens extends LensBase
	{
		private var _minAngleX:Number;
		private var _minLengthX:Number;
		private var _tanMinX:Number;
		private var _maxAngleX:Number;
		private var _maxLengthX:Number;
		private var _tanMaxX:Number;
		private var _minAngleY:Number;
		private var _minLengthY:Number;
		private var _tanMinY:Number;
		private var _maxAngleY:Number;
		private var _maxLengthY:Number;
		private var _tanMaxY:Number;
		
		/**
		 * Creates a new PerspectiveLens object.
		 *
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function PerspectiveOffCenterLens(minAngleX:Number = -40, maxAngleX:Number = 40, minAngleY:Number = -40, maxAngleY:Number = 40)
		{
			super();
			
			this.minAngleX = minAngleX;
			this.maxAngleX = maxAngleX;
			this.minAngleY = minAngleY;
			this.maxAngleY = maxAngleY;
		}
		
		public function get minAngleX():Number
		{
			return _minAngleX;
		}
		
		public function set minAngleX(value:Number):void
		{
			_minAngleX = value;
			
			_tanMinX = Math.tan(_minAngleX*Math.PI/180);
			
			invalidateMatrix();
		}
		
		public function get maxAngleX():Number
		{
			return _maxAngleX;
		}
		
		public function set maxAngleX(value:Number):void
		{
			_maxAngleX = value;
			
			_tanMaxX = Math.tan(_maxAngleX*Math.PI/180);
			
			invalidateMatrix();
		}
		
		public function get minAngleY():Number
		{
			return _minAngleY;
		}
		
		public function set minAngleY(value:Number):void
		{
			_minAngleY = value;
			
			_tanMinY = Math.tan(_minAngleY*Math.PI/180);
			
			invalidateMatrix();
		}
		
		public function get maxAngleY():Number
		{
			return _maxAngleY;
		}
		
		public function set maxAngleY(value:Number):void
		{
			_maxAngleY = value;
			
			_tanMaxY = Math.tan(_maxAngleY*Math.PI/180);
			
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
		override public function unproject(nX:Number, nY:Number, sZ:Number):Vector3D
		{
			var v:Vector3D = new Vector3D(nX, -nY, sZ, 1.0);
			
			v.x *= sZ;
			v.y *= sZ;
			
			v = unprojectionMatrix.transformVector(v);
			
			//z is unaffected by transform
			v.z = sZ;
			
			return v;
		}
		
		override public function clone():LensBase
		{
			var clone:PerspectiveOffCenterLens = new PerspectiveOffCenterLens(_minAngleX, _maxAngleX, _minAngleY, _maxAngleY);
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
			
			_minLengthX = _near*_tanMinX;
			_maxLengthX = _near*_tanMaxX;
			_minLengthY = _near*_tanMinY;
			_maxLengthY = _near*_tanMaxY;
			
			var minLengthFracX:Number = -_minLengthX/(_maxLengthX - _minLengthX);
			var minLengthFracY:Number = -_minLengthY/(_maxLengthY - _minLengthY);
			
			var left:Number, right:Number, top:Number, bottom:Number;
			
			// assume scissored frustum
			var center:Number = -_minLengthX*(_scissorRect.x + _scissorRect.width*minLengthFracX)/(_scissorRect.width*minLengthFracX);
			var middle:Number = _minLengthY*(_scissorRect.y + _scissorRect.height*minLengthFracY)/(_scissorRect.height*minLengthFracY);
			
			left = center - (_maxLengthX - _minLengthX)*(_viewPort.width/_scissorRect.width);
			right = center;
			top = middle;
			bottom = middle + (_maxLengthY - _minLengthY)*(_viewPort.height/_scissorRect.height);
			
			raw[uint(0)] = 2*_near/(right - left);
			raw[uint(5)] = 2*_near/(bottom - top);
			raw[uint(8)] = (right + left)/(right - left);
			raw[uint(9)] = (bottom + top)/(bottom - top);
			raw[uint(10)] = (_far + _near)/(_far - _near);
			raw[uint(11)] = 1;
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
				raw[uint(6)] = raw[uint(7)] = raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
			raw[uint(14)] = -2*_far*_near/(_far - _near);
			
			_matrix.copyRawDataFrom(raw);
			
			_minLengthX = _far*_tanMinX;
			_maxLengthX = _far*_tanMaxX;
			_minLengthY = _far*_tanMinY;
			_maxLengthY = _far*_tanMaxY;
			
			_frustumCorners[0] = _frustumCorners[9] = left;
			_frustumCorners[3] = _frustumCorners[6] = right;
			_frustumCorners[1] = _frustumCorners[4] = top;
			_frustumCorners[7] = _frustumCorners[10] = bottom;
			
			_frustumCorners[12] = _frustumCorners[21] = _minLengthX;
			_frustumCorners[15] = _frustumCorners[18] = _maxLengthX;
			_frustumCorners[13] = _frustumCorners[16] = _minLengthY;
			_frustumCorners[19] = _frustumCorners[22] = _maxLengthY;
			
			_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
			_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
			
			_matrixInvalid = false;
		}
	}
}
