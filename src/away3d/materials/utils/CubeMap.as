package away3d.materials.utils
{
	import away3d.arcane;

	import flash.display.BitmapData;
	import flash.display3D.textures.CubeTexture;

	use namespace arcane;

	/**
	 * CubeMap represents a cube map texture, consisting out of 6 BitmapData objects. All BitmapData objects should be
	 * of the same size.
	 */
	public class CubeMap
	{
		private var _bitmapDatas : Vector.<BitmapData>;
		private var _size : int;

		/**
		 * Creates a new CubeMap object.
		 * @param posX The texture on the cube's right face.
		 * @param negX The texture on the cube's left face.
		 * @param posY The texture on the cube's top face.
		 * @param negY The texture on the cube's bottom face.
		 * @param posZ The texture on the cube's far face.
		 * @param negZ The texture on the cube's near face.
		 */
		public function CubeMap(posX : BitmapData = null, negX : BitmapData = null,
								posY : BitmapData = null, negY : BitmapData = null,
								posZ : BitmapData = null, negZ : BitmapData = null)
		{
			_bitmapDatas = new Vector.<BitmapData>(6, true);
			_bitmapDatas[0] = posX;
			_bitmapDatas[1] = negX;
			_bitmapDatas[2] = posY;
			_bitmapDatas[3] = negY;
			_bitmapDatas[4] = posZ;
			_bitmapDatas[5] = negZ;
			if (positiveX) {
				_size = positiveX.width;
				_size = positiveY.width;
			}
		}

		/**
		 * The size of the cube map texture.
		 */
		public function get size() : int
		{
			return _size;
		}

		/**
		 * The texture on the cube's right face.
		 */
		public function get positiveX() : BitmapData
		{
			return _bitmapDatas[0];
		}

		public function set positiveX(value : BitmapData) : void
		{
			_size = value.width;
			_bitmapDatas[0] = value;
		}

		/**
		 * The texture on the cube's left face.
		 */
		public function get negativeX() : BitmapData
		{
			return _bitmapDatas[1];
		}

		public function set negativeX(value : BitmapData) : void
		{
			_bitmapDatas[1] = value;
		}

		/**
		 * The texture on the cube's top face.
		 */
		public function get positiveY() : BitmapData
		{
			return _bitmapDatas[2];
		}

		public function set positiveY(value : BitmapData) : void
		{
			_bitmapDatas[2] = value;
		}

		/**
		 * The texture on the cube's bottom face.
		 */
		public function get negativeY() : BitmapData
		{
			return _bitmapDatas[3];
		}

		public function set negativeY(value : BitmapData) : void
		{
			_bitmapDatas[3] = value;
		}

		/**
		 * The texture on the cube's far face.
		 */
		public function get positiveZ() : BitmapData
		{
			return _bitmapDatas[4];
		}

		public function set positiveZ(value : BitmapData) : void
		{
			_bitmapDatas[4] = value;
		}

		/**
		 * The texture on the cube's near face.
		 */
		public function get negativeZ() : BitmapData
		{
			return _bitmapDatas[5];
		}

		public function set negativeZ(value : BitmapData) : void
		{
			_bitmapDatas[5] = value;
		}

		/**
		 * Disposes of all BitmapData objects used by this CubeMap.
		 */
		public function dispose() : void
		{
			if (_bitmapDatas)
				for (var i : int = 0; i < 6; ++i)
					_bitmapDatas[i].dispose();

			_bitmapDatas = null;
		}

		/**
		 * Uploads the BitmapData objects to the CubeTexture.
		 * @param cubeTexture The CubeTexture to upload to.
		 */
		arcane function upload(cubeTexture : CubeTexture) : void
		{
			for (var i : int = 0; i < 6; ++i)
				cubeTexture.uploadFromBitmapData(_bitmapDatas[i], i);
		}
	}
}
