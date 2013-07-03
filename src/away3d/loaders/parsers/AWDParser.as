package away3d.loaders.parsers
{
	import away3d.library.assets.IAsset;
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
		private var _parser:ParserBase;
		
		public function AWDParser()
		{
			super(ParserDataFormat.BINARY);
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(suffix:String):Boolean
		{
			return (suffix.toLowerCase() == 'awd');
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:*):Boolean
		{
			return (AWD1Parser.supportsData(data) || AWD2Parser.supportsData(data));
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
		 * @inheritDoc
		 */
		public override function get parsingPaused():Boolean
		{
			return _parser? _parser.parsingPaused : false;
		}
		
		/**
		 * @private
		 * Delegate to the concrete parser.
		 */
		arcane override function resolveDependency(resourceDependency:ResourceDependency):void
		{
			if (_parser)
				_parser.resolveDependency(resourceDependency);
		}
		
		/**
		 * @private
		 * Delegate to the concrete parser.
		 */
		arcane override function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			if (_parser)
				_parser.resolveDependencyFailure(resourceDependency);
		}
		
		/**
		 * @private
		 * Delagate to the concrete parser.
		 */
		arcane override function resolveDependencyName(resourceDependency:ResourceDependency, asset:IAsset):String
		{
			if (_parser)
				return _parser.resolveDependencyName(resourceDependency, asset);
			return asset.name;
		}
		
		arcane override function resumeParsingAfterDependencies():void
		{
			if (_parser)
				_parser.resumeParsingAfterDependencies();
		}
		
		/**
		 * Find the right conrete parser (AWD1Parser or AWD2Parser) and delegate actual
		 * parsing to it.
		 */
		protected override function proceedParsing():Boolean
		{
			if (!_parser) {
				// Inspect data to find correct parser. AWD2 parser
				// file inspection is the most reliable
				if (AWD2Parser.supportsData(_data))
					_parser = new AWD2Parser();
				else
					_parser = new AWD1Parser();
				_parser.materialMode = materialMode;
				// Listen for events that need to be bubbled
				_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
				_parser.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
				_parser.addEventListener(ParserEvent.PARSE_ERROR, onParseError);
				_parser.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
				_parser.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
				
				_parser.parseAsync(_data);
			}
			
			// Return MORE_TO_PARSE while delegate parser is working. Once the delegate
			// finishes parsing, this dummy parser instance will be stopped as well as
			// a result of the delegate's PARSE_COMPLETE event (onParseComplete).
			return MORE_TO_PARSE;
		}
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		 */
		private function onParseError(ev:ParserEvent):void
		{
			dispatchEvent(ev.clone());
		}
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		 */
		private function onReadyForDependencies(ev:ParserEvent):void
		{
			dispatchEvent(ev.clone());
		}
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		 */
		private function onAssetComplete(ev:AssetEvent):void
		{
			dispatchEvent(ev.clone());
		}
		
		/**
		 * @private
		 * Just bubble events from concrete parser.
		 */
		private function onParseComplete(ev:ParserEvent):void
		{
			_parser.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			_parser.removeEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
			_parser.removeEventListener(ParserEvent.PARSE_ERROR, onParseError);
			_parser.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			_parser.removeEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			finishParsing();
		}
	}
}

