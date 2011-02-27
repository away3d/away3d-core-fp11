package away3d.loading
{
	import flash.display.BitmapData;

	/**
	 * BitmapDataResource is a wrapper for loaded BitmapData, allowing it to be used uniformly as a resource when
	 * loading, parsing, and listing/resolving dependencies.
	 */
	public class BitmapDataResource implements IResource
	{
		private var _name : String;
		private var _bitmapData : BitmapData;

		/**
		 * Creates a new BitmapDataResource object.
		 * @param bitmapData An optional BitmapData object to use as the resource data.
		 */
		public function BitmapDataResource(bitmapData : BitmapData = null)
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

		/**
		 * The name of the resource.
		 */
		public function get name() : String
		{
			return _name;
		}

		public function set name(value : String) : void
		{
			_name = value;
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose(deep : Boolean) : void
		{
			_bitmapData.dispose();
		}
	}
}
