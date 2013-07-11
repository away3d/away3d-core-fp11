package away3d.loaders.parsers.utils
{
	import flash.utils.ByteArray;
	
	public class ParserUtil
	{
		
		/**
		 * Returns a object as ByteArray, if possible.
		 * 
		 * @param data The object to return as ByteArray
		 * 
		 * @return The ByteArray or null
		 *
		 */
		public static function toByteArray(data:*):ByteArray
		{
			if (data is Class)
				data = new data();
			
			if (data is ByteArray)
				return data;
			else
				return null;
		}
		
		/**
		 * Returns a object as String, if possible.
		 * 
		 * @param data The object to return as String
		 * @param length The length of the returned String
		 * 
		 * @return The String or null
		 *
		 */
		public static function toString(data:*, length:uint = 0):String
		{
			var ba:ByteArray;
			
			length ||= uint.MAX_VALUE;
			
			if (data is String)
				return String(data).substr(0, length);
			
			ba = toByteArray(data);
			if (ba) {
				ba.position = 0;
				return ba.readUTFBytes(Math.min(ba.bytesAvailable, length));
			}
			
			return null;
		}
	}
}
