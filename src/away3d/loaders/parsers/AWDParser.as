package away3d.loaders.parsers
{
	import away3d.arcane;
	import away3d.events.AssetEvent;
	import away3d.events.ParserEvent;
	import away3d.loaders.misc.ResourceDependency;
	
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
			return (AWD1Parser.supportsData(data) || AWD2Parser.supportsData(data));
		}
		
		
		
		/**
		 * @inheritDoc
		*/
		public override function get dependencies():Vector.<ResourceDependency>
		{
			return _parser? _parser.dependencies : super.dependencies;
		}
		
		
		/**
		 * @inheritDoc
		*/
		public override function get parsingComplete():Boolean
		{
			return _parser? _parser.parsingComplete : false;
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
		
		
		arcane override function resumeParsingAfterDependencies():void
		{
			if (_parser) _parser.resumeParsingAfterDependencies();
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
				if (AWD2Parser.supportsData(_data))
					_parser = new AWD2Parser();
				else
					_parser = new AWD1Parser();
			
				// Listen for events that need to be bubbled
				_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
				_parser.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
				_parser.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
				
				_parser.parseAsync(_data);
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
		private function onAssetComplete(ev : AssetEvent) : void
		{
			dispatchEvent(ev.clone());
		}
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		*/
		private function onParseComplete(ev : ParserEvent) : void
		{
			_parser.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			_parser.removeEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
			_parser.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			dispatchEvent(ev.clone());
		}
	}
}

