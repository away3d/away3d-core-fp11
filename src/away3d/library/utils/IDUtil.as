package away3d.library.utils
{
	
	public class IDUtil
	{
		/**
		 *  @private
		 *  Char codes for 0123456789ABCDEF
		 */
		private static const ALPHA_CHAR_CODES:Array = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];
		
		/**
		 *  Generates a UID (unique identifier) based on ActionScript's
		 *  pseudo-random number generator and the current time.
		 *
		 *  <p>The UID has the form
		 *  <code>"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"</code>
		 *  where X is a hexadecimal digit (0-9, A-F).</p>
		 *
		 *  <p>This UID will not be truly globally unique; but it is the best
		 *  we can do without player support for UID generation.</p>
		 *
		 *  @return The newly-generated UID.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static function createUID():String
		{
			var uid:Array = new Array(36);
			var index:int = 0;
			
			var i:int;
			var j:int;
			
			for (i = 0; i < 8; i++)
				uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random()*16)];
			
			for (i = 0; i < 3; i++) {
				uid[index++] = 45; // charCode for "-"
				
				for (j = 0; j < 4; j++)
					uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random()*16)];
			}
			
			uid[index++] = 45; // charCode for "-"
			
			var time:Number = new Date().getTime();
			// Note: time is the number of milliseconds since 1970,
			// which is currently more than one trillion.
			// We use the low 8 hex digits of this number in the UID.
			// Just in case the system clock has been reset to
			// Jan 1-4, 1970 (in which case this number could have only
			// 1-7 hex digits), we pad on the left with 7 zeros
			// before taking the low digits.
			var timeString:String = ("0000000" + time.toString(16).toUpperCase()).substr(-8);
			
			for (i = 0; i < 8; i++)
				uid[index++] = timeString.charCodeAt(i);
			
			for (i = 0; i < 4; i++)
				uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random()*16)];
			
			return String.fromCharCode.apply(null, uid);
		}
		
		/**
		 * Returns the decimal representation of a hex digit.
		 * @private
		 */
		private static function getDigit(hex:String):uint
		{
			switch (hex) {
				case "A":
				case "a":
					return 10;
				case "B":
				case "b":
					return 11;
				case "C":
				case "c":
					return 12;
				case "D":
				case "d":
					return 13;
				case "E":
				case "e":
					return 14;
				case "F":
				case "f":
					return 15;
				default:
					return new uint(hex);
			}
		}
	}
}
