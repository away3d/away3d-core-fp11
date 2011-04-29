package away3d.loading
{
	import away3d.events.AssetEvent;
	import away3d.events.LibraryEvent;
	import away3d.events.LoaderEvent;
	import away3d.loading.misc.SingleResourceLoader;
	import away3d.loading.assets.IAsset;
	import away3d.loading.parsers.ParserBase;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	
	import mx.controls.listClasses.AdvancedListBase;

	public class AssetLibrary extends EventDispatcher
	{
		private static var _instances : Object = {};
			
		private var _loadingSessions : Vector.<AssetLoader>;
		
		private var _assets : Vector.<IAsset>;
		private var _namespaces : Object;
		
		
		public function AssetLibrary(se : SingletonEnforcer)
		{
			_assets = new Vector.<IAsset>;
			_namespaces = {};
			_loadingSessions = new Vector.<AssetLoader>;
		}
		
		
		
		/**
		 * Gets the singleton instance of the ResourceManager.
		 */
		public static function getInstance(key : String = 'default') : AssetLibrary
		{
			if (!_instances.hasOwnProperty(key))
				_instances[key] = new AssetLibrary(new SingletonEnforcer());
			
			return _instances[key];
		}
		
		
		public function load(req : URLRequest, ignoreDependencies : Boolean = false, parser : ParserBase = null, namespace : String = null) : AssetLoader
		{
			return loadResource(req, ignoreDependencies, parser, namespace);
		}
		
		public static function load(req : URLRequest, ignoreDependencies : Boolean = false, parser : ParserBase = null, namespace : String = null) : AssetLoader
		{
			return getInstance().load(req, ignoreDependencies, parser, namespace);
		}
		
		
		
		public function parseData(data : *, ignoreDependencies : Boolean = true, parser : ParserBase = null, namespace : String = null) : AssetLoader
		{
			return parseResource(data, ignoreDependencies, parser, namespace);
		}
		
		public static function parseData(data : *, ignoreDependencies : Boolean = true, parser : ParserBase = null, namespace : String = null) : AssetLoader
		{
			return getInstance().parseData(data, ignoreDependencies, parser, namespace);
		}
		
		
		
		public function getAsset(name : String, namespace : String = null) : IAsset
		{
			var asset : IAsset;
			
			// TODO: Improve this using look-up tables, but make sure
			// they deal with renaming assets
			for each (asset in _assets) {
				if (asset.assetPathEquals(name, namespace))
					return asset;
			}
			
			return null;
		}
		
		public static function getAsset(name : String, namespace : String = null) : IAsset
		{
			return getInstance().getAsset(name, namespace);
		}
		
		
		
		public static function enableParser(parserClass : Class) : void
		{
			SingleResourceLoader.enableParser(parserClass);
		}
		
		public static function enableParsers(parserClasses : Vector.<Class>) : void
		{
			SingleResourceLoader.enableParsers(parserClasses);
		}
		
		
		
		
		public static function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void		{			getInstance().addEventListener(type, listener, useCapture, priority, useWeakReference);		}								public static function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void		{			getInstance().removeEventListener(type, listener,useCapture);		}								public static function hasEventListener(type : String) : Boolean		{			return getInstance().hasEventListener(type);		}								public static function willTrigger(type : String) : Boolean		{			return getInstance().willTrigger(type);		}
		
		
				
		/**
		 * Loads a yet unloaded resource file from the given url.
		 * @param url The url of the file to be loaded.
		 * @param ignoreDependencies Indicates whether or not dependencies should be ignored or loaded.
		 * @param parser An optional parser object that will translate the data into a usable resource.
		 * @return A handle to the retrieved resource.
		 */
		private function loadResource(req : URLRequest, ignoreDependencies : Boolean, parser : ParserBase, namespace : String) : AssetLoader
		{
			var session : AssetLoader = new AssetLoader();
			_loadingSessions.push(session);
			session.addEventListener(AssetEvent.ASSET_RETRIEVED, onAssetRetrieved);
			session.addEventListener(LibraryEvent.RESOURCE_RETRIEVED, onResourceRetrieved);
			session.addEventListener(LibraryEvent.DEPENDENCY_RETRIEVED, onDependencyRetrieved);
			session.addEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
			session.load(req, ignoreDependencies, parser, namespace);
			
			return session;
		}
		
		
		
		/**
		 * Retrieves an unloaded resource parsed from the given data.
		 * @param data The data to be parsed.
		 * @param id The id that will be assigned to the resource. This can later also be used by the getResource method.
		 * @param ignoreDependencies Indicates whether or not dependencies should be ignored or loaded.
		 * @param parser An optional parser object that will translate the data into a usable resource.
		 * @return A handle to the retrieved resource.
		 */
		private function parseResource(data : *, ignoreDependencies : Boolean = true, parser : ParserBase = null, namespace : String = null) : AssetLoader
		{
			var session : AssetLoader = new AssetLoader();
			_loadingSessions.push(session);
			session.addEventListener(AssetEvent.ASSET_RETRIEVED, onAssetRetrieved);
			session.addEventListener(LibraryEvent.RESOURCE_RETRIEVED, onResourceRetrieved);
			session.addEventListener(LibraryEvent.DEPENDENCY_RETRIEVED, onDependencyRetrieved);
			session.parseData(data, '', ignoreDependencies, parser, namespace);
			
			return session;
		}
		
		
		
		/**
		 * Called when a dependency was retrieved.
		 */
		private function onDependencyRetrieved(event : LibraryEvent) : void
		{
			if (hasEventListener(LibraryEvent.DEPENDENCY_RETRIEVED))
				dispatchEvent(event);
		}
		
		/**
		 * Called when a an error occurs during dependency retrieving.
		 */
		private function onDependencyRetrievingError(event : LoaderEvent) : void
		{
			var ext:String = event.url.substring(event.url.length-4, event.url.length).toLowerCase();
			if (!(ext== ".jpg" || ext == ".png") && hasEventListener(LoaderEvent.LOAD_ERROR)){
				dispatchEvent(event);
			}
			else if(hasEventListener(LoaderEvent.LOAD_MAP_ERROR)){
				var le:LoaderEvent = new LoaderEvent(LoaderEvent.LOAD_MAP_ERROR, event.url, event.message);
				dispatchEvent(le);
			}
			else throw new Error(event.message);
		}
		
		private function onAssetRetrieved(event : AssetEvent) : void
		{
			_assets.push(event.asset);
			event.asset.addEventListener(AssetEvent.ASSET_RENAME, onAssetRename);
			dispatchEvent(event.clone());
		}
		
		/**
		 * Called when the resource and all of its dependencies was retrieved.
		 */
		private function onResourceRetrieved(event : LibraryEvent) : void
		{
			var session : AssetLoader = AssetLoader(event.target);
			
			var index : int = _loadingSessions.indexOf(session);
			session.removeEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
			session.removeEventListener(LibraryEvent.RESOURCE_RETRIEVED, onResourceRetrieved);
			session.removeEventListener(LibraryEvent.DEPENDENCY_RETRIEVED, onDependencyRetrieved);
			session.removeEventListener(LibraryEvent.DEPENDENCY_ERROR, onDependencyRetrievingError);
			session.removeEventListener(AssetEvent.ASSET_RETRIEVED, onAssetRetrieved);
			
			_loadingSessions.splice(index, 1);
			
			/*
			if(session.handle){
				dispatchEvent(event);
			}else{
				onResourceError((session is IResource)? IResource(session) : null);
			}
			*/
			
			dispatchEvent(event.clone());
		}
		
		/**
		 * Called when unespected error occurs
		 */
		private function onResourceError() : void
		{
			var msg:String = "Unexpected parser error";
			if(hasEventListener(LibraryEvent.DEPENDENCY_ERROR)){
				var re:LibraryEvent = new LibraryEvent(LibraryEvent.DEPENDENCY_ERROR, "");
				dispatchEvent(re);
			} else{
				throw new Error(msg);
			}
		}
		
		
		private function onAssetRename(ev : AssetEvent) : void
		{
			//trace('renaming', ev.asset.assetFullPath);
		}
	}
}

// singleton enforcer
class SingletonEnforcer
{
}
