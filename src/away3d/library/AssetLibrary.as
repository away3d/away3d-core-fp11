package away3d.library
{
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	import away3d.library.naming.ConflictPrecedence;
	import away3d.library.naming.ConflictStrategy;
	import away3d.library.naming.ConflictStrategyBase;
	import away3d.library.utils.AssetLibraryIterator;
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
		
		private var _strategy : ConflictStrategyBase;
		private var _strategyPreference : String;
		
		private var _assets : Vector.<IAsset>;
		private var _assetDictionary : Object;
		private var _assetDictDirty : Boolean;
		
		
		
		public function AssetLibrary(se : SingletonEnforcer)
		{
			// TODO: not used
			se = se;			
			_assets = new Vector.<IAsset>;
			_assetDictionary = {};
			_loadingSessions = new Vector.<AssetLoader>;
			
			conflictStrategy = ConflictStrategy.APPEND_NUM_SUFFIX.create();
			conflictPrecedence = ConflictPrecedence.FAVOR_NEW;
		}
		
		
		
		/**
		 * Gets an AssetLibrary instance. If no key is given, returns the default instance (which is
		 * similar to using the AssetLibrary as a singleton.) To keep several separated libraries,
		 * pass a string key to this method to define which instance should be returned. This is
		 * referred to as using the AssetLibrary as a multiton.
		 * 
		 * @param key Defines which multiton instance should be returned.
		 * @return An instance of the asset library
		 */
		public static function getInstance(key : String = 'default') : AssetLibrary
		{
			if (!key)
				key = 'default';
			
			if (!_instances.hasOwnProperty(key))
				_instances[key] = new AssetLibrary(new SingletonEnforcer());
			
			return _instances[key];
		}
		
		
		/**
		 * Defines which strategy should be used for resolving naming conflicts, when two library
		 * assets are given the same name. By default, <code>ConflictStrategy.APPEND_NUM_SUFFIX</code>
		 * is used which means that a numeric suffix is appended to one of the assets. The
		 * <code>conflictPrecedence</code> property defines which of the two conflicting assets will
		 * be renamed.
		 * 
		 * @see away3d.library.naming.ConflictStrategy
		 * @see away3d.library.AssetLibrary.conflictPrecedence
		*/
		public function get conflictStrategy() : ConflictStrategyBase
		{
			return _strategy;
		}
		public function set conflictStrategy(val : ConflictStrategyBase) : void
		{
			if (!val)
				throw new Error('namingStrategy must not be null. To ignore naming, use AssetLibrary.IGNORE');
			
			_strategy = val.create();
		}
		
		
		/**
		 * Short-hand for conflictStrategy property on default asset library instance.
		*/
		public static function get conflictStrategy() : ConflictStrategyBase
		{
			return getInstance().conflictStrategy;
		}
		public static function set conflictStrategy(val : ConflictStrategyBase) : void
		{
			getInstance().conflictStrategy = val;
		}
		
		
		/**
		 * Defines which asset should have precedence when resolving a naming conflict between
		 * two assets of which one has just been renamed by the user or by a parser. By default
		 * <code>ConflictPrecedence.FAVOR_NEW</code> is used, meaning that the newly renamed
		 * asset will keep it's new name while the older asset gets renamed to not conflict.
		 * 
		 * This property is ignored for conflict strategies that do not actually rename an
		 * asset automatically, such as ConflictStrategy.IGNORE and ConflictStrategy.THROW_ERROR.
		 * 
		 * @see away3d.library.naming.ConflictPrecedence
		 * @see away3d.library.naming.ConflictStrategy
		*/
		public function get conflictPrecedence() : String
		{
			return _strategyPreference;
		}
		public function set conflictPrecedence(val : String) : void
		{
			_strategyPreference = val;
		}
		
		
		/**
		 * Short-hand for conflictPrecedence property on default asset library instance.
		 *
		 * @see away3d.library.AssetLibrary.conflictPrecedence
		*/
		public static function get conflictPrecedence() : String
		{
			return getInstance().conflictPrecedence;
		}
		public static function set conflictPrecedence(val : String) : void
		{
			getInstance().conflictPrecedence = val;
		}
		
		
		
		/**
		 * Create an AssetLibraryIterator instance that can be used to iterate over the assets
		 * in this asset library instance. The iterator can filter assets on asset type and/or
		 * namespace. A "null" filter value means no filter of that type is used.
		 * 
		 * @param assetTypeFilter Asset type to filter on (from the AssetType enum class.) Use
		 * null to not filter on asset type.
		 * @param namespaceFilter Namespace to filter on. Use null to not filter on namespace.
		 * @param filterFunc Callback function to use when deciding whether an asset should be
		 * included in the iteration or not. This needs to be a function that takes a single
		 * parameter of type IAsset and returns a boolean where true means it should be included.
		 * 
		 * @see away3d.library.assets.AssetType
		*/
		public function createIterator(assetTypeFilter : String = null, namespaceFilter : String = null, filterFunc : Function = null) : AssetLibraryIterator
		{
			return new AssetLibraryIterator(_assets, assetTypeFilter, namespaceFilter, filterFunc);
		}
		
		
		/**
		 * Short-hand for createIterator() method on default asset library instance.
		 * 
		 * @see away3d.library.AssetLibrary.createIterator()
		*/
		public static function createIterator(assetTypeFilter : String = null, namespaceFilter : String = null, filterFunc : Function = null) : AssetLibraryIterator
		{
			return getInstance().createIterator(assetTypeFilter, namespaceFilter, filterFunc);
		}
		
		
		public function load(req : URLRequest, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			return loadResource(req, context, ns, parser);
		}
		
		public static function load(req : URLRequest, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			return getInstance().load(req, context, ns, parser);
		}
		
		
		
		public function loadData(data : *, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			return parseResource(data, context, ns, parser);
		}
		
		public static function loadData(data : *, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			return getInstance().loadData(data, context, ns, parser);
		}
		
		
		
		public function getAsset(name : String, ns : String = null) : IAsset
		{
			// TODO not used
			//var asset : IAsset;
			
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
		
		
		
		
		public static function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void
		{
			getInstance().addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		
		
		public static function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void
		{
			getInstance().removeEventListener(type, listener,useCapture);
		}
		
		
		
		public static function hasEventListener(type : String) : Boolean
		{
			return getInstance().hasEventListener(type);
		}
		
		
		
		public static function willTrigger(type : String) : Boolean
		{
			return getInstance().willTrigger(type);
		}
		
		
		
		
		
		/**
		 * Adds an asset to the asset library, first making sure that it's name is unique
		 * using the method defined by the <code>conflictStrategy</code> and 
		 * <code>conflictPrecedence</code> properties.
		*/
		public function addAsset(asset : IAsset) : void
		{
			var ns : String;
			var old : IAsset;
			
			// Bail if asset has already been added.
			if (_assets.indexOf(asset) >= 0)
				return;
			
			old = getAsset(asset.name, asset.assetNamespace);
			ns = asset.assetNamespace || NamedAssetBase.DEFAULT_NAMESPACE;
			
			if (old != null) {
				_strategy.resolveConflict(asset, old, _assetDictionary[ns], _strategyPreference);
			}
			
			// Add it
			_assets.push(asset);
			if (!_assetDictionary.hasOwnProperty(ns))
				_assetDictionary[ns] = {};
			_assetDictionary[ns][asset.name] = asset;
			
			asset.addEventListener(AssetEvent.ASSET_RENAME, onAssetRename);
			asset.addEventListener(AssetEvent.ASSET_CONFLICT_RESOLVED, onAssetConflictResolved);
		}
		
		/**
		 * Short-hand for addAsset() method on default asset library instance.
		 * 
		 * @see away3d.library.AssetLibrary.addAsset()
		*/
		public static function addAsset(asset : IAsset) : void
		{
			getInstance().addAsset(asset);
		}
		
		
		
		
		/**
		 * Removes an asset from the library, and optionally disposes that asset by calling
		 * it's disposeAsset() method (which for most assets is implemented as a default
		 * version of that type's dispose() method.
		 * 
		 * @param asset The asset which should be removed from this library.
		 * @param dispose Defines whether the assets should also be disposed.
		*/
		public function removeAsset(asset : IAsset, dispose : Boolean = true) : void
		{
			var idx : int;
			
			removeAssetFromDict(asset);
			
			asset.removeEventListener(AssetEvent.ASSET_RENAME, onAssetRename);
			asset.removeEventListener(AssetEvent.ASSET_CONFLICT_RESOLVED, onAssetConflictResolved);
			
			idx = _assets.indexOf(asset);
			if (idx >= 0)
				_assets.splice(idx, 1);
			
			if (dispose)
				asset.disposeAsset();
		}
		
		/**
		 * Short-hand for removeAsset() method on default asset library instance.
		 * 
		 * @param asset The asset which should be removed from the library.
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibrary.removeAsset()
		*/
		public static function removeAsset(asset : IAsset, dispose : Boolean = true) : void
		{
			getInstance().removeAsset(asset, dispose);
		}
		
		
		
		
		/**
		 * Removes an asset which is specified using name and namespace.
		 * 
		 * @param name The name of the asset to be removed.
		 * @param ns The namespace to which the desired asset belongs.
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibrary.removeAsset()
		*/
		public function removeAssetByName(name : String, ns : String = null, dispose : Boolean = true) : IAsset
		{
			var asset : IAsset = getAsset(name, ns);
			if (asset) 
				removeAsset(asset, dispose);
			
			return asset;
		}
		
		/**
		 * Short-hand for removeAssetByName() method on default asset library instance.
		 * 
		 * @param name The name of the asset to be removed.
		 * @param ns The namespace to which the desired asset belongs.
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibrary.removeAssetByName()
		*/
		public static function removeAssetByName(name : String, ns : String = null, dispose : Boolean = true) : IAsset
		{
			return getInstance().removeAssetByName(name, ns, dispose);
		}
		
		
		
		
		/**
		 * Removes all assets from the asset library, optionally disposing them as they
		 * are removed.
		 * 
		 * @param dispose Defines whether the assets should also be disposed.
		*/
		public function removeAllAssets(dispose : Boolean = true) : void
		{
			if (dispose) {
				var asset : IAsset;
				for each (asset in _assets)
					asset.disposeAsset();
			}
			
			_assets.length = 0;
			rehashAssetDict();
		}
		
		/**
		 * Short-hand for removeAllAssets() method on default asset library instance.
		 * 
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibrary.removeAllAssets()
		*/
		public static function removeAllAssets(dispose : Boolean = true) : void
		{
			getInstance().removeAllAssets(dispose);
		}
		
		
		
		/**
		 * Removes all assets belonging to a particular namespace (null for default) 
		 * from the asset library, and optionall disposes them by calling their
		 * disposeAsset() method.
		 * 
		 * @param ns The namespace from which all assets should be removed.
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibrary.removeAsset()
		*/
		public function removeNamespaceAssets(ns : String=null, dispose : Boolean = true) : void
		{
			var idx : uint = 0;
			var asset : IAsset;
			var old_assets : Vector.<IAsset>;
			
			// Empty the assets vector after having stored a copy of it.
			// The copy will be filled with all assets which weren't removed.
			old_assets = _assets.concat();
			_assets.length = 0;
			
			ns ||= NamedAssetBase.DEFAULT_NAMESPACE;
			for each (asset in _assets) {
				// Remove from dict if in the supplied namespace. If not,
				// transfer over to the new vector.
				if (asset.assetNamespace == ns) {
					if (dispose) 
						asset.disposeAsset();
					removeAssetFromDict(asset);
				}
				else {
					_assets[idx++] = asset;
				}
			}
		}
		
		/**
		 * Short-hand for removeNamespaceAssets() method on default asset library instance.
		 * 
		 * @see away3d.library.AssetLibrary.removeNamespaceAssets()
		*/
		public static function removeNamespaceAssets(ns : String=null, dispose : Boolean = true) : void
		{
			getInstance().removeNamespaceAssets(ns, dispose);
		}
		
		
		
		
			
		private function removeAssetFromDict(asset : IAsset) : void
		{
			if (_assetDictDirty)
				rehashAssetDict();
			
			if (_assetDictionary.hasOwnProperty(asset.assetNamespace)) {
				if (_assetDictionary.hasOwnProperty(asset.name))
					delete _assetDictionary[asset.assetNamespace][asset.name];
				
			}
		}
		
		
		/**
		 * Loads a yet unloaded resource file from the given url.
		 */
		private function loadResource(req : URLRequest, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			var loader : AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
			loader.addEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
			loader.addEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			return loader.load(req, context, ns, parser);
		}
		
		
		
		/**
		 * Retrieves an unloaded resource parsed from the given data.
		 * @param data The data to be parsed.
		 * @param id The id that will be assigned to the resource. This can later also be used by the getResource method.
		 * @param ignoreDependencies Indicates whether or not dependencies should be ignored or loaded.
		 * @param parser An optional parser object that will translate the data into a usable resource.
		 * @return A handle to the retrieved resource.
		 */
		private function parseResource(data : *, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			var loader : AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
			loader.addEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			loader.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			return loader.loadData(data, '', context, ns, parser);
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
		private function onDependencyRetrieved(event : LoaderEvent) : void
		{
			if (hasEventListener(LoaderEvent.DEPENDENCY_COMPLETE))
				dispatchEvent(event);
		}
		
		/**
		 * Called when a an error occurs during dependency retrieving.
		 */
		private function onDependencyRetrievingError(event : LoaderEvent) : void
		{
			// TODO: not used
			//var ext:String = 
			event.url.substring(event.url.length-4, event.url.length).toLowerCase();
			if (hasEventListener(LoaderEvent.LOAD_ERROR)){
				dispatchEvent(event);
			}
			
			else throw new Error(event.message);
		}
		
		private function onAssetComplete(event : AssetEvent) : void
		{
			// Only add asset to library the first time.
			if (event.type == AssetEvent.ASSET_COMPLETE)
				addAsset(event.asset);
			
			dispatchEvent(event.clone());
		}
		
		/**
		 * Called when the resource and all of its dependencies was retrieved.
		 */
		private function onResourceRetrieved(event : LoaderEvent) : void
		{
			var loader : AssetLoader = AssetLoader(event.target);
			
			var index : int = _loadingSessions.indexOf(loader);
			loader.removeEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
			loader.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
			loader.removeEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
			loader.removeEventListener(LoaderEvent.DEPENDENCY_ERROR, onDependencyRetrievingError);
			loader.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			loader.removeEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
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
		/*
		private function onResourceError() : void
		{
			var msg:String = "Unexpected parser error";
			if(hasEventListener(LoaderEvent.DEPENDENCY_ERROR)){
				var re:LoaderEvent = new LoaderEvent(LoaderEvent.DEPENDENCY_ERROR, "");
				dispatchEvent(re);
			} else{
				throw new Error(msg);
			}
		}
		*/
		
		private function onAssetRename(ev : AssetEvent) : void
		{
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
		
		
		private function onAssetConflictResolved(ev : AssetEvent) : void
		{
			dispatchEvent(ev.clone());
		}
	}
}

// singleton enforcer
class SingletonEnforcer
{
}
