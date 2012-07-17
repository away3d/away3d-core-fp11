package away3d.library.assets
{
	import flash.display.BitmapData;

	/**
	 * BitmapDataResource is a wrapper for loaded BitmapData, allowing it to be used uniformly as a resource when
	 * loading, parsing, and listing/resolving dependencies.
	 */
	public class BitmapDataAsset extends NamedAssetBase implements IAsset
	{
		private var _bitmapData : BitmapData;

		/**
		 * Creates a new BitmapDataResource object.
		 * @param bitmapData An optional BitmapData object to use as the resource data.
		 */
		public function BitmapDataAsset(bitmapData : BitmapData = null)
		{
			_bitmapData = bitmapData;
		}

		/**
		 * The bitmapData to be treated as a resource.
		 */
		public function get bitmapData() : BitmapData
		{
			return _bitmapData;
		}

		public function set bitmapData(value : BitmapData) : void
		{
			_bitmapData = value;
		}
		
		
		public function get assetType() : String
		{
			return AssetType.TEXTURE;
		}

		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose() : void
		{
			_bitmapData.dispose();
		}
	}
}
