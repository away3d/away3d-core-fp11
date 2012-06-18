package away3d.controllers
{
	import away3d.arcane;
	import away3d.core.math.*;
	import away3d.entities.*;
	
	use namespace arcane;
	
	/**
	 * Extended camera used to hover round a specified target object.
	 * 
	 * @see	away3d.containers.View3D
	 */
	public class FirstPersonController extends ControllerBase
	{
		arcane var _currentPanAngle:Number = 0;
		arcane var _currentTiltAngle:Number = 90;
		
		private var _panAngle:Number = 0;
		private var _tiltAngle:Number = 90;
		private var _minTiltAngle:Number = -90;
		private var _maxTiltAngle:Number = 90;
		private var _steps:uint = 8;
		private var _walkIncrement:Number = 0;
		private var _strafeIncrement:Number = 0;
		
		/**
		 * Fractional step taken each time the <code>hover()</code> method is called. Defaults to 8.
		 * 
		 * Affects the speed at which the <code>tiltAngle</code> and <code>panAngle</code> resolve to their targets.
		 * 
		 * @see	#tiltAngle
		 * @see	#panAngle
		 */
		public function get steps():uint
		{
			return _steps;
		}
		
		public function set steps(val:uint):void
		{
			val = (val<1)? 1 : val;
			
			if (_steps == val)
				return;
			
			_steps = val;
			
			notifyUpdate();
		}
		
		/**
		 * Rotation of the camera in degrees around the y axis. Defaults to 0.
		 */
		public function get panAngle():Number
		{
			return _panAngle;
		}
		
		public function set panAngle(val:Number):void
		{
			if (_panAngle == val)
				return;
			
			_panAngle = val;
			
			notifyUpdate();
		}
		
		/**
		 * Elevation angle of the camera in degrees. Defaults to 90.
		 */
		public function get tiltAngle():Number
		{
			return _tiltAngle;
		}
		
		public function set tiltAngle(val:Number):void
		{
			val = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, val));
			
			if (_tiltAngle == val)
				return;
			
			_tiltAngle = val;
			
			notifyUpdate();
		}
		
		/**
		 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
		 * 
		 * @see	#tiltAngle
		 */
		public function get minTiltAngle():Number
		{
			return _minTiltAngle;
		}
		
		public function set minTiltAngle(val:Number):void
		{
			if (_minTiltAngle == val)
				return;
			
			_minTiltAngle = val;
			
			tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		}
		
		/**
		 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
		 * 
		 * @see	#tiltAngle
		 */
		public function get maxTiltAngle():Number
		{
			return _maxTiltAngle;
		}
		
		public function set maxTiltAngle(val:Number):void
		{
			if (_maxTiltAngle == val)
				return;
			
			_maxTiltAngle = val;
			
			tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		}
		
		/**
		 * Creates a new <code>HoverController</code> object.
		 */
		public function FirstPersonController(targetObject:Entity = null, panAngle:Number = 0, tiltAngle:Number = 90, minTiltAngle:Number = -90, maxTiltAngle:Number = 90, steps:uint = 8)
		{
			super(targetObject);
			
			this.panAngle = panAngle;
			this.tiltAngle = tiltAngle;
			this.minTiltAngle = minTiltAngle;
			this.maxTiltAngle = maxTiltAngle;
			this.steps = steps;
			
			//values passed in contrustor are applied immediately
			_currentPanAngle = _panAngle;
			_currentTiltAngle = _tiltAngle;
		}
		
		/**
		 * Updates the current tilt angle and pan angle values.
		 * 
		 * Values are calculated using the defined <code>tiltAngle</code>, <code>panAngle</code> and <code>steps</code> variables.
		 * 
		 * @see	#tiltAngle
		 * @see	#panAngle
		 * @see	#steps
		 */
		public override function update():void
		{
			if (_tiltAngle != _currentTiltAngle || _panAngle != _currentPanAngle) {
				
				notifyUpdate();
				
				if (_panAngle < 0)
					panAngle = (_panAngle % 360) + 360;
				else
					panAngle = _panAngle % 360;
				
				if (panAngle - _currentPanAngle < -180)
					panAngle += 360;
				else if (panAngle - _currentPanAngle > 180)
					panAngle -= 360;
				
				_currentTiltAngle += (_tiltAngle - _currentTiltAngle)/(steps + 1);
				_currentPanAngle += (_panAngle - _currentPanAngle)/(steps + 1);
				
				
				//snap coords if angle differences are close
				if ((Math.abs(tiltAngle - _currentTiltAngle) < 0.01) && (Math.abs(_panAngle - _currentPanAngle) < 0.01)) {
					_currentTiltAngle = _tiltAngle;
					_currentPanAngle = _panAngle;
				}
			}
			
			targetObject.rotationX = _currentTiltAngle;
			targetObject.rotationY = _currentPanAngle;
			
			if (_walkIncrement) {
				targetObject.x += _walkIncrement*Math.sin(panAngle*MathConsts.DEGREES_TO_RADIANS);
				targetObject.z += _walkIncrement*Math.cos(panAngle*MathConsts.DEGREES_TO_RADIANS);
				_walkIncrement = 0;
			}
			
			if (_strafeIncrement) {
				targetObject.moveRight(_strafeIncrement);
				_strafeIncrement = 0;
			}
			
		}
		
		public function incrementWalk(val:Number):void
		{
			if (val == 0)
				return;
			
			_walkIncrement += val;
			
			notifyUpdate();
		}
		
		
		public function incrementStrafe(val:Number):void
		{
			if (val == 0)
				return;
			
			_strafeIncrement += val;
			
			notifyUpdate();
		}

	}
}