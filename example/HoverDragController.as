package {
    import away3d.cameras.Camera3D;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;

	/**
	 * Makes the camera rotate around a target on drag. Hardly a proper scalable implementation, but this is just to support the simple demo.
	 *
	 * @author David Lenaerts
	 */
	public class HoverDragController
	{
		private var _stage : Stage;
		private var _target : Vector3D;
		private var _camera : Camera3D;
		private var _radius : Number = 1000;
		private var _speed : Number = .005;
		private var _dragSmoothing : Number = .1;
		private var _drag : Boolean;
		private var _referenceX : Number = 0;
		private var _referenceY : Number = 0;
		private var _xRad : Number = 0;
		private var _yRad : Number = .5;
		private var _targetXRad : Number = 0;
		private var _targetYRad : Number = .5;
        private var _targetRadius : Number = 1000;

		/**
		 * Creates a HoverDragController object
		 * @param camera The camera to control
		 * @param stage The stage that will be receiving mouse events
		 */
		public function HoverDragController(camera : Camera3D, stage : Stage)
		{
			_stage = stage;
			_target = new Vector3D();
			_camera = camera;

			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            _stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		/**
		 * Amount of "lag" the camera has
		 */
		public function get dragSmoothing() : Number
		{
			return _dragSmoothing;
		}

		public function set dragSmoothing(value : Number) : void
		{
			_dragSmoothing = value;
		}

		/**
		 * The distance of the camera to the target
		 */
		public function get radius() : Number
		{
			return _targetRadius;
		}

		public function set radius(value : Number) : void
		{
			_targetRadius = value;
		}

		/**
		 * The amount by which the camera be moved relative to the mouse movement
		 */
		public function get speed() : Number
		{
			return _speed;
		}

		public function set speed(value : Number) : void
		{
			_speed = value;
		}

		/**
		 * Removes all listeners
		 */
		public function destroy() : void
		{
			_stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            _stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            _stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

        /**
		 * The center of attention for the camera
		 */
		public function get target() : Vector3D
		{
			return _target;
		}

		public function set target(value : Vector3D) : void
		{
			_target = value;
		}

		/**
		 * Update cam movement towards its target position
		 */
		private function onEnterFrame(event : Event) : void
		{
			if (_drag) updateRotationTarget();

            _radius = _radius + (_targetRadius - _radius)*dragSmoothing;
			_xRad = _xRad + (_targetXRad - _xRad)*dragSmoothing;
			_yRad = _yRad + (_targetYRad - _yRad)*dragSmoothing;

			// simple spherical position based on spherical coordinates
			var cy : Number = Math.cos(_yRad)*_radius;
			_camera.x = _target.x - Math.sin(_xRad)*cy;
			_camera.y = _target.y - Math.sin(_yRad)*_radius;
			_camera.z = _target.z - Math.cos(_xRad)*cy;
			_camera.lookAt(_target);
		}

		/**
		 * If dragging, update the target position's spherical coordinates
		 */
		private function updateRotationTarget() : void
		{
			var mouseX : Number = _stage.mouseX;
			var mouseY : Number = _stage.mouseY;
			var dx : Number = mouseX - _referenceX;
			var dy : Number = mouseY - _referenceY;
			var bound : Number = Math.PI * .5 - .05;

			_referenceX = mouseX;
			_referenceY = mouseY;
			_targetXRad += dx * _speed;
			_targetYRad += dy * _speed;
			if (_targetYRad > bound) _targetYRad = bound;
			else if (_targetYRad < -bound) _targetYRad = -bound;
		}

		/**
		 * Start dragging
		 */
		private function onMouseDown(event : MouseEvent) : void
		{
			_drag = true;
			_referenceX = _stage.mouseX;
			_referenceY = _stage.mouseY;
		}

		/**
		 * Stop dragging
		 */
		private function onMouseUp(event : MouseEvent) : void
		{
			_drag = false;
		}

        /**
         * Updates camera distance
         */
        private function onMouseWheel(event:MouseEvent) : void
        {
            _targetRadius -= event.delta*5;
        }


	}
}
