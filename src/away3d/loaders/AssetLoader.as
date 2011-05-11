package away3d.loaders
{
	import away3d.arcane;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.misc.AssetLoaderToken;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.misc.SingleFileLoader;
	import away3d.loaders.parsers.ParserBase;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	
	use namespace arcane;
	
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
		private var _uri : String;
		
		private var _dependencyStack : Vector.<Vector.<ResourceDependency>>;
		private var _dependencyIndexStack : Vector.<uint>;
		private var _currentDependencyIndex : uint;
		private var _currentDependencies : Vector.<ResourceDependency>;
		private var _loadingDependency : ResourceDependency;
		private var _namespace : String;
		
		/**
		 * Create a new ResourceLoadSession object.
		 */
		public function AssetLoader()
		{
			_dependencyStack = new Vector.<Vector.<ResourceDependency>>();
			_dependencyIndexStack = new Vector.<uint>();
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
		 */
		public function load(req : URLRequest, parser : ParserBase = null, context : AssetLoaderContext = null, namespace : String = null) : AssetLoaderToken
		{
			var token : AssetLoaderToken = new AssetLoaderToken(this);
			
			_uri = req.url = req.url.replace(/\\/g, "/");
			_context = context;
			_namespace = namespace;
			_currentDependencies = new Vector.<ResourceDependency>();
			_currentDependencies.push(new ResourceDependency('', req, null, null));
			retrieveNext(parser);
			
			return token;
		}
		
		/**
		 * Loads a resource from already loaded data.
		 */
		public function parseData(data : *, id : String, parser : ParserBase = null, context : AssetLoaderContext = null, namespace : String = null) : AssetLoaderToken
		{
			var token : AssetLoaderToken = new AssetLoaderToken(this);
			
			_uri = id;
			_context = context;
			_namespace = namespace;
			_currentDependencies = new Vector.<ResourceDependency>();
			_currentDependencies.push(new ResourceDependency(id, null, data, null));
			retrieveNext(parser);
			
			return token;
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
					_currentDependencies = _dependencyStack.pop();
					_currentDependencyIndex = _dependencyIndexStack.pop();
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
			} else {
				dispatchEvent(new LoaderEvent(LoaderEvent.RESOURCE_COMPLETE, _uri));
			}
		}
		
		/**
		 * Retrieves a single dependency.
		 * @param parser The parser that will translate the data into a usable resource.
		 */
		private function retrieveDependency(dependency : ResourceDependency, parser : ParserBase = null) : void
		{
			var loader : SingleFileLoader = new SingleFileLoader();
			loader.addEventListener(LoaderEvent.DATA_LOADED, onRetrievalComplete);
			loader.addEventListener(LoaderEvent.LOAD_ERROR, onRetrievalFailed);
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
			_loadingDependency = dependency;

			if (_loadingDependency.data) {
				loader.parseData(_loadingDependency.data, parser);
			}
			else if (_context && _context.hasDataForUrl(_loadingDependency.request.url)) {
				loader.parseData(_context.getDataForUrl(_loadingDependency.request.url));
			}
			else {
				// Resolve URL and start loading
				dependency.request.url = resolveDependencyUrl(dependency);
				loader.load(dependency.request, parser);
			}
		}
		
		
		private function resolveDependencyUrl(dependency : ResourceDependency) : String
		{
			var abs_re : RegExp;
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
			abs_re = new RegExp(/^[a-zA-Z]{3,4}:\/\//);
			if (url.charAt(0)=='/' || abs_re.test(url))
				return url;
			
			// Since not absolute, just get rid of base file name to find it's
			// folder and then concatenate dynamic URL
			if (_context && _context.dependencyBaseUrl) {
				base = _context.dependencyBaseUrl;
				return base.charAt(base.length-1)=='/'? 
					base.concat(url) : base.concat('/', url);
			}
			else {
				base = _uri.substring(0, _uri.lastIndexOf('/')+1);
				return base.concat(url);
			}
		}
		
		/**
		 * Called when a single dependency loading failed, and pushes further dependencies onto the stack.
		 * @param event
		 */
		private function onRetrievalFailed(event : LoaderEvent) : void
		{
			var loader : SingleFileLoader = SingleFileLoader(event.target);
			loader.removeEventListener(LoaderEvent.DATA_LOADED, onRetrievalComplete);
			loader.removeEventListener(LoaderEvent.LOAD_ERROR, onRetrievalFailed);
			loader.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
			
			if(hasEventListener(LoaderEvent.LOAD_ERROR)){
				dispatchEvent(new LoaderEvent(LoaderEvent.LOAD_ERROR, loader.url, event.message));
			} else{
				trace("Unable to load "+loader.url);
			}
			
			// TODO: Investigate this. Why is this done?
			var ext:String = loader.url.substring(loader.url.length-4, loader.url.length).toLowerCase();
			if(ext == ".mtl" || ext ==".jpg" || ext ==".png"){
				_loadingDependency.resolveFailure();
				prepareNextRetrieve(loader, event, false);
			}
		}
		
		
		private function onAssetRetrieved(event : AssetEvent) : void
		{
			// Add loaded asset to list of assets retrieved as part
			// of the current dependency. This list will be inspected
			// by the parent parser when dependency is resolved
			if (_loadingDependency)
				_loadingDependency.assets.push(event.asset);
			
			event.asset.resetAssetPath(event.asset.name, _namespace);
			dispatchEvent(event.clone());
		}
		
		/**
		 * Called when a single dependency was parsed, and pushes further dependencies onto the stack.
		 * @param event
		 */
		private function onRetrievalComplete(event : LoaderEvent) : void
		{
			var loader : SingleFileLoader = SingleFileLoader(event.target);
			loader.removeEventListener(LoaderEvent.DATA_LOADED, onRetrievalComplete);
			loader.removeEventListener(LoaderEvent.LOAD_ERROR, onRetrievalFailed);
			loader.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
			prepareNextRetrieve(loader, event);
		}
		
		/**
		 * Pushes further dependencies onto the stack.
		 * @param event
		 */
		private function prepareNextRetrieve(loader:SingleFileLoader, event : LoaderEvent, resolve:Boolean = true) : void
		{
			dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE, event.url));
			
			if(resolve) _loadingDependency.resolve();
			
			if (_context && !_context.includeDependencies){
				dispatchEvent(new LoaderEvent(LoaderEvent.RESOURCE_COMPLETE, _uri));
			} else{
				_dependencyStack.push(_currentDependencies);
				_dependencyIndexStack.push(_currentDependencyIndex);
				_currentDependencyIndex = 0;
				_currentDependencies = loader.dependencies;
				retrieveNext();
			}
			
		}
	}
}

