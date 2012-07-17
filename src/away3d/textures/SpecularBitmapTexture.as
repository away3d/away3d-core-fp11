package away3d.textures
{
	import away3d.arcane;

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	use namespace arcane;

	/**
	 * A convenience texture that encodes a specular map in the red channel, and the gloss map in the green channel, as expected by BasicSpecularMapMethod
	 */
	public class SpecularBitmapTexture extends BitmapTexture
	{
		private var _specularMap : BitmapData;
		private var _glossMap : BitmapData;

		public function SpecularBitmapTexture(specularMap : BitmapData = null, glossMap : BitmapData = null)
		{
			var bmd : BitmapData;

			if (specularMap) bmd = specularMap;
			else bmd = glossMap;
			bmd = bmd? new BitmapData(bmd.width, bmd.height, false, 0xffffff) : new BitmapData(1, 1, false, 0xffffff);

			super(bmd);

			this.specularMap = specularMap;
			this.glossMap = glossMap;
		}

		public function get specularMap() : BitmapData
		{
			return _specularMap;
		}

		public function set specularMap(value : BitmapData) : void
		{
			_specularMap = value;
			invalidateContent();

			testSize();
		}

		public function get glossMap() : BitmapData
		{
			return _glossMap;
		}

		public function set glossMap(value : BitmapData) : void
		{
			_glossMap = value;
			invalidateContent();

			testSize();
		}

		private function testSize() : void
		{
			var w : Number, h : Number;

			if (_specularMap) {
				w = _specularMap.width;
				h = _specularMap.height;
			}
			else if (_glossMap) {
				w = _glossMap.width;
				h = _glossMap.height;
			}
			else {
				w = 1;
				h = 1;
			}

			if (w != bitmapData.width && h != bitmapData.height) {
				var oldBitmap : BitmapData = bitmapData;
				super.bitmapData = new BitmapData(_specularMap.width, specularMap.height, false, 0xffffff);
				oldBitmap.dispose();
			}
		}

		override protected function uploadContent(texture : TextureBase) : void
		{
			var rect : Rectangle = _specularMap.rect;
			var origin : Point = new Point();

			bitmapData.fillRect(rect,  0xffffff);

			if (_glossMap)
				bitmapData.copyChannel(_glossMap, rect, origin, BitmapDataChannel.GREEN, BitmapDataChannel.GREEN);

			if (_specularMap)
				bitmapData.copyChannel(_specularMap, rect, origin, BitmapDataChannel.RED, BitmapDataChannel.RED);

			super.uploadContent(texture);
		}

		override public function dispose() : void
		{
			bitmapData.dispose();
			bitmapData = null;
		}
	}
}
