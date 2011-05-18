package away3d.library
{
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	import away3d.library.strategies.ErrorNamingStrategy;
	import away3d.library.strategies.IgnoreNamingStrategy;
	import away3d.library.strategies.NamingStrategyBase;
	import away3d.library.strategies.NumSuffixNamingStrategy;
	import away3d.loaders.AssetLoader;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.misc.AssetLoaderToken;
	import away3d.loaders.misc.SingleFileLoader;
	import away3d.loaders.parsers.ParserBase;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;

	public class AssetLibrary extends EventDispatcher
	{
		private static var _instances : Object = {};
			
		private var _loadingSessions : Vector.<AssetLoader>;
		
		private var _strategy : NamingStrategyBase;
		private var _strategyPreference : String;
		
		private var _assets : Vector.<IAsset>;
		private var _assetDictionary : Object;
		private var _assetDictDirty : Boolean;
		
		
		public static const IGNORE_CONFLICTS : NamingStrategyBase = new IgnoreNamingStrategy();
		public static const NUM_SUFFIX : NamingStrategyBase = new NumSuffixNamingStrategy();
		public static const THROW_ERROR : NamingStrategyBase = new ErrorNamingStrategy();
		
		
		public function AssetLibrary(se : SingletonEnforcer)
		{
			_assets = new Vector.<IAsset>;
			_assetDictionary = {};
			_loadingSessions = new Vector.<AssetLoader>;
			
			_strategy = NUM_SUFFIX.create();
			_strategyPreference = NamingStrategyBase.PREFER_NEW;
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
		
		
		public function get namingStrategy() : NamingStrategyBase
		{
			return _strategy;
		}
		public function set namingStrategy(val : NamingStrategyBase) : void
		{
			if (!val)
				throw new Error('namingStrategy must not be null. To ignore naming, use AssetLibrary.IGNORE');
			
			_strategy = val.create();
		}
		
		
		public static function get namingStrategy() : NamingStrategyBase
		{
			return getInstance().namingStrategy;
		}
		public static function set namingStrategy(val : NamingStrategyBase) : void
		{
			getInstance().namingStrategy = val;
		}
		
		
		public function get namingStrategyPreference() : String
		{
			return _strategyPreference;
		}
		public function set namingStrategyPreference(val : String) : void
		{
			_strategyPreference = val;
		}
		
		
		public static function get namingStrategyPreference() : String
		{
			return getInstance().namingStrategyPreference;
		}
		public static function set namingStrategyPreference(val : String) : void
		{
			getInstance().namingStrategyPreference = val;
		}
		
		
		public function load(req : URLRequest, parser : ParserBase = null, context : AssetLoaderContext = null, ns : String = null) : AssetLoaderToken
		{
			return loadResource(req, parser, context, ns);
		}
		
		public static function load(req : URLRequest, parser : ParserBase = null, context : AssetLoaderContext = null, ns : String = null) : AssetLoaderToken
		{
			return getInstance().load(req, parser, context, ns);
		}
		
		
		
		public function parseData(data : *, parser : ParserBase = null, context : AssetLoaderContext = null, ns : String = null) : AssetLoaderToken
		{
			return parseResource(data, parser, context, ns);
		}
		
		public static function parseData(data : *, parser : ParserBase = null, context : AssetLoaderContext = null, ns : String = null) : AssetLoaderToken
		{
			return getInstance().parseData(data, parser, context, ns);
		}
		
		
		
		public function getAsset(name : String, ns : String = null) : IAsset
		{
			var asset : IAsset;
			
			if (_assetDictDirty)
				rehashAssetDict();
			
			ns ||= NamedAssetBase.DEFAULT_NAMESPACE;
			if (!_assetDictionary.hasOwnProperty(ns))
				return null;
			
			return _assetDictionary[ns][name];
		}
		
		public static function getAsset(name : String, ns : String = null) : IAsset
		{
			return getInstance().getAsset(name, ns);
		}
		
		
		
		public static function enableParser(parserClass : Class) : void
		{
			SingleFileLoader.enableParser(parserClass);
		}
		
		public static function enableParsers(parserClasses : Vector.<Class>) : void
		{
			SingleFileLoader.enableParsers(parserClasses);
		}
		
		
		
		
		public static function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void		{			getInstance().addEventListener(type, listener, useCapture, priority, useWeakReference);		}								public static function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void		{			getInstance().removeEventListener(type, listener,useCapture);		}								public static function hasEventListener(type : String) : Boolean		{			return getInstance().hasEventListener(type);		}								public static function willTrigger(type : String) : Boolean		{			return getInstance().willTrigger(type);		}
		
		
				
		/**
		 * Loads a yet unloaded resource file from the given url.
		 */
		private function loadResource(req : URLRequest, parser : ParserBase = null, context : AssetLoaderContext = null, ns : String = null) : AssetLoaderToken
		{
			var loader : AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(away3d.events.LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
			loader.addEventListener(away3d.events.LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
			loader.addEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
			return loader.load(req, parser, context, ns);
		}
		
		
		
		/**
		 * Retrieves an unloaded resource parsed from the given data.
		 * @param data The data to be parsed.
		 * @param id The id that will be assigned to the resource. This can later also be used by the getResource method.
		 * @param ignoreDependencies Indicates whether or not dependencies should be ignored or loaded.
		 * @param parser An optional parser object that will translate the data into a usable resource.
		 * @return A handle to the retrieved resource.
		 */
		private function parseResource(data : *, parser : ParserBase = null, context : AssetLoaderContext = null, ns : String = null) : AssetLoaderToken
		{
			var loader : AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(away3d.events.LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
			loader.addEventListener(away3d.events.LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
			return loader.parseData(data, '', parser, context, ns);
		}
		
		
		
		private function addAsset(asset : IAsset) : void
		{
			var old : IAsset;
			
			trace('addAsset()');
			
			old = getAsset(asset.name, asset.assetNamespace);
			if (old != null) {
				trace('had old! Resolving');
				_strategy.resolveConflict(asset, old, _assetDictionary[asset.assetNamespace], _strategyPreference);
				trace('RESOLVED: ===================================');
				trace('old: ', old.assetFullPath);
				trace('new: ', asset.assetFullPath);
				trace('=============================================');
			}
			
			// Add it
			_assets.push(asset);
			if (!_assetDictionary.hasOwnProperty(asset.assetNamespace))
				_assetDictionary[asset.assetNamespace] = {};
			_assetDictionary[asset.assetNamespace][asset.name] = asset;
			
			
			asset.addEventListener(AssetEvent.ASSET_RENAME, onAssetRename);
		}
		
		
		private function rehashAssetDict() : void
		{
			var asset : IAsset;
			
			_assetDictionary = {};
			
			_assets.fixed = true;
			for each (asset in _assets) {
				if (!_assetDictionary.hasOwnProperty(asset.assetNamespace))
					_assetDictionary[asset.assetNamespace] = {};
				
				_assetDictionary[asset.assetNamespace][asset.name] = asset;
			}
			_assets.fixed = false;
			
			_assetDictDirty = false;
		}
		
		
		/**
		 * Called when a dependency was retrieved.
		 */
		private function onDependencyRetrieved(event : away3d.events.LoaderEvent) : void
		{
			if (hasEventListener(away3d.events.LoaderEvent.DEPENDENCY_COMPLETE))
				dispatchEvent(event);
		}
		
		/**
		 * Called when a an error occurs during dependency retrieving.
		 */
		private function onDependencyRetrievingError(event : LoaderEvent) : void
		{
			var ext:String = event.url.substring(event.url.length-4, event.url.length).toLowerCase();
			if (hasEventListener(LoaderEvent.LOAD_ERROR)){
				dispatchEvent(event);
			}
			
			else throw new Error(event.message);
		}
		
		private function onAssetComplete(event : AssetEvent) : void
		{
			addAsset(event.asset);
			dispatchEvent(event.clone());
		}
		
		/**
		 * Called when the resource and all of its dependencies was retrieved.
		 */
		private function onResourceRetrieved(event : away3d.events.LoaderEvent) : void
		{
			var session : AssetLoader = AssetLoader(event.target);
			
			var index : int = _loadingSessions.indexOf(session);
			session.removeEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
			session.removeEventListener(away3d.events.LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
			session.removeEventListener(away3d.events.LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
			session.removeEventListener(away3d.events.LoaderEvent.DEPENDENCY_ERROR, onDependencyRetrievingError);
			session.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			
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
			if(hasEventListener(away3d.events.LoaderEvent.DEPENDENCY_ERROR)){
				var re:away3d.events.LoaderEvent = new away3d.events.LoaderEvent(away3d.events.LoaderEvent.DEPENDENCY_ERROR, "");
				dispatchEvent(re);
			} else{
				throw new Error(msg);
			}
		}
		
		
		private function onAssetRename(ev : AssetEvent) : void
		{
			trace('onAssetRename()');
			var asset : IAsset = IAsset(ev.currentTarget);
			var old : IAsset = getAsset(asset.assetNamespace, asset.name);
			
			if (old != null)
				_strategy.resolveConflict(asset, old, _assetDictionary[asset.assetNamespace], _strategyPreference);
			else {
				var dict : Object = _assetDictionary[ev.asset.assetNamespace];
				if (dict == null)
					return;
				
				dict[ev.assetPrevName] = null;
				dict[ev.asset.name] = ev.asset;
			}
		}
	}
}

// singleton enforcer
class SingletonEnforcer
{
}
