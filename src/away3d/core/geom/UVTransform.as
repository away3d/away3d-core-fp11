package away3d.core.geom
{
	import flash.geom.Matrix;

	public class UVTransform
	{
		private var _uvMatrix:Matrix = new Matrix();
		private var _uvMatrixDirty:Boolean;
		private var _rotation:Number = 0;
		private var _scaleU:Number = 1;
		private var _scaleV:Number = 1;
		private var _offsetU:Number = 0;
		private var _offsetV:Number = 0;

		/**
		 *
		 */
		public function  get offsetU():Number
		{
			return _offsetU;
		}

		public function set offsetU(value:Number):void
		{
			if (value == _offsetU)
				return;

			_offsetU = value;
			_uvMatrixDirty = true;
		}

		/**
		 *
		 */
		public function get offsetV():Number
		{
			return _offsetV;
		}

		public function set offsetV(value:Number):void
		{
			if (value == _offsetV)
				return;

			_offsetV = value;
			_uvMatrixDirty = true;

		}

		/**
		 *
		 */
		public function get rotation():Number
		{
			return _rotation;
		}

		public function set rotation(value:Number):void
		{
			if (value == _rotation)
				return;

			_rotation = value;

			_uvMatrixDirty = true;
		}

		/**
		 *
		 */
		public function get scaleU():Number
		{
			return _scaleU;
		}

		public function set scaleU(value:Number):void
		{
			if (value == _scaleU)
				return;

			_scaleU = value;

			_uvMatrixDirty = true;
		}

		/**
		 *
		 */
		public function get scaleV():Number
		{
			return _scaleV;
		}

		public function set scaleV(value:Number):void
		{
			if (value == _scaleV)
				return;

			_scaleV = value;

			_uvMatrixDirty = true;
		}

		/**
		 *
		 */
		public function get matrix():Matrix
		{
			if (_uvMatrixDirty)
				updateUVMatrix();

			return _uvMatrix;
		}


		/**
		 * @private
		 */
		private function updateUVMatrix():void
		{
			_uvMatrix.identity();

			if (_rotation != 0)
				_uvMatrix.rotate(_rotation);

			if (_scaleU != 1 || _scaleV != 1)
				_uvMatrix.scale(_scaleU, _scaleV);

			_uvMatrix.translate(_offsetU, _offsetV);

			_uvMatrixDirty = false;
		}
	}
}
