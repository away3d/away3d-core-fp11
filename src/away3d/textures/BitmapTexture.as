package away3d.textures
{
	import away3d.arcane;
	import away3d.materials.utils.MipmapGenerator;
	import away3d.tools.utils.TextureUtils;

	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;

	use namespace arcane;

	public class BitmapTexture extends Texture2DBase
	{
		private static var _mipMaps : Array = [];
		private static var _mipMapUses : Array = [];

		private var _bitmapData : BitmapData;
		private var _mipMapHolder : BitmapData;

		public function BitmapTexture(bitmapData : BitmapData)
		{
			super();

			this.bitmapData = bitmapData;
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

			setMipMap();
		}

		override protected function uploadContent(texture : TextureBase) : void
		{
			MipmapGenerator.generateMipMaps(_bitmapData, texture, _mipMapHolder, true);
		}

		private function setMipMap() : void
		{
			var oldW : uint, oldH : uint;
			var newW : uint, newH : uint;

			newW = _bitmapData.width;
			newH = _bitmapData.height;

			if (_mipMapHolder) {
				oldW = _mipMapHolder.width;
				oldH = _mipMapHolder.height;
				if (oldW == _bitmapData.width && oldH == _bitmapData.height) return;

				if (--_mipMapUses[oldW][_mipMapHolder.height] == 0) {
					_mipMaps[oldW][oldH].dispose();
					_mipMaps[oldW][oldH] = null;
				}
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
				++_mipMapUses[newW][newH];
				_mipMapHolder = _mipMaps[newW][newH];
			}
		}
	}
}
