package away3d.controllers
{
	import away3d.arcane;
	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.core.math.*;

	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * Extended camera used to hover round a specified target object.
	 * 
	 * @see	away3d.containers.View3D
	 */
	public class HoverController extends LookAtController
	{
		arcane var _currentPanAngle:Number = 0;
		arcane var _currentTiltAngle:Number = 90;
		
		private var _panAngle:Number = 0;
		private var _tiltAngle:Number = 90;
		private var _distance:Number = 1000;
		private var _minPanAngle:Number = -Infinity;
		private var _maxPanAngle:Number = Infinity;
		private var _minTiltAngle:Number = -90;
		private var _maxTiltAngle:Number = 90;
		private var _steps:uint = 8;
		private var _yFactor:Number = 2;
		private var _wrapPanAngle:Boolean = false;
		
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
			val = Math.max(_minPanAngle, Math.min(_maxPanAngle, val));
			
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
		 * Distance between the camera and the specified target. Defaults to 1000.
		 */
		public function get distance():Number
		{
			return _distance;
		}
		
		public function set distance(val:Number):void
		{
			if (_distance == val)
				return;
			
			_distance = val;
			
			notifyUpdate();
		}
		
		/**
		 * Minimum bounds for the <code>panAngle</code>. Defaults to -Infinity.
		 * 
		 * @see	#panAngle
		 */
		public function get minPanAngle():Number
		{
			return _minPanAngle;
		}
		
		public function set minPanAngle(val:Number):void
		{
			if (_minPanAngle == val)
				return;
			
			_minPanAngle = val;
			
			panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
		}
		
		/**
		 * Maximum bounds for the <code>panAngle</code>. Defaults to Infinity.
		 * 
		 * @see	#panAngle
		 */
		public function get maxPanAngle():Number
		{
			return _maxPanAngle;
		}
		
		public function set maxPanAngle(val:Number):void
		{
			if (_maxPanAngle == val)
				return;
			
			_maxPanAngle = val;
			
			panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
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
		 * Fractional difference in distance between the horizontal camera orientation and vertical camera orientation. Defaults to 2.
		 * 
		 * @see	#distance
		 */
		public function get yFactor():Number
		{
			return _yFactor;
		}
		
		public function set yFactor(val:Number):void
		{
			if (_yFactor == val)
				return;
			
			_yFactor = val;
			
			notifyUpdate();
		}
		
		/**
		 * Defines whether the value of the pan angle wraps when over 360 degrees or under 0 degrees. Defaults to false.
		 */
		public function get wrapPanAngle():Boolean
		{
			return _wrapPanAngle;
		}
		
		public function set wrapPanAngle(val:Boolean):void
		{
			if (_wrapPanAngle == val)
				return;
			
			_wrapPanAngle = val;
			
			notifyUpdate();
		}
		
		/**
		 * Creates a new <code>HoverController</code> object.
		 */
		public function HoverController(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null, panAngle:Number = 0, tiltAngle:Number = 90, distance:Number = 1000, minTiltAngle:Number = -90, maxTiltAngle:Number = 90, minPanAngle:Number = NaN, maxPanAngle:Number = NaN, steps:uint = 8, yFactor:Number = 2, wrapPanAngle:Boolean = false)
		{
			super(targetObject, lookAtObject);
			
			this.distance = distance;
			this.panAngle = panAngle;
			this.tiltAngle = tiltAngle;
			this.minPanAngle = minPanAngle || -Infinity;
			this.maxPanAngle = maxPanAngle || Infinity;
			this.minTiltAngle = minTiltAngle;
			this.maxTiltAngle = maxTiltAngle;
			this.steps = steps;
			this.yFactor = yFactor;
			this.wrapPanAngle = wrapPanAngle;
			
			//values passed in contrustor are applied immediately
			_currentPanAngle = _panAngle;
			_currentTiltAngle = _tiltAngle;
		}
		
		/**
		 * Updates the current tilt angle and pan angle values.
		 * 
		 * Values are calculated using the defined <code>tiltAngle</code>, <code>panAngle</code> and <code>steps</code> variables.
		 * 
		 * @param interpolate   If the update to a target pan- or tiltAngle is interpolated. Default is true.
		 *
		 * @see	#tiltAngle
		 * @see	#panAngle
		 * @see	#steps
		 */
		public override function update(interpolate:Boolean = true):void
		{
			if (_tiltAngle != _currentTiltAngle || _panAngle != _currentPanAngle) {
				
				notifyUpdate();
				
				if (_wrapPanAngle) {
					if (_panAngle < 0)
						_panAngle = (_panAngle % 360) + 360;
					else
						_panAngle = _panAngle % 360;
					
					if (_panAngle - _currentPanAngle < -180)
						_currentPanAngle -= 360;
					else if (_panAngle - _currentPanAngle > 180)
						_currentPanAngle += 360;
				}

				if(interpolate){
					_currentTiltAngle += (_tiltAngle - _currentTiltAngle)/(steps + 1);
					_currentPanAngle += (_panAngle - _currentPanAngle)/(steps + 1);	
				} else {
					_currentPanAngle = _panAngle;
					_currentTiltAngle = _tiltAngle;
				}
				
				//snap coords if angle differences are close
				if ((Math.abs(tiltAngle - _currentTiltAngle) < 0.01) && (Math.abs(_panAngle - _currentPanAngle) < 0.01)) {
					_currentTiltAngle = _tiltAngle;
					_currentPanAngle = _panAngle;
				}
			}
			
			var pos:Vector3D = (lookAtObject)? lookAtObject.position : (lookAtPosition)? lookAtPosition: _origin;
			targetObject.x = pos.x + distance*Math.sin(_currentPanAngle*MathConsts.DEGREES_TO_RADIANS)*Math.cos(_currentTiltAngle*MathConsts.DEGREES_TO_RADIANS);
			targetObject.z = pos.z + distance*Math.cos(_currentPanAngle*MathConsts.DEGREES_TO_RADIANS)*Math.cos(_currentTiltAngle*MathConsts.DEGREES_TO_RADIANS);
			targetObject.y = pos.y + distance*Math.sin(_currentTiltAngle*MathConsts.DEGREES_TO_RADIANS)*yFactor;
			
			super.update();
		}
	}
}