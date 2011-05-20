package away3d.loaders.misc
{
	import away3d.arcane;
	
	public class AssetLoaderContext
	{
		private var _includeDependencies : Boolean;
		private var _dependencyBaseUrl : String;
		private var _embeddedDataByUrl : Object;
		private var _remappedUrls : Object;
		
		private var _overrideAbsPath : Boolean;
		private var _overrideFullUrls : Boolean;
		
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
			_remappedUrls = {};
		}
		
		
		/**
		 * Defines whether dependencies (all files except the one at the URL given to the load() or
		 * parseData() operations) should be automatically loaded. Defaults to true.
		*/
		public function get includeDependencies() : Boolean
		{
			return _includeDependencies;
		}
		public function set includeDependencies(val : Boolean) : void
		{
			_includeDependencies = val;
		}
		
		
		/**
		 * A base URL that will be appended to all relative dependency URLs found in a loaded resource.
		 * Absolute paths will not be affected by the value of this property.
		*/
		public function get dependencyBaseUrl() : String
		{
			return _dependencyBaseUrl;
		}
		public function set dependencyBaseUrl(val : String) : void
		{
			_dependencyBaseUrl = val;
		}
		
		
		
		/**
		 * Defines whether absolute paths (defined as paths that begin with a "/") should be overridden
		 * with the dependencyBaseUrl defined in this context. If this is true, and the base path is
		 * "base", /path/to/asset.jpg will be resolved as base/path/to/asset.jpg.
		*/
		public function get overrideAbsolutePaths() : Boolean
		{
			return _overrideAbsPath;
		}
		public function set overrideAbsolutePaths(val : Boolean) : void
		{
			_overrideAbsPath = val;
		}
		
		
		/**
		 * Defines whether "full" URLs (defined as a URL that includes a scheme, e.g. http://) should be
		 * overridden with the dependencyBaseUrl defined in this context. If this is true, and the base
		 * path is "base", http://example.com/path/to/asset.jpg will be resolved as base/path/to/asset.jpg.
		*/
		public function get overrideFullURLs() : Boolean
		{
			return _overrideFullUrls;
		}
		public function set overrideFullURLs(val : Boolean) : void
		{
			_overrideFullUrls = val;
		}
		
		
		/**
		 * Map a URL to another URL, so that files that are referred to by the original URL will instead
		 * be loaded from the new URL. Use this when your file structure does not match the one that is
		 * expected by the loaded file.
		 * 
		 * @param originalUrl The original URL which is referenced in the loaded resource.
		 * @param newUrl The URL from which Away3D should load the resource instead.
		 * 
		 * @see mapUrlToData()
		*/
		public function mapUrl(originalUrl : String, newUrl : String) : void
		{
			_remappedUrls[originalUrl] = newUrl;
		}
		
		
		/**
		 * Map a URL to embedded data, so that instead of trying to load a dependency from the URL at
		 * which it's referenced, the dependency data will be retrieved straight from the memory instead.
		 * 
		 * @param originalUrl The original URL which is referenced in the loaded resource.
		 * @param data The embedded data. Can be ByteArray or a class which can be used to create a bytearray.
		*/
		public function mapUrlToData(originalUrl : String, data : *) : void
		{
			_embeddedDataByUrl[originalUrl] = data;
		}
		
		
		/**
		 * @private
		 * Defines whether embedded data has been mapped to a particular URL.
		*/
		arcane function hasDataForUrl(url : String) : Boolean
		{
			return _embeddedDataByUrl.hasOwnProperty(url);
		}
		
		
		/**
		 * @private
		 * Returns embedded data for a particular URL.
		*/
		arcane function getDataForUrl(url : String) : *
		{
			return _embeddedDataByUrl[url];
		}
		
		
		/**
		 * @private
		 * Defines whether a replacement URL has been mapped to a particular URL.
		*/
		arcane function hasMappingForUrl(url : String) : Boolean
		{
			return _remappedUrls.hasOwnProperty(url);
		}
		
		
		/**
		 * @private
		 * Returns new (replacement) URL for a particular original URL.
		*/
		arcane function getRemappedUrl(originalUrl : String) : String
		{
			return _remappedUrls[originalUrl];
		}
	}
}