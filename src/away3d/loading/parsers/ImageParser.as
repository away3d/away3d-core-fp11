package away3d.loading.parsers
{
	import away3d.loading.BitmapDataResource;
	import away3d.loading.IResource;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	
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
		private var _bitmapDataResource : BitmapDataResource;
		
		/**
		 * Creates a new ImageParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
		 */
		public function ImageParser(uri : String, extra : Object)
		{
			super(uri, ParserDataFormat.BINARY, extra);
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension : String) : Boolean
		{
			extension = extension.toLowerCase();
			return extension == "jpg" || extension == "png";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean
		{
			// todo: implement
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function initHandle() : IResource
		{
			_bitmapDataResource = new BitmapDataResource();
			return _bitmapDataResource;
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
			_bitmapDataResource.bitmapData = Bitmap(_loader.content).bitmapData;
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
			_doneParsing = true;
		}
		
	}
}
