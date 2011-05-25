package away3d.loaders.parsers

{

	import away3d.library.assets.BitmapDataAsset;

	

	import flash.display.Bitmap;

	import flash.display.Loader;

	import flash.events.Event;

	import flash.utils.ByteArray;
	

	/**

	 * ImageParser provides a "parser" for natively supported image types (jpg, png). While it simply loads bytes into

	 * a loader object, it wraps it in a BitmapDataResource so resource management can happen consistently without

	 * exception cases.

	 */

	public class ImageParser extends ParserBase

	{

		private var _startedParsing : Boolean;

		private var _doneParsing : Boolean;

		private var _loader : Loader;

		

		/**

		 * Creates a new ImageParser object.

		 * @param uri The url or id of the data or file to be parsed.

		 * @param extra The holder for extra contextual data that the parser might need.

		 */

		public function ImageParser()

		{

			super(ParserDataFormat.BINARY);

		}

		

		/**

		 * Indicates whether or not a given file extension is supported by the parser.

		 * @param extension The file extension of a potential file to be parsed.

		 * @return Whether or not the given file type is supported.

		 */

		public static function supportsType(extension : String) : Boolean

		{

			extension = extension.toLowerCase();

			return extension == "jpg" || extension == "jpeg" || extension == "png" || extension == "gif" || extension == "bmp";

		}

		

		/**

		 * Tests whether a data block can be parsed by the parser.

		 * @param data The data block to potentially be parsed.

		 * @return Whether or not the given data is supported.

		 */

		public static function supportsData(data : *) : Boolean

		{

			var ba : ByteArray;

			

			ba = ByteArray(data);

			

			ba.position = 0;

			if (ba.readUnsignedShort() == 0xffd8)

				return true; // JPEG, maybe check for "JFIF" as well?

			

			ba.position = 0;

			if (ba.readShort() == 0x424D)

				return true; // BMP 

			

			ba.position = 1;

			if (ba.readUTFBytes(3) == 'PNG')

				return true;

			

			ba.position = 0;

			if (ba.readUTFBytes(3) == 'GIF' && ba.readShort() == 0x3839 && ba.readByte() == 0x61)

				return true;

			

			return false;

		}

		

		

		/**

		 * @inheritDoc

		 */

		protected override function proceedParsing() : Boolean

		{

			if (!_startedParsing) {

				_loader = new Loader();

				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);

				_loader.loadBytes(_byteData);

				_startedParsing = true;

			}

			

			return _doneParsing;

		}

		

		/**

		 * Called when "loading" is complete.

		 */

		private function onLoadComplete(event : Event) : void

		{
			var asset : BitmapDataAsset = new BitmapDataAsset(Bitmap(_loader.content).bitmapData);

			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);

			_doneParsing = true;

			

			finalizeAsset(asset, 'bitmap');

		}

		

	}

}


