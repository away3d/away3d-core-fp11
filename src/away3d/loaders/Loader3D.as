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
		
		public function load(req : URLRequest, parser : ParserBase = null, context : AssetLoaderContext = null, ns : String = null) : AssetLoaderToken
		{
			var token : AssetLoaderToken;
			
			if (_useAssetLib) {
				var lib : AssetLibrary;
				lib = AssetLibrary.getInstance(_assetLibId);
				token = lib.load(req, parser, context, ns);
			}
			else {
				var loader : AssetLoader = new AssetLoader();
				token = loader.load(req, parser, context, ns);
			}
			
			token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			token.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			return token;
		}
		
		
		public function parseData(data : *, parser : ParserBase = null, context : AssetLoaderContext = null,  ns : String = null) : AssetLoaderToken
		{
			var token : AssetLoaderToken;
			
			if (_useAssetLib) {
				var lib : AssetLibrary;
				lib = AssetLibrary.getInstance(_assetLibId);
				token = lib.parseData(data, parser, context, ns);
			}
			else {
				var loader : AssetLoader = new AssetLoader();
				token = loader.parseData(data, '', parser, context, ns);
			}
			
			token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			token.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			token.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			return token;
		}
		
		
		public static function enableParser(parserClass : Class) : void
		{
			SingleFileLoader.enableParser(parserClass);
		}
		
		
		public static function enableParsers(parserClasses : Vector.<Class>) : void
		{
			SingleFileLoader.enableParsers(parserClasses);
		}
		
		
		
		private function onAssetComplete(ev : AssetEvent) : void
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
		
		
		private function onResourceComplete(ev : Event) : void
		{
			var dispatcher : EventDispatcher;
			
			dispatcher = EventDispatcher(ev.currentTarget);
			dispatcher.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			dispatcher.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.ANIMATION_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.ANIMATOR_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.BITMAP_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			this.dispatchEvent(ev.clone());
		}
	}
}