package away3d.loaders.parsers
{
	import away3d.arcane;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.events.ParserEvent;
	import away3d.loaders.misc.ResourceDependency;
	
	import flash.utils.ByteArray;
	
	use namespace arcane;

	/**
	 * The AWDParser class is a wrapper for both AWD1Parser and AWD2Parser, and will
	 * find the right concrete parser for an AWD file.
	*/
	public class AWDParser extends ParserBase
	{
		private var _parser : ParserBase;
		
		public function AWDParser()
		{
			super(ParserDataFormat.BINARY);
		}
		
		
		public static function supportsType(suffix : String) : Boolean
		{
			return (suffix.toLowerCase()=='awd');
		}
		
		
		public static function supportsData(data : *) : Boolean
		{
			var ba : ByteArray;
			var str : String;
			
			// Data will be byte array since this parser
			// has data format = BINARY
			ba = ByteArray(data);
			if (AWD2Parser.supportsData(ba))
				return true;
			
			// If not AWD2, convert to string and let
			// AWD1Parser check if data is supported
			str = ba.readUTFBytes(ba.bytesAvailable);
			return AWD1Parser.supportsData(str);
		}
		
		
		
		/**
		 * @inheritDoc
		*/
		public override function get dependencies():Vector.<ResourceDependency>
		{
			return _parser? _parser.dependencies : _dependencies;
		}
		
		
		/**
		 * @private
		 * Delegate to the concrete parser.
		*/
		arcane override function resolveDependency(resourceDependency:ResourceDependency):void
		{
			if (_parser) _parser.resolveDependency(resourceDependency);
		}
		
		
		/**
		 * @private
		 * Delegate to the concrete parser.
		*/
		arcane override function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			if (_parser) _parser.resolveDependencyFailure(resourceDependency);
		}
		
		
		/**
		 * Find the right conrete parser (AWD1Parser or AWD2Parser) and delegate actual
		 * parsing to it.
		*/
		protected override function proceedParsing() : Boolean
		{
			if (!_parser) {
				// Inspect data to find correct parser. AWD2 parser
				// file inspection is the most reliable
				if (AWD2Parser.supportsData(_byteData))
					_parser = new AWD2Parser();
				else
					_parser = new AWD1Parser();
			
				// Listen for events that need to be bubbled
				_parser.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
				_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
				
				// Start parsing using concrete parser
				switch (_parser.dataFormat) {
					case ParserDataFormat.BINARY:
						_parser.parseBytesAsync(_byteData);
						break;
					case ParserDataFormat.PLAIN_TEXT:
						_parser.parseTextAsync(_byteData.readUTFBytes(_byteData.bytesAvailable));
						break;
				}
			}
			
			// Because finishParsing() is overriden, we can stop
			// this parser without any events being dispatched.
			return PARSING_DONE;
		}
		
		
		/**
		 * @private
		 * Overridden to prevent default behavior of dispatching event,
		 * so that this wrapper can stop "parsing" straight away but not
		 * dispatch events until wrapped concrete parser is actually done.
		*/
		protected override function finishParsing() : void
		{
			// Do nothing.
		}
		
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		*/
		private function onReadyForDependencies(ev : ParserEvent) : void
		{
			dispatchEvent(ev.clone());
		}
		
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		*/
		private function onAssetRetrieved(ev : AssetEvent) : void
		{
			dispatchEvent(ev.clone());
		}
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		*/
		private function onParseComplete(ev : ParserEvent) : void
		{
			dispatchEvent(ev.clone());
		}
	}
}