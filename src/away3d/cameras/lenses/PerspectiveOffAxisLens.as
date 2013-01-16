package away3d.cameras.lenses
{
	import away3d.core.managers.Stage3DProxy;
	import flash.geom.Rectangle;
	import away3d.core.math.Matrix3DUtils;

	/**
	 * The PerspectiveLens object provides a projection matrix that projects 3D geometry with perspective distortion.
	 */
	public class PerspectiveOffAxisLens extends LensBase
	{
		private var _fieldOfView : Number;
		private var _focalLengthInv : Number;
		private var _yMax : Number;
		private var _xMax : Number;
		private var _stageProxy : Stage3DProxy;
		private var _viewArea : Rectangle;
		public var xOff : Number = 0;
		public var yOff : Number = 0;
		public var wOff : Number = 0;
		public var hOff : Number = 0;

		/**
		 * Creates a new PerspectiveLens object.
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function PerspectiveOffAxisLens(stageProxy : Stage3DProxy, viewArea:Rectangle = null, fieldOfView : Number = 60)
		{
			super();
			this.fieldOfView = fieldOfView;
			this.stageProxy = stageProxy;
			this.viewArea = viewArea ||= new Rectangle(0, 0, _stageProxy.width, _stageProxy.height);
		}

		/**
		 * The stage3DProxy containing the off-axis perspective clip area
		 */
		public function get stageProxy() : Stage3DProxy
		{ 
			return _stageProxy;
		}
		
		public function set stageProxy(stageProxy : Stage3DProxy) : void 
		{ 
			_stageProxy = stageProxy;
			invalidateMatrix();
		}
		

		/**
		 * The rectangulare area where the the scene is to be centered
		 */
		public function get viewArea() : Rectangle
		{ 
			return _viewArea;
		}
		public function set viewArea(viewArea : Rectangle) : void
		{ 
			_viewArea = viewArea;
			invalidateMatrix();
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

		override public function clone() : LensBase
		{
			var clone : PerspectiveOffAxisLens = new PerspectiveOffAxisLens(_stageProxy, _viewArea, _fieldOfView);
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

			var left:Number = _viewArea.x - _stageProxy.width * 0.5;
			var right:Number = _viewArea.x + _viewArea.width - _stageProxy.width * 0.5;
			var top:Number = _stageProxy.height * 0.5 - _viewArea.y;
			var bottom:Number = _stageProxy.height * 0.5 - _viewArea.y - _viewArea.height;

			var ym2:Number = _yMax * 2;
			var xWid:Number = ym2 * (stageProxy.width / _viewArea.width) * _aspectRatio;
			var yHgt:Number = ym2 * (stageProxy.height / _viewArea.height);
			var centre:Number = left + (_viewArea.width * 0.5);
			var centerScaled:Number = ym2 * (centre / _viewArea.height);
			var middle:Number = bottom + (_viewArea.height * 0.5);
			var middleScaled:Number = ym2 * (middle / _viewArea.height);
			left = centerScaled - xWid * 0.5;
			right = centerScaled + xWid * 0.5;
			top = middleScaled + yHgt * 0.5;
			bottom = middleScaled - yHgt * 0.5;

			var a:Number = (right + left) / (right - left);
    		var b:Number = (bottom + top) / (top - bottom);
    		var c:Number = (_far + _near) / (_far - _near);
    		var d:Number = -2 * _far * _near / (_far - _near);
			
			raw[uint(0)] = 2 * _near / (right - left);
			raw[uint(5)] = 2 * _near / (top - bottom);
			raw[uint(8)] = a;
			raw[uint(9)] = b;
			raw[uint(10)] = c;
			raw[uint(11)] = 1;
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
			raw[uint(6)] = raw[uint(7)] = raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
			raw[uint(14)] = d;

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
		
		public function updateMatrixRect(l:int, r:int, w:int, h:int) : void
		{
			_viewArea.x = l;
			_viewArea.y = r;
			_viewArea.width = w;
			_viewArea.height = h;

			invalidateMatrix();
		}
	}
}