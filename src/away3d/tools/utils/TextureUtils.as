package away3d.tools.utils
{
	import flash.display.BitmapData;

	public class TextureUtils
	{
		private static const MAX_SIZE : uint = 2048;

		public static function isBitmapDataValid(bitmapData : BitmapData) : Boolean
		{
			if (bitmapData == null) return true;

			var w : int = bitmapData.width;
			var h : int = bitmapData.height;

			if (w < 2 || h < 2 || w > MAX_SIZE || h > MAX_SIZE) return false;

			if (isPowerOfTwo(w) && isPowerOfTwo(h)) return true;

			return false;
		}

		public static function isPowerOfTwo(value : int) : Boolean
		{
			return value ? ((value & -value) == value) : false;
		}

		public static function getBestPowerOf2(value : int) : Number
		{
			var p : int = 1;

			while (p < value)
				p <<= 1;

			if (p > 2048) p = 2048;

			return p;
		}
	}
}
