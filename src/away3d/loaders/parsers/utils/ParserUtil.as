package away3d.loaders.parsers.utils
{
	import flash.utils.ByteArray;

	public class ParserUtil
	{
		public static function toByteArray(data : *) : ByteArray
		{
			if (data is Class)
				data = new data();
			
			if (data is ByteArray)
				return data;
			else return null;
		}
		
		public static function toString(data : *, length : uint = 0) : String
		{
			var ba : ByteArray;
			
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