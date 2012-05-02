package away3d.library
{
	import away3d.arcane;
	import away3d.library.assets.IAsset;
	import away3d.library.naming.ConflictStrategyBase;
	import away3d.library.utils.AssetLibraryIterator;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.misc.AssetLoaderToken;
	import away3d.loaders.misc.SingleFileLoader;
	import away3d.loaders.parsers.ParserBase;
	
	import flash.net.URLRequest;
	
	use namespace arcane;
	
	/**
	 * AssetLibrary enforces a singleton pattern and is not intended to be instanced.
	 * It's purpose is to allow access to the default library bundle through a set of static shortcut methods.
	 * If you are interested in creating multiple library bundles, please use the <code>getBundle()</code> method.
	 */
	public class AssetLibrary
	{
		arcane static var _instances : Object = {};
		
		/**
		 * Creates a new <code>AssetLibrary</code> object.
		 * 
		 * @param se A singleton enforcer for the AssetLibrary ensuring it cannnot be instanced.
		 */
		public function AssetLibrary(se : AssetLibrarySingletonEnforcer)
		{
			se = se;
		}
		
		/**
		 * Returns an AssetLibrary bundle instance. If no key is given, returns the default bundle (which is
		 * similar to using the AssetLibraryBundle as a singleton). To keep several separated library bundles,
		 * pass a string key to this method to define which bundle should be returned. This is
		 * referred to as using the AssetLibraryBundle as a multiton.
		 * 
		 * @param key Defines which multiton instance should be returned.
		 * @return An instance of the asset library
		 */
		public static function getBundle(key : String = 'default') : AssetLibraryBundle
		{
			return AssetLibraryBundle.getInstance(key);
		}
		
		/**
		 * 
		 */		
		public static function enableParser(parserClass : Class) : void
		{
			SingleFileLoader.enableParser(parserClass);
		}
		
		/**
		 * 
		 */
		public static function enableParsers(parserClasses : Vector.<Class>) : void
		{
			SingleFileLoader.enableParsers(parserClasses);
		}
		
		/**
		 * Short-hand for conflictStrategy property on default asset library bundle.
		 * 
		 * @see away3d.library.AssetLibraryBundle.conflictStrategy
		*/
		public static function get conflictStrategy() : ConflictStrategyBase
		{
			return getBundle().conflictStrategy;
		}
		public static function set conflictStrategy(val : ConflictStrategyBase) : void
		{
			getBundle().conflictStrategy = val;
		}
		
		/**
		 * Short-hand for conflictPrecedence property on default asset library bundle.
		 *
		 * @see away3d.library.AssetLibraryBundle.conflictPrecedence
		*/
		public static function get conflictPrecedence() : String
		{
			return getBundle().conflictPrecedence;
		}
		public static function set conflictPrecedence(val : String) : void
		{
			getBundle().conflictPrecedence = val;
		}
		
		/**
		 * Short-hand for createIterator() method on default asset library bundle.
		 * 
		 * @see away3d.library.AssetLibraryBundle.createIterator()
		*/
		public static function createIterator(assetTypeFilter : String = null, namespaceFilter : String = null, filterFunc : Function = null) : AssetLibraryIterator
		{
			return getBundle().createIterator(assetTypeFilter, namespaceFilter, filterFunc);
		}
		
		/**
		 * Short-hand for load() method on default asset library bundle.
		 * 
		 * @see away3d.library.AssetLibraryBundle.load()
		 */
		public static function load(req : URLRequest, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			return getBundle().load(req, context, ns, parser);
		}
		
		/**
		 * Short-hand for loadData() method on default asset library bundle.
		 * 
		 * @see away3d.library.AssetLibraryBundle.loadData()
		 */
		public static function loadData(data : *, context : AssetLoaderContext = null, ns : String = null, parser : ParserBase = null) : AssetLoaderToken
		{
			return getBundle().loadData(data, context, ns, parser);
		}
		
		/**
		 * Short-hand for getAsset() method on default asset library bundle.
		 * 
		 * @see away3d.library.AssetLibraryBundle.getAsset()
		 */
		public static function getAsset(name : String, ns : String = null) : IAsset
		{
			return getBundle().getAsset(name, ns);
		}
		
		/**
		 * Short-hand for addEventListener() method on default asset library bundle.
		 */
		public static function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void
		{
			getBundle().addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/**
		 * Short-hand for removeEventListener() method on default asset library bundle.
		 */		
		public static function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void
		{
			getBundle().removeEventListener(type, listener,useCapture);
		}
		
		/**
		 * Short-hand for hasEventListener() method on default asset library bundle.
		 */
		public static function hasEventListener(type : String) : Boolean
		{
			return getBundle().hasEventListener(type);
		}
		
		public static function willTrigger(type : String) : Boolean
		{
			return getBundle().willTrigger(type);
		}
		
		/**
		 * Short-hand for addAsset() method on default asset library bundle.
		 * 
		 * @see away3d.library.AssetLibraryBundle.addAsset()
		*/
		public static function addAsset(asset : IAsset) : void
		{
			getBundle().addAsset(asset);
		}
		
		/**
		 * Short-hand for removeAsset() method on default asset library bundle.
		 * 
		 * @param asset The asset which should be removed from the library.
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibraryBundle.removeAsset()
		*/
		public static function removeAsset(asset : IAsset, dispose : Boolean = true) : void
		{
			getBundle().removeAsset(asset, dispose);
		}
		
		
		/**
		 * Short-hand for removeAssetByName() method on default asset library bundle.
		 * 
		 * @param name The name of the asset to be removed.
		 * @param ns The namespace to which the desired asset belongs.
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibraryBundle.removeAssetByName()
		*/
		public static function removeAssetByName(name : String, ns : String = null, dispose : Boolean = true) : IAsset
		{
			return getBundle().removeAssetByName(name, ns, dispose);
		}
		
		/**
		 * Short-hand for removeAllAssets() method on default asset library bundle.
		 * 
		 * @param dispose Defines whether the assets should also be disposed.
		 * 
		 * @see away3d.library.AssetLibraryBundle.removeAllAssets()
		*/
		public static function removeAllAssets(dispose : Boolean = true) : void
		{
			getBundle().removeAllAssets(dispose);
		}
		
		/**
		 * Short-hand for removeNamespaceAssets() method on default asset library bundle.
		 * 
		 * @see away3d.library.AssetLibraryBundle.removeNamespaceAssets()
		*/
		public static function removeNamespaceAssets(ns : String=null, dispose : Boolean = true) : void
		{
			getBundle().removeNamespaceAssets(ns, dispose);
		}
	}
}

// singleton enforcer
class AssetLibrarySingletonEnforcer
{
}
