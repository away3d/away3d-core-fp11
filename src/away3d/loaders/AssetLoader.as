package away3d.loaders
{
	import away3d.arcane;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.events.ParserEvent;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.misc.AssetLoaderToken;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.misc.SingleFileLoader;
	import away3d.loaders.parsers.ParserBase;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;

	use namespace arcane;
	
	/**
	 * Dispatched when a full resource (including dependencies) finishes loading.
	 * 
	 * @eventType away3d.events.LoaderEvent
	 */
	[Event(name="resourceComplete", type="away3d.events.LoaderEvent")]
	
	/**
	 * Dispatched when a single dependency (which may be the main file of a resource)
	 * finishes loading.
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
	 * Dispatched when a animation asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animationComplete", type="away3d.events.AssetEvent")]
	
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
	 * AssetLoader can load any file format that Away3D supports (or for which a third-party parser
	 * has been plugged in) and it's dependencies. Events are dispatched when assets are encountered
	 * and for when the resource (or it's dependencies) have been loaded.
	 * 
	 * The AssetLoader will not make assets available in any other way than through the dispatched
	 * events. To store assets and make them available at any point from any module in an application,
	 * use the AssetLibrary to load and manage assets.
	 * 
	 * @see away3d.loading.Loader3D
	 * @see away3d.loading.AssetLibrary
	 */
	public class AssetLoader extends EventDispatcher
	{
		private var _context : AssetLoaderContext;
		private var _token : AssetLoaderToken;
		private var _uri : String;
		
		private var _errorHandlers : Vector.<Function>;
		
		private var _loaderStack : Vector.<SingleFileLoader>;
		private var _dependencyStack : Vector.<Vector.<ResourceDependency>>;
		private var _dependencyIndexStack : Vector.<uint>;
		private var _currentLoader : SingleFileLoader;
		private var _currentDependencyIndex : uint;
		private var _currentDependencies : Vector.<ResourceDependency>;
		private var _loadingDependency : ResourceDependency;
		private var _namespace : String;
		
		/**
		 * Create a new ResourceLoadSession object.
		 */
		public function AssetLoader()
		{
			_loaderStack = new Vector.<SingleFileLoader>();
			_dependencyStack = new Vector.<Vector.<ResourceDependency>>();
			_dependencyIndexStack = new Vector.<uint>();
			
			_errorHandlers = new Vector.<Function>();
		}
		
		
		public static function enableParser(parserClass : Class) : void
		{
			SingleFileLoader.enableParser(parserClass);
		}
		
		
		public static function enableParsers(parserClasses : Vector.<Class>) : void
		{
			SingleFileLoader.enableParsers(parserClasses);
		}
		
		/**
		 * Loads a file and (optionally) all of its dependencies.
		 * 
		 * @param req The URLRequest object containing the URL of the file to be loaded.
		 * @param context An optional context object providing additional parameters for loading
		 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
		 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
		 */
		public function load(req : URLRequest, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			if (!_token) {
				_token = new AssetLoaderToken(this);
				
				_uri = req.url = req.url.replace(/\\/g, "/");
				_context = context;
				_namespace = ns;
				_currentDependencies = new Vector.<ResourceDependency>();
				_currentDependencies.push(new ResourceDependency('', req, null, null));
				retrieveNext(parser);
				
				return _token;
			}
			
			// TODO: Throw error (already loading)
			return null;
		}
		
		/**
		 * Loads a resource from already loaded data.
		 * 
		 * @param data The data object containing all resource information.
		 * @param context An optional context object providing additional parameters for loading
		 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
		 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
		 */
		public function loadData(data : *, id : String, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			if (!_token) {
				_token = new AssetLoaderToken(this);
				
				_uri = id;
				_context = context;
				_namespace = ns;
				_currentDependencies = new Vector.<ResourceDependency>();
				_currentDependencies.push(new ResourceDependency(id, null, data, null));
				retrieveNext(parser);
				
				return _token;
			}
			
			// TODO: Throw error (already loading)
			return null;
		}
		
		
		/**
		 * Recursively retrieves the next to-be-loaded and parsed dependency on the stack, or pops the list off the
		 * stack when complete and continues on the top set.
		 * @param parser The parser that will translate the data into a usable resource.
		 */
		private function retrieveNext(parser : ParserBase = null) : void
		{
			// move back up the stack while we're at the end
			while (_currentDependencies && _currentDependencyIndex == _currentDependencies.length) {
				if (_dependencyStack.length > 0) {
					_currentLoader = _loaderStack.pop();
					_currentDependencies = _dependencyStack.pop();
					_currentDependencyIndex = _dependencyIndexStack.pop();
					
					// If this load operation is one that needs to be parsed, and the parsing has
					// not completed yet, resume parsing after having loaded it's dependency queue
					if (_currentLoader.parser && _currentLoader.parser.parsingPaused) {
						// Back to loading the one we thought was complete
						_loadingDependency = _currentDependencies[_currentDependencyIndex-1];
						_currentLoader.parser.resumeParsingAfterDependencies();
						break;
					}
				}
				else _currentDependencies = null;
			}
			
			
			if (_currentDependencies && _currentDependencyIndex<_currentDependencies.length) {
				// Order is extremely important here. If retrieveDependency() finishes synchronously,
				// and currentDependencyIndex hasn't been incremented by that time, we hit infinitely
				// deep recursion (loading the same over and over again.) Hence the temp variable.
				var idx : uint = _currentDependencyIndex;
				_currentDependencyIndex++;
				retrieveDependency(_currentDependencies[idx], parser);
			} 
			else if (_loaderStack.length==0) {
				if (_currentLoader.parser.parsingComplete) {
					// This was the first (base) loader in the stack. Since it has been completed the
					// entire resource must be done.
					dispatchEvent(new LoaderEvent(LoaderEvent.RESOURCE_COMPLETE, _uri));
				}
				else {
					_currentLoader.parser.resumeParsingAfterDependencies();
				}
			}
		}
		
		/**
		 * Retrieves a single dependency.
		 * @param parser The parser that will translate the data into a usable resource.
		 */
		private function retrieveDependency(dependency : ResourceDependency, parser : ParserBase = null) : void
		{
			var data : *;
			var loader : SingleFileLoader;
			
			loader = new SingleFileLoader();
			addEventListeners(loader);
			
			_loadingDependency = dependency;
			
			// Get already loaded (or mapped) data if available
			data = _loadingDependency.data;
			if (_context && _loadingDependency.request && _context.hasDataForUrl(_loadingDependency.request.url))
				data = _context.getDataForUrl(_loadingDependency.request.url);
			
			if (data) {
				if (_loadingDependency.retrieveAsRawData) {
					// No need to parse. The parent parser is expecting this
					// to be raw data so it can be passed directly.
					dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE, _loadingDependency.request.url, true));
					_loadingDependency.setData(data);
					_loadingDependency.resolve();
					
					// Move on to next dependency
					retrieveNext();
				}
				else {
					loader.parseData(data, parser, _loadingDependency.request);
				}
			}
			else {
				// Resolve URL and start loading
				dependency.request.url = resolveDependencyUrl(dependency);
				loader.load(dependency.request, parser, _loadingDependency.retrieveAsRawData);
			}
		}
		
		
		private function joinUrl(base : String, end : String) : String
		{
			if (end.charAt(0)=='/')
				end = end.substr(1);
			
			if (base.length==0)
				return end;
			
			if (base.charAt(base.length-1)=='/')
				base = base.substr(0, base.length-1);
			
			return base.concat('/', end);
		}
		
		private function resolveDependencyUrl(dependency : ResourceDependency) : String
		{
			var scheme_re : RegExp;
			var base : String;
			var url : String = dependency.request.url;
			
			// Has the user re-mapped this URL?
			if (_context && _context.hasMappingForUrl(url))
				return _context.getRemappedUrl(url);
			
			// This is the "base" dependency, i.e. the actual requested asset.
			// We will not try to resolve this since the user can probably be 
			// thrusted to know this URL better than our automatic resolver. :)
			if (url == _uri)
				return url;
			
			// Absolute URL? Check if starts with slash or a URL
			// scheme definition (e.g. ftp://, http://, file://)
			scheme_re = new RegExp(/^[a-zA-Z]{3,4}:\/\//);
			if (url.charAt(0) == '/') {
				if (_context && _context.overrideAbsolutePaths) {
					return joinUrl(_context.dependencyBaseUrl, url);
				}
				else {
					return url;
				}
			}
			else if (scheme_re.test(url)) {
				// If overriding full URLs, get rid of scheme (e.g. "http://")
				// and replace with the dependencyBaseUrl defined by user.
				if (_context && _context.overrideFullURLs) {
					var noscheme_url : String;
					
					noscheme_url = url.replace(scheme_re);
					return joinUrl(_context.dependencyBaseUrl, noscheme_url);
				}
			}
			
			// Since not absolute, just get rid of base file name to find it's
			// folder and then concatenate dynamic URL
			if (_context && _context.dependencyBaseUrl) {
				base = _context.dependencyBaseUrl;
				return joinUrl(base, url);
			}
			else {
				base = _uri.substring(0, _uri.lastIndexOf('/')+1);
				return joinUrl(base, url);
			}
		}
		
		private function retrieveLoaderDependencies(loader : SingleFileLoader) : void
		{
			_loaderStack.push(loader);
			_dependencyStack.push(_currentDependencies);
			_dependencyIndexStack.push(_currentDependencyIndex);
			_currentDependencyIndex = 0;
			_currentDependencies = loader.dependencies;
			retrieveNext();
		}
		
		/**
		 * Called when a single dependency loading failed, and pushes further dependencies onto the stack.
		 * @param event
		 */
		private function onRetrievalFailed(event : LoaderEvent) : void
		{
			var handled : Boolean;
			var isDependency : Boolean = (_dependencyStack.length > 0);
			var loader : SingleFileLoader = SingleFileLoader(event.target);
			
			removeEventListeners(loader);
			
			event = new LoaderEvent(LoaderEvent.LOAD_ERROR, _uri, isDependency, event.message);
			
			if (hasEventListener(LoaderEvent.LOAD_ERROR)) {
				dispatchEvent(event);
				handled = true;
			}
			else {
				// TODO: Consider not doing this even when AssetLoader does
				// have it's own LOAD_ERROR listener
				var i : uint, len : uint = _errorHandlers.length;
				for (i=0; i<len; i++) {
					var handlerFunction : Function = _errorHandlers[i];
					handled ||= handlerFunction(event);
				}
			}
			
			if (handled) {
				if (isDependency && !event.isDefaultPrevented()) {
					_loadingDependency.resolveFailure();
					prepareNextRetrieve(loader, event, false);
				}
				else {
					// Either this was the base file (last left in the stack) or
					// default behavior was prevented by the handlers, and hence
					// there is nothing more to do than clean up and bail.
					dispose();
					return;
				}
			}
			else {
				// Error event was not handled by listeners directly on AssetLoader or
				// on any of the subscribed loaders (in the list of error handlers.)
				throw new Error(event.message);
			}
		}
		
		
		private function onAssetComplete(event : AssetEvent) : void
		{
			// Event is dispatched twice per asset (once as generic ASSET_COMPLETE,
			// and once as type-specific, e.g. MESH_COMPLETE.) Do this only once.
			if (event.type == AssetEvent.ASSET_COMPLETE) {
				
				// Add loaded asset to list of assets retrieved as part
				// of the current dependency. This list will be inspected
				// by the parent parser when dependency is resolved
				if (_loadingDependency)
					_loadingDependency.assets.push(event.asset);
				
				event.asset.resetAssetPath(event.asset.name, _namespace);
			}
			
			dispatchEvent(event.clone());
		}
		
		
		private function onReadyForDependencies(event : ParserEvent) : void
		{
			var loader : SingleFileLoader = SingleFileLoader(event.currentTarget);
			
			if (_context && !_context.includeDependencies) {
				loader.parser.resumeParsingAfterDependencies();
			}
			else {
				retrieveLoaderDependencies(loader);
			}
		}
		
		/**
		 * Called when a single dependency was parsed, and pushes further dependencies onto the stack.
		 * @param event
		 */
		private function onRetrievalComplete(event : LoaderEvent) : void
		{
			var loader : SingleFileLoader = SingleFileLoader(event.target);
			prepareNextRetrieve(loader, event); //prepare next in front of removing listeners to allow any remaining asset events to propagate
			
			removeEventListeners(loader);
		}
		
		/**
		 * Pushes further dependencies onto the stack.
		 * @param event
		 */
		private function prepareNextRetrieve(loader:SingleFileLoader, event : LoaderEvent, resolve:Boolean = true) : void
		{
			// TODO: Don't dispatch this on failure
			dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE, event.url));
			
			_loadingDependency.setData(loader.data);
			if(resolve) _loadingDependency.resolve();
			
			if (_context && !_context.includeDependencies){
				dispatchEvent(new LoaderEvent(LoaderEvent.RESOURCE_COMPLETE, _uri));
			} else{
				retrieveLoaderDependencies(loader);
			}
		}
		
		
		private function addEventListeners(loader : SingleFileLoader) : void
		{
			loader.addEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onRetrievalComplete);
			loader.addEventListener(LoaderEvent.LOAD_ERROR, onRetrievalFailed);
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			loader.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
		}
		
		
		private function removeEventListeners(loader : SingleFileLoader) : void
		{
			loader.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			loader.removeEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onRetrievalComplete);
			loader.removeEventListener(LoaderEvent.LOAD_ERROR, onRetrievalFailed);
			loader.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		}
		
		
		private function dispose() : void
		{
			_currentDependencies = null;
			_loadingDependency = null;
			
			_errorHandlers = null;
			_loaderStack = null;
			_context = null;
			_token = null;
			
			if (_currentLoader) {
				removeEventListeners(_currentLoader);
				_currentLoader = null;
			}
		}
		
		
		/**
		 * @private
		 * This method is used by other loader classes (e.g. Loader3D and AssetLibraryBundle) to
		 * add error event listeners to the AssetLoader instance. This system is used instead of
		 * the regular EventDispatcher system so that the AssetLibrary error handler can be sure
		 * that if hasEventListener() returns true, it's client code that's listening for the
		 * event. Secondly, functions added as error handler through this custom method are 
		 * expected to return a boolean value indicating whether the event was handled (i.e.
		 * whether they in turn had any client code listening for the event.) If no handlers
		 * return true, the AssetLoader knows that the event wasn't handled and will throw an RTE.
		*/
		arcane function addErrorHandler(handler : Function) : void
		{
			if (_errorHandlers.indexOf(handler)<0) {
				_errorHandlers.push(handler);
			}
		}
	}
}

