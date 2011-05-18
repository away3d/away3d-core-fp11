package away3d.events
{
	import away3d.library.assets.IAsset;
	
	import flash.events.Event;

	public class AssetEvent extends Event
	{
		public static const ASSET_COMPLETE : String = 'assetRetrieved';
		
		public static const ASSET_RENAME : String = 'assetRename';
		public static const ASSET_CONFLICT_RESOLVED : String = 'assetConflictResolved';
		
		private var _asset : IAsset;
		private var _prevName : String;
		
		public function AssetEvent(type : String, asset : IAsset = null, prevName : String = null)
		{
			super(type);
			
			_asset = asset;
			_prevName = prevName || (_asset? _asset.name : null);
		}
		
		
		public function get asset() : IAsset
		{
			return _asset;
		}
		
		
		public function get assetPrevName() : String
		{
			return _prevName;
		}
		
		
		public override function clone() : Event
		{
			return new AssetEvent(type, asset, assetPrevName);
		}
	}
}