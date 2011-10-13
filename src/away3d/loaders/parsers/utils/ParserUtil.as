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
		
		public static function toString(data : *) : String
		{
			var ba : ByteArray;
			
			if (data is String)
				return data;
			
			ba = toByteArray(data);
			if (ba) {
				ba.position = 0;
				return ba.readUTFBytes(ba.bytesAvailable);
			}
			
			return null;
		}
	}
}