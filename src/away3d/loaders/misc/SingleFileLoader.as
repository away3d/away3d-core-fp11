package away3d.loaders.misc
{
	import away3d.arcane;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.events.ParserEvent;
	import away3d.loaders.parsers.ImageParser;
	import away3d.loaders.parsers.ParserBase;
	import away3d.loaders.parsers.ParserDataFormat;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;

	use namespace arcane;
	
	/**
	 * Dispatched when the dependency that this single-file loader was loading complets.
	 * 
	 * @eventType away3d.events.LoaderEvent
	 */
	[Event(name="dependencyComplete", type="away3d.events.LoaderEvent")]
	
	/**
	 * Dispatched when an error occurs during loading. 
	 * 
	 * @eventType away3d.events.LoaderEvent
	 */
	[Event(name="loadError", type="away3d.events.LoaderEvent")]
	
	/**
	 * Dispatched when any asset finishes parsing. Also see specific events for each
	 * individual asset type (meshes, materials et c.)
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="assetComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a geometry asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="geometryComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a skeleton asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="skeletonComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a skeleton pose asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="skeletonPoseComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a container asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="containerComplete", type="away3d.events.AssetEvent")]
		
	/**
	 * Dispatched when an animation set has been constructed from a group of animation state resources.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animationSetComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when an animation state has been constructed from a group of animation node resources.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animationStateComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when an animation node has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animationNodeComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when an animation state transition has been constructed from a group of animation node resources.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="stateTransitionComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a texture asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="textureComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a material asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="materialComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a animator asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animatorComplete", type="away3d.events.AssetEvent")]

	/**
	 * Dispatched when an image assets dimensions are not a power of 2
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="textureSizeError", type="away3d.events.AssetEvent")]
	
	
	/**
	 * The SingleFileLoader is used to load a single file, as part of a resource.
	 *
	 * While SingleFileLoader can be used directly, e.g. to create a third-party asset 
	 * management system, it's recommended to use any of the classes Loader3D, AssetLoader
	 * and AssetLibrary instead in most cases.
	 *
	 * @see away3d.loading.Loader3D
	 * @see away3d.loading.AssetLoader
	 * @see away3d.loading.AssetLibrary
	 */
	public class SingleFileLoader extends EventDispatcher
	{
		private var _parser : ParserBase;
		private var _req : URLRequest;
		private var _fileExtension : String;
		private var _fileName : String;
		private var _loadAsRawData : Boolean;
		private var _data : *;
		
		// Image parser only parser that is added by default, to save file size.
		private static var _parsers : Vector.<Class> = Vector.<Class>([ ImageParser ]);
		
		
		/**
		 * Creates a new SingleFileLoader object.
		 */
		public function SingleFileLoader()
		{
		}
		
		
		public function get url() : String
		{
			return _req? _req.url : '';
		}
		
		
		public function get data() : *
		{
			return _data;
		}
		
		
		public function get loadAsRawData() : Boolean
		{
			return _loadAsRawData;
		}
		
		
		public static function enableParser(parser : Class) : void
		{
			if (_parsers.indexOf(parser) < 0)
				_parsers.push(parser);
		}
		
		
		public static function enableParsers(parsers : Vector.<Class>) : void
		{
			var pc : Class;
			for each (pc in parsers) {
				enableParser(pc);
			}
		}
		
		
		/**
		 * Load a resource from a file.
		 * 
		 * @param urlRequest The URLRequest object containing the URL of the object to be loaded.
		 * @param parser An optional parser object that will translate the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
		 */
		public function load(urlRequest : URLRequest, parser : ParserBase = null, loadAsRawData : Boolean = false) : void
		{
			var urlLoader : URLLoader;
			var dataFormat : String;
			
			_loadAsRawData = loadAsRawData;
			_req = urlRequest;
			decomposeFilename(_req.url);
			
			if (_loadAsRawData) {
				// Always use binary for raw data loading
				dataFormat = URLLoaderDataFormat.BINARY;
			}
			else {
				if (parser) _parser = parser;
				
				if (!_parser) _parser = getParserFromSuffix();
				
				if (_parser) {
					switch (_parser.dataFormat) {
						case ParserDataFormat.BINARY:
							dataFormat = URLLoaderDataFormat.BINARY;
							break;
						case ParserDataFormat.PLAIN_TEXT:
							dataFormat = URLLoaderDataFormat.TEXT;
							break;
					}
					
				} else {
					// Always use BINARY for unknown file formats. The thorough
					// file type check will determine format after load, and if
					// binary, a text load will have broken the file data.
					dataFormat = URLLoaderDataFormat.BINARY;
				}
			}
			
			urlLoader = new URLLoader();
			urlLoader.dataFormat = dataFormat;
			urlLoader.addEventListener(Event.COMPLETE, handleUrlLoaderComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);
			urlLoader.load(urlRequest);
		}
		
		/**
		 * Loads a resource from already loaded data.
		 * @param data The data to be parsed. Depending on the parser type, this can be a ByteArray, String or XML.
		 * @param uri The identifier (url or id) of the object to be loaded, mainly used for resource management.
		 * @param parser An optional parser object that will translate the data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
		 */
		public function parseData(data : *, parser : ParserBase = null, req : URLRequest = null) : void
		{
			if (data is Class)
				data = new data();
			
			if (parser)
				_parser = parser;
			
			_req = req;
			
			parse(data);
		}
		
		/**
		 * A reference to the parser that will translate the loaded data into a usable resource.
		 */
		public function get parser() : ParserBase
		{
			return _parser;
		}
		
		/**
		 * A list of dependencies that need to be loaded and resolved for the loaded object.
		 */
		public function get dependencies() : Vector.<ResourceDependency>
		{
			return _parser? _parser.dependencies : new Vector.<ResourceDependency>;
		}
		
		/**
		 * Splits a url string into base and extension.
		 * @param url The url to be decomposed.
		 */
		private function decomposeFilename(url : String) : void
		{
			
			// Get rid of query string if any and extract suffix
			var base : String = (url.indexOf('?')>0)? url.split('?')[0] : url;
			var i : int = base.lastIndexOf('.');
			_fileExtension = base.substr(i + 1).toLowerCase();
			_fileName = base.substr(0, i);
		}
		
		/**
		 * Guesses the parser to be used based on the file extension.
		 * @return An instance of the guessed parser.
		 */
		private function getParserFromSuffix() : ParserBase
		{
			var len : uint = _parsers.length;
			
			// go in reverse order to allow application override of default parser added in Away3D proper
			for (var i : int = len-1; i >= 0; i--)
				if (_parsers[i].supportsType(_fileExtension)) return new _parsers[i]();
			
			return null;
		}
		
		/**
		 * Guesses the parser to be used based on the file contents.
		 * @param data The data to be parsed.
		 * @param uri The url or id of the object to be parsed.
		 * @return An instance of the guessed parser.
		 */
		private function getParserFromData(data : *) : ParserBase
		{
			var len : uint = _parsers.length;
			
			// go in reverse order to allow application override of default parser added in Away3D proper
			for (var i : int = len-1; i >= 0; i--)
				if (_parsers[i].supportsData(data))
					return new _parsers[i]();
			
			return null;
		}
		
		/**
		 * Cleanups
		 */
		private function removeListeners(urlLoader:URLLoader) : void
		{
			urlLoader.removeEventListener(Event.COMPLETE, handleUrlLoaderComplete);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);
		}
		
		/**
		 * Called when loading of a file has failed
		 */
		private function handleUrlLoaderError(event:IOErrorEvent) : void
		{
			var urlLoader : URLLoader = URLLoader(event.currentTarget);
			removeListeners(urlLoader);
			
			if(hasEventListener(LoaderEvent.LOAD_ERROR))
				dispatchEvent(new LoaderEvent(LoaderEvent.LOAD_ERROR, _req.url, true, event.text));
		}
		
		/**
		 * Called when loading of a file is complete
		 */
		private function handleUrlLoaderComplete(event : Event) : void
		{
			var urlLoader : URLLoader = URLLoader(event.currentTarget);
			removeListeners(urlLoader);
			
			_data = urlLoader.data;
			
			if (_loadAsRawData) {
				// No need to parse this data, which should be returned as is
				dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE));
			}
			else {
				parse(_data);
			}
		}
		
		/**
		 * Initiates parsing of the loaded data.
		 * @param data The data to be parsed.
		 */
		private function parse(data : *) : void
		{
			// If no parser has been defined, try to find one by letting
			// all plugged in parsers inspect the actual data.
			if (!_parser)
				_parser = getParserFromData(data);
			
			if(_parser){
				_parser.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
				_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
				_parser.addEventListener(AssetEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
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
				
				if (_req && _req.url)
					_parser._fileName = _req.url;
				
				_parser.parseAsync(data);
			} else{
				var msg:String = "No parser defined. To enable all parsers for auto-detection, use Parsers.enableAllBundled()";
				if(hasEventListener(LoaderEvent.LOAD_ERROR)){
					this.dispatchEvent(new LoaderEvent(LoaderEvent.LOAD_ERROR, "", true, msg) );
				} else{
					throw new Error(msg);
				}
			}
		}
		
		
		private function onReadyForDependencies(event : ParserEvent) : void
		{
			dispatchEvent(event.clone());
		}
		
		private function onAssetComplete(event : AssetEvent) : void
		{
			this.dispatchEvent(event.clone());
		}

		private function onTextureSizeError(event : AssetEvent) : void
		{
			this.dispatchEvent(event.clone());
		}
		
		/**
		 * Called when parsing is complete.
		 */
		private function onParseComplete(event : ParserEvent) : void
		{
			this.dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE, this.url));//dispatch in front of removing listeners to allow any remaining asset events to propagate
			
			_parser.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			_parser.removeEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
			_parser.removeEventListener(AssetEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
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
		}
	}
}

