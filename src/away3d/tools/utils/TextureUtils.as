package away3d.tools.utils
{
	import flash.display.BitmapData;

	public class TextureUtils
	{
		private static const MAX_SIZE : uint = 2048;

		public static function isBitmapDataValid(bitmapData : BitmapData) : Boolean
		{
			if (bitmapData == null) return true;

			return isDimensionValid(bitmapData.width) && isDimensionValid(bitmapData.height);
		}

		public static function isDimensionValid(d : uint) : Boolean
		{
			return d >= 2 && d <= MAX_SIZE && isPowerOfTwo(d);

		}

		private static function isPowerOfTwo(value : int) : Boolean
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
