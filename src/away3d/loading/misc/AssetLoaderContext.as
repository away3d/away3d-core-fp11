package away3d.loading.misc
{
	public class AssetLoaderContext
	{
		private var _ignoreDependencies : Boolean;
		private var _dependencyBaseUrl : String;
		private var _embeddedDataByUrl : Object;
		
		/**
		 * AssetLoaderContext provides configuration for the AssetLoader load() and parse() operations.
		 * Use it to configure how (and if) dependencies are loaded, or to map dependency URLs to
		 * embedded data.
		 * 
		 * @see away3d.loading.AssetLoader
		*/
		public function AssetLoaderContext(ignoreDependencies : Boolean = false, dependencyBaseUrl : String = null)
		{
			_ignoreDependencies = ignoreDependencies;
			_dependencyBaseUrl = dependencyBaseUrl || '';
			_embeddedDataByUrl = {};
		}
		
		
		public function get ignoreDependencies() : Boolean
		{
			return _ignoreDependencies;
		}
		public function set ignoreDependencies(val : Boolean) : void
		{
			_ignoreDependencies = val;
		}
		
		
		public function get dependencyBaseUrl() : String
		{
			return _dependencyBaseUrl;
		}
		public function set dependencyBaseUrl(val : String) : void
		{
			_dependencyBaseUrl = val;
		}
		
		
		public function mapUrlToEmbededData(url : String, data : Class) : void
		{
			_embeddedDataByUrl[url] = data;
		}
		
		
		public function hasAssetForUrl(url : String) : Boolean
		{
			return _embeddedDataByUrl.hasOwnProperty(url);
		}
		
		
		public function resolveEmbedFromUrl(url : String) : Class
		{
			return _embeddedDataByUrl[url];
		}
	}
}