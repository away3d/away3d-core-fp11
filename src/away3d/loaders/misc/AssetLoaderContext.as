package away3d.loaders.misc
{
	import away3d.arcane;
	
	public class AssetLoaderContext
	{
		private var _includeDependencies : Boolean;
		private var _dependencyBaseUrl : String;
		private var _embeddedDataByUrl : Object;
		
		/**
		 * AssetLoaderContext provides configuration for the AssetLoader load() and parse() operations.
		 * Use it to configure how (and if) dependencies are loaded, or to map dependency URLs to
		 * embedded data.
		 * 
		 * @see away3d.loading.AssetLoader
		*/
		public function AssetLoaderContext(includeDependencies : Boolean = true, dependencyBaseUrl : String = null)
		{
			_includeDependencies = includeDependencies;
			_dependencyBaseUrl = dependencyBaseUrl || '';
			_embeddedDataByUrl = {};
		}
		
		
		public function get includeDependencies() : Boolean
		{
			return _includeDependencies;
		}
		public function set includeDependencies(val : Boolean) : void
		{
			_includeDependencies = val;
		}
		
		
		public function get dependencyBaseUrl() : String
		{
			return _dependencyBaseUrl;
		}
		public function set dependencyBaseUrl(val : String) : void
		{
			_dependencyBaseUrl = val;
		}
		
		
		public function mapUrlToData(url : String, data : Class) : void
		{
			_embeddedDataByUrl[url] = data;
		}
		
		
		arcane function hasDataForUrl(url : String) : Boolean
		{
			return _embeddedDataByUrl.hasOwnProperty(url);
		}
		
		
		arcane function getDataForUrl(url : String) : Class
		{
			return _embeddedDataByUrl[url];
		}
	}
}