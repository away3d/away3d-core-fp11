package away3d.textures
{
	import away3d.arcane;
	import away3d.materials.utils.MipmapGenerator;
	import away3d.tools.utils.TextureUtils;

	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	public class BitmapCubeTexture extends CubeTextureBase
	{
		private var _bitmapDatas : Vector.<BitmapData>;

		public function BitmapCubeTexture(posX : BitmapData, negX : BitmapData, posY : BitmapData, negY : BitmapData, posZ : BitmapData, negZ : BitmapData)
		{
			super();

			_bitmapDatas = new Vector.<BitmapData>(6, true);
			testSize(_bitmapDatas[0] = posX);
			testSize(_bitmapDatas[1] = negX);
			testSize(_bitmapDatas[2] = posY);
			testSize(_bitmapDatas[3] = negY);
			testSize(_bitmapDatas[4] = posZ);
			testSize(_bitmapDatas[5] = negZ);

			setSize(posX.width, posX.height);
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
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
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
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
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
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
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
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
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
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
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
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[5] = value;
		}

		private function testSize(value : BitmapData) : void
		{
			if (value.width != value.height) throw new Error("BitmapData should have equal width and height!");
			if (!TextureUtils.isBitmapDataValid(value)) throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");
		}


		override protected function uploadContent(texture : TextureBase) : void
		{
			for (var i : int = 0; i < 6; ++i)
				MipmapGenerator.generateMipMaps(_bitmapDatas[i], texture, null, false, i);
		}
	}
}
