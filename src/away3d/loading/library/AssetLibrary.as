package away3d.loading.library
{
	import away3d.events.AssetPathEvent;
	import away3d.events.LoaderEvent;
	import away3d.events.ResourceEvent;
	import away3d.loading.AssetLoader;
	import away3d.loading.assets.IAsset;
	import away3d.loading.parsers.ParserBase;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	
	import mx.controls.listClasses.AdvancedListBase;

	public class AssetLibrary extends EventDispatcher
	{
		private static var _instances : Object = {};
			
		private var _loadingSessions : Vector.<ResourceLoadSession>;
		
		private var _assets : Vector.<IAsset>;
		private var _namespaces : Object;
		
		
		public function AssetLibrary(se : SingletonEnforcer)
		{
			_assets = new Vector.<IAsset>;
			_namespaces = {};
			_loadingSessions = new Vector.<ResourceLoadSession>;
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
		
		
		public function load(req : URLRequest, ignoreDependencies : Boolean = false, parser : ParserBase = null, namespace : String = null) : ResourceLoadSession
		{
			return loadResource(req, ignoreDependencies, parser, namespace);
		}
		
		public static function load(req : URLRequest, ignoreDependencies : Boolean = false, parser : ParserBase = null, namespace : String = null) : ResourceLoadSession
		{
			return getInstance().load(req, ignoreDependencies, parser, namespace);
		}
		
		
		
		public function parseData(data : *, ignoreDependencies : Boolean = true, parser : ParserBase = null, namespace : String = null) : ResourceLoadSession
		{
			return parseResource(data, ignoreDependencies, parser, namespace);
		}
		
		public static function parseData(data : *, ignoreDependencies : Boolean = true, parser : ParserBase = null, namespace : String = null) : ResourceLoadSession
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
			AssetLoader.enableParser(parserClass);
		}
		
		public static function enableParsers(parserClasses : Vector.<Class>) : void
		{
			AssetLoader.enableParsers(parserClasses);
		}
		
		
		
		
		public static function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void		{			getInstance().addEventListener(type, listener, useCapture, priority, useWeakReference);		}								public static function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void		{			getInstance().removeEventListener(type, listener,useCapture);		}								public static function hasEventListener(type : String) : Boolean		{			return getInstance().hasEventListener(type);		}								public static function willTrigger(type : String) : Boolean		{			return getInstance().willTrigger(type);		}
		
		
				
		/**
		 * Loads a yet unloaded resource file from the given url.
		 * @param url The url of the file to be loaded.
		 * @param ignoreDependencies Indicates whether or not dependencies should be ignored or loaded.
		 * @param parser An optional parser object that will translate the data into a usable resource.
		 * @return A handle to the retrieved resource.
		 */
		private function loadResource(req : URLRequest, ignoreDependencies : Boolean, parser : ParserBase, namespace : String) : ResourceLoadSession
		{
			var session : ResourceLoadSession = new ResourceLoadSession();
			_loadingSessions.push(session);
			session.addEventListener(ResourceEvent.ASSET_RETRIEVED, onAssetRetrieved);
			session.addEventListener(ResourceEvent.RESOURCE_RETRIEVED, onResourceRetrieved);
			session.addEventListener(ResourceEvent.DEPENDENCY_RETRIEVED, onDependencyRetrieved);
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
		private function parseResource(data : *, ignoreDependencies : Boolean = true, parser : ParserBase = null, ns : String = null) : ResourceLoadSession
		{
			var session : ResourceLoadSession = new ResourceLoadSession();
			_loadingSessions.push(session);
			session.addEventListener(ResourceEvent.ASSET_RETRIEVED, onAssetRetrieved);
			session.addEventListener(ResourceEvent.RESOURCE_RETRIEVED, onResourceRetrieved);
			session.addEventListener(ResourceEvent.DEPENDENCY_RETRIEVED, onDependencyRetrieved);
			session.parse(data, ns, ignoreDependencies, parser);
			
			return session;
		}
		
		
		
		/**
		 * Called when a dependency was retrieved.
		 */
		private function onDependencyRetrieved(event : ResourceEvent) : void
		{
			if (hasEventListener(ResourceEvent.DEPENDENCY_RETRIEVED))
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
		
		private function onAssetRetrieved(event : ResourceEvent) : void
		{
			_assets.push(event.asset);
			event.asset.addEventListener(AssetPathEvent.ASSET_RENAME, onAssetRename);
			dispatchEvent(event.clone());
		}
		
		/**
		 * Called when the resource and all of its dependencies was retrieved.
		 */
		private function onResourceRetrieved(event : ResourceEvent) : void
		{
			var session : ResourceLoadSession = ResourceLoadSession(event.target);
			
			var index : int = _loadingSessions.indexOf(session);
			session.removeEventListener(ResourceEvent.RESOURCE_RETRIEVED, onResourceRetrieved);
			session.removeEventListener(ResourceEvent.DEPENDENCY_RETRIEVED, onDependencyRetrieved);
			session.removeEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
			session.removeEventListener(ResourceEvent.ASSET_RETRIEVED, onAssetRetrieved);
			session.removeEventListener(ResourceEvent.DEPENDENCY_ERROR, onDependencyRetrievingError);
			
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
			if(hasEventListener(ResourceEvent.DEPENDENCY_ERROR)){
				var re:ResourceEvent = new ResourceEvent(ResourceEvent.DEPENDENCY_ERROR, null, "");
				dispatchEvent(re);
			} else{
				throw new Error(msg);
			}
		}
		
		
		private function onAssetRename(ev : AssetPathEvent) : void
		{
			//trace('renaming', ev.asset.assetFullPath);
		}
	}
}

// singleton enforcer
class SingletonEnforcer
{
}
