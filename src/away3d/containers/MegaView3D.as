package away3d.containers
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.FreeMatrixLens;
	import away3d.cameras.lenses.LensBase;
	import away3d.core.render.RendererBase;
	import away3d.events.LensEvent;

	import flash.geom.Matrix3D;

	import flash.utils.getTimer;

	use namespace arcane;

	/**
	 * MegaView3D provides a way to create a View3D that is wider than the standard maximum 2048px width.
	 */
	public class MegaView3D extends View3D
	{
		private var _left : View3D;
		private var _right : View3D;

		private var _leftCamera : Camera3D;
		private var _leftLens : FreeMatrixLens;
		private var _rightCamera : Camera3D;
		private var _rightLens : FreeMatrixLens;
		private var _antiAlias : uint;
		private var _cameraLensInvalid : Boolean;
		private var _hasRight : Boolean;

		public function MegaView3D(scene : Scene3D = null, camera : Camera3D = null)
		{
			_scene = scene || new Scene3D();
			_camera = camera || new Camera3D();
			_camera.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
			_leftLens = new FreeMatrixLens();
			_leftCamera = new Camera3D(_leftLens);
			_left = new View3D(_scene, _leftCamera);
			updateCameraLenses();
			addChild(_left);
		}


		override public function set camera(camera : Camera3D) : void
		{
			_camera.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
			super.camera = camera;
			_camera.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
		}

		/**
		 * @inheritDoc
		 */
		override public function set filters3d(value : Array) : void
		{
			_filters3d = value;
			_left.filters3d = value;
			if (_right) _right.filters3d = value;
		}

		/**
		 * @private
		 */
		override public function set renderer(value : RendererBase) : void
		{
			throw new Error("Setting renderer not supported on MegaView3D");
		}

		/**
		 * @inheritDoc
		 */
		override public function set backgroundColor(value : uint) : void
		{
			_backgroundColor = value;
			_left.backgroundColor = value;
			if (_right) _right.backgroundColor = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function get renderedFacesCount() : uint
		{
			return _hasRight? _left.renderedFacesCount + _right.renderedFacesCount : _left.renderedFacesCount;
		}

		/**
		 * @inheritDoc
		 */
		override public function set antiAlias(value : uint) : void
		{
			_antiAlias = value;
			_left.antiAlias = value;
			if (_right) _right.antiAlias = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function set x(value : Number) : void
		{
			_x = value;
			_left.x = value;
			if (_right) _right.x = 2048+x;
		}

		/**
		 * @inheritDoc
		 */
		override public function set y(value : Number) : void
		{
			_y = value;
			_left.y = value;
			if (_right) _right.y = 2048+y;
		}

		/**
		 * @inheritDoc
		 */
		override public function set height(value : Number) : void
		{
			_height = value;
			_aspectRatio = _width/_height;
			_left.height = value;
			if (_right) _right.height = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function set width(value : Number) : void
		{
			var leftW : Number;
			_width = value;
			_aspectRatio = _width/_height;
			value = int(value);

			if (value > 4096) value = 4096;

			if (value > 2048) {
				_cameraLensInvalid = true;
				_hasRight = true;
				if (!_right) initRight();
				else _right.width = _width - 2048;
				leftW = 2048;
			}
			else {
				_hasRight = false;
//				if (_right) disposeRight();
				leftW = value;
			}

			_left.width = leftW;
		}

		private function disposeLeft() : void
		{
			removeChild(_left);
			_left.dispose();
			_leftCamera.dispose(true);
			_leftCamera = null;
			_leftLens = null;
			_left = null;
		}

		private function disposeRight() : void
		{
			removeChild(_right);
			_right.dispose();
			_rightCamera.dispose(true);
			_rightCamera = null;
			_rightLens = null;
			_right = null;
		}

		private function initRight() : void
		{
			_rightLens = new FreeMatrixLens();
			_rightCamera = new Camera3D(_rightLens);
			_right = new View3D(_scene, _rightCamera);
			_right.x = 2048 + _x;
			_right.width = _width - 2048;
			_right.height = _height;
			_right.antiAlias = _antiAlias;
			_right.filters3d = _filters3d;
			_right.backgroundColor = _backgroundColor;
			addChild(_right);
			updateCameraLenses();
		}


		override public function render() : void
		{
			var time : Number = getTimer();

			if (_time == 0) _time = time;
			_deltaTime = time - _time;
			_time = time;

			if (_hasRight)
				_rightCamera.transform = _leftCamera.transform = _camera.transform;
			else
				_leftCamera.transform = _camera.transform;

			_camera.lens.aspectRatio = _aspectRatio;

			if (_cameraLensInvalid)
				updateCameraLenses();

			_left.render();
			if (_hasRight) _right.render();
		}

		private function onLensMatrixChanged(event : LensEvent) : void
		{
			_cameraLensInvalid = true;
		}

		private function updateCameraLenses() : void
		{
			var leftMtx : Matrix3D = _leftLens.matrix;
			var rightMtx : Matrix3D;
			var srcLens : LensBase = _camera.lens;
			var frustumCorners : Vector.<Number> = _camera.lens.frustumCorners;

			if (_hasRight) {
				rightMtx = _rightLens.matrix;
				var mid : Number = 2048/_width;
				srcLens.getSubFrustumMatrix(0, mid, 0, 1, leftMtx, _leftLens.frustumCorners);
				srcLens.getSubFrustumMatrix(mid, 1, 0, 1, rightMtx, _rightLens.frustumCorners);

				_leftLens.matrix = leftMtx;
				_rightLens.matrix = rightMtx;
			}
			else {
				_leftLens.frustumCorners = frustumCorners;
				leftMtx.copyFrom(srcLens.matrix);
				_leftLens.matrix = leftMtx;
			}

			_cameraLensInvalid = false;
		}

		override public function dispose() : void
		{
			disposeLeft();
			disposeRight();
			_camera.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
		}
	}
}
