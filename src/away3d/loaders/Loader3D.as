package away3d.loaders
{
	import away3d.containers.ObjectContainer3D;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.misc.AssetLoaderToken;
	import away3d.loaders.misc.SingleFileLoader;
	import away3d.loaders.parsers.ParserBase;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	
	/**
	 * Loader3D can load any file format that Away3D supports (or for which a third-party parser
	 * has been plugged in) and be added directly to the scene. As assets are encountered
	 * they are added to the Loader3D container. Assets that can not be displayed in the scene
	 * graph (e.g. unused bitmaps/materials, skeletons et c) will be ignored.
	 * 
	 * This provides a fast and easy way to load models (no need for event listeners) but is not
	 * very versatile since many types of assets are ignored.
	 * 
	 * Loader3D by default uses the AssetLibrary to load all assets, which means that they also
	 * ends up in the library. To circumvent this, Loader3D can be configured to not use the 
	 * AssetLibrary in which case it will use the AssetLoader directly.
	 * 
	 * @see away3d.loading.AssetLoader
	 * @see away3d.loading.AssetLibrary
	*/
	public class Loader3D extends ObjectContainer3D
	{
		private var _useAssetLib : Boolean;
		private var _assetLibId : String;
		
		public function Loader3D(useAssetLibrary : Boolean = true, assetLibraryId : String = null)
		{
			super();
			
			_useAssetLib = useAssetLibrary;
			_assetLibId = assetLibraryId;
		}
		
		
		public function load(req : URLRequest, parser : ParserBase = null, context : AssetLoaderContext = null, namespace : String = null) : AssetLoaderToken
		{
			if (_useAssetLib) {
				var lib : AssetLibrary;
				
				lib = AssetLibrary.getInstance(_assetLibId);
				lib.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
				lib.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
				return lib.load(req, parser, context, namespace);
			}
			else {
				var loader : AssetLoader = new AssetLoader();
				loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
				loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
				return loader.load(req, parser, context, namespace);
			}
		}
		
		
		public function parseData(data : *, parser : ParserBase = null, context : AssetLoaderContext = null,  namespace : String = null) : AssetLoaderToken
		{
			if (_useAssetLib) {
				var lib : AssetLibrary;
				
				lib = AssetLibrary.getInstance(_assetLibId);
				lib.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
				lib.addEventListener(away3d.events.LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
				return lib.parseData(data, parser, context, namespace);
			}
			else {
				var loader : AssetLoader = new AssetLoader();
				loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
				loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
				return loader.parseData(data, '', parser, context, namespace);
			}
		}
		
		
		public static function enableParser(parserClass : Class) : void
		{
			SingleFileLoader.enableParser(parserClass);
		}
		
		
		public static function enableParsers(parserClasses : Vector.<Class>) : void
		{
			SingleFileLoader.enableParsers(parserClasses);
		}
		
		
		
		private function onAssetRetrieved(ev : AssetEvent) : void
		{
			var type : String = ev.asset.assetType;
			if (type == AssetType.CONTAINER) {
				this.addChild(ObjectContainer3D(ev.asset));
			}
			else if (type == AssetType.MESH) {
				var mesh : Mesh = Mesh(ev.asset);
				if (mesh.parent == null)
					this.addChild(mesh);
			}
			
			this.dispatchEvent(ev.clone());
		}
		
		
		private function onResourceRetrieved(ev : Event) : void
		{
			var dispatcher : EventDispatcher;
			
			dispatcher = EventDispatcher(ev.currentTarget);
			dispatcher.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
			dispatcher.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
			dispatcher.removeEventListener(LoaderEvent.DATA_LOADED, onResourceRetrieved);
			
			this.dispatchEvent(ev.clone());
		}
	}
}