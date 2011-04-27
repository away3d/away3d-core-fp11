package away3d.events
{
	import away3d.loading.assets.IAsset;
	
	import flash.events.Event;

	public class AssetPathEvent extends Event
	{
		public static const ASSET_RENAME : String = 'assetRename';
		
		private var _asset : IAsset;
		
		public function AssetPathEvent(type : String, asset : IAsset = null)
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
			return new AssetPathEvent(type, asset);
		}
	}
}