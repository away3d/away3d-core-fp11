package away3d.loading.misc
{
	public class AssetLoaderContext
	{
		private var _ignoreDependencies : Boolean;
		private var _dependencyBaseUrl : String;
		private var _embeddedDataByUrl : Object;
		
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
		
		
		public function get dependencyBaseUrl() : String
		{
			return _dependencyBaseUrl;
		}
		
		
		public function mapUrlToEmbed(url : String, data : Class) : void
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