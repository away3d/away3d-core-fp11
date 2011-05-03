package away3d.events
{
	import away3d.library.assets.IAsset;
	
	import flash.events.Event;

	public class AssetEvent extends Event
	{
		public static const ASSET_COMPLETE : String = 'assetRetrieved';
		
		public static const ASSET_RENAME : String = 'assetRename';
		
		private var _asset : IAsset;
		
		public function AssetEvent(type : String, asset : IAsset = null)
		{
			super(type);
			
			_asset = asset;
		}
		
		
		public function get asset() : IAsset
		{
			return _asset;
		}
		
		
		public override function clone() : Event
		{
			return new AssetEvent(type, asset);
		}
	}
}