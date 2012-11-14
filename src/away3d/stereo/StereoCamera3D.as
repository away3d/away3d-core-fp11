package away3d.stereo
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.LensBase;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	public class StereoCamera3D extends Camera3D
	{
		private var _leftCam : Camera3D;
		private var _rightCam : Camera3D;
		
		private var _offset : Number;
		private var _focus : Number;
		private var _focusPoint : Vector3D;
		private var _focusInfinity : Boolean;
		
		private var _leftCamDirty : Boolean = true;
		private var _rightCamDirty : Boolean = true;
		private var _focusPointDirty : Boolean = true;
		
		public function StereoCamera3D(lens:LensBase=null)
		{
			super(lens);
			
			_leftCam = new Camera3D(lens);
			_rightCam = new Camera3D(lens);
			
			_offset = 0;
			_focus = 1000;
			_focusPoint = new Vector3D();
		}
		
		override public function set lens(value : LensBase) : void
		{
			_leftCam.lens = value;
			_rightCam.lens = value;
			
			super.lens = value;
		}
		
		
		public function get leftCamera() : Camera3D
		{
			if (_leftCamDirty) {
				var tf : Matrix3D;
				
				if (_focusPointDirty)
					updateFocusPoint();
				
				tf = _leftCam.transform;
				tf.copyFrom(transform);
				tf.prependTranslation(-_offset, 0, 0);
				_leftCam.transform = tf;
				
				if (!_focusInfinity)
					_leftCam.lookAt(_focusPoint);
				
				_leftCamDirty = false;
			}
			
			return _leftCam;
		}
		
		
		public function get rightCamera() : Camera3D
		{
			if (_rightCamDirty) {
				var tf : Matrix3D;
				
				if (_focusPointDirty)
					updateFocusPoint();
				
				tf = _rightCam.transform;
				tf.copyFrom(transform);
				tf.prependTranslation(_offset, 0, 0);
				_rightCam.transform = tf;
				
				if (!_focusInfinity)
					_rightCam.lookAt(_focusPoint);
				
				_rightCamDirty = false;
			}
			
			return _rightCam;
		}
		

		public function get stereoFocus():Number
		{
			return _focus;
		}

		public function set stereoFocus(value:Number):void
		{
			_focus = value;
//			trace('focus:', _focus);
			invalidateStereoCams();
		}

		public function get stereoOffset():Number
		{
			return _offset;
		}
		public function set stereoOffset(value:Number):void
		{
			_offset = value;
			invalidateStereoCams();
		}
		
		
		protected function updateFocusPoint() : void
		{
			if (_focus == Infinity) {
				_focusInfinity = true;
			}
			else {
				_focusPoint.x = 0;
				_focusPoint.y = 0;
				_focusPoint.z = _focus;
				
				_focusPoint = transform.transformVector(_focusPoint);
				
				_focusInfinity = false;
				_focusPointDirty = false;
			}
		}
		
		
		override arcane function invalidateTransform() : void
		{
			super.invalidateTransform();
			invalidateStereoCams();
		}
		
		
		arcane function invalidateStereoCams() : void
		{
			_leftCamDirty = true;
			_rightCamDirty = true;
			_focusPointDirty = true;
		}
	}
}
