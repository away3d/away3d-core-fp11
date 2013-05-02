package away3d.textures {
	import away3d.arcane;
	import away3d.materials.utils.MipmapGenerator;
	import away3d.tools.utils.TextureUtils;

	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	public class BitmapTexture extends Texture2DBase
	{
		private static var _mipMaps : Array = [];
		private static var _mipMapUses : Array = [];

		private var _bitmapData : BitmapData;
		private var _mipMapHolder : BitmapData;
		private var _generateMipmaps: Boolean;

		public function BitmapTexture(bitmapData : BitmapData, generateMipmaps:Boolean = true)
		{
			super();

			this.bitmapData = bitmapData;
			_generateMipmaps = generateMipmaps;
		}

		public function get bitmapData() : BitmapData
		{
			return _bitmapData;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			if (value == _bitmapData) return;

			if (!TextureUtils.isBitmapDataValid(value))
				throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");

			invalidateContent();
			setSize(value.width, value.height);

			_bitmapData = value;

			if (_generateMipmaps) getMipMapHolder();
		}

		override protected function uploadContent(texture : TextureBase) : void
		{
			if (_generateMipmaps) MipmapGenerator.generateMipMaps(_bitmapData, texture, _mipMapHolder, true);
			else Texture(texture).uploadFromBitmapData (_bitmapData, 0);
		}

		private function getMipMapHolder() : void
		{
			var newW : uint, newH : uint;

			newW = _bitmapData.width;
			newH = _bitmapData.height;

			if (_mipMapHolder) {
				if (_mipMapHolder.width == newW && _bitmapData.height == newH)
					return;

				freeMipMapHolder();
			}

			if (!_mipMaps[newW]) {
				_mipMaps[newW] = [];
				_mipMapUses[newW] = [];
			}
			if (!_mipMaps[newW][newH]) {
				_mipMapHolder = _mipMaps[newW][newH] = new BitmapData(newW, newH, true);
				_mipMapUses[newW][newH] = 1;
			}
			else {
				_mipMapUses[newW][newH] = _mipMapUses[newW][newH] + 1;
				_mipMapHolder = _mipMaps[newW][newH];
			}
		}

		private function freeMipMapHolder() : void
		{
			var holderWidth : uint = _mipMapHolder.width;
			var holderHeight : uint = _mipMapHolder.height;

			if (--_mipMapUses[holderWidth][holderHeight] == 0) {
				_mipMaps[holderWidth][holderHeight].dispose();
				_mipMaps[holderWidth][holderHeight] = null;
			}
		}

		override public function dispose() : void
		{
			super.dispose();

			if (_mipMapHolder)
				freeMipMapHolder();
		}
	}
}
