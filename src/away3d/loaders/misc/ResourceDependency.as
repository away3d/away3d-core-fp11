package away3d.loaders.misc
{
	import away3d.arcane;
	import away3d.library.assets.IAsset;
	import away3d.loaders.parsers.ParserBase;

	import flash.net.URLRequest;

	use namespace arcane;
	
	/**
	 * ResourceDependency represents the data required to load, parse and resolve additional files ("dependencies")
	 * required by a parser, used by ResourceLoadSession.
	 *
	 */
	public class ResourceDependency
	{
		private var _id : String;
		private var _req : URLRequest;
		private var _assets : Vector.<IAsset>;
		private var _parentParser : ParserBase;
		private var _data : *;
		private var _base : Boolean;
		private var _retrieveAsRawData : Boolean;
		
		public function ResourceDependency(id : String, req : URLRequest, data : *, parentParser : ParserBase, retrieveAsRawData : Boolean = false)
		{
			_id = id;
			_req = req;
			_parentParser = parentParser;
			_data = data;
			_retrieveAsRawData = retrieveAsRawData;
			
			_assets = new Vector.<IAsset>;
		}
		
		
		public function get id() : String
		{
			return _id;
		}
		
		
		public function get assets() : Vector.<IAsset>
		{
			return _assets;
		}
		
		
		public function get request() : URLRequest
		{
			return _req;
		}
		
		
		public function get retrieveAsRawData() : Boolean
		{
			return _retrieveAsRawData;
		}
		
		
		/**
		 * The data containing the dependency to be parsed, if the resource was already loaded.
		 */
		public function get data() : *
		{
			return _data;
		}
		
		
		/**
		 * @private
		 * Method to set data after having already created the dependency object, e.g. after load.
		*/
		arcane function setData(data : *) : void
		{
			_data = data;
		}
		
		/**
		 * The parser which is dependent on this ResourceDependency object.
		 */
		public function get parentParser() : ParserBase
		{
			return _parentParser;
		}
		
		/**
		 * Resolve the dependency when it's loaded with the parent parser. For example, a dependency containing an
		 * ImageResource would be assigned to a Mesh instance as a BitmapMaterial, a scene graph object would be added
		 * to its intended parent. The dependency should be a member of the dependencies property.
		 */
		public function resolve() : void
		{
			if (_parentParser) _parentParser.resolveDependency(this);
		}
		
		/**
		 * Resolve a dependency failure. For example, map loading failure from a 3d file
		 */
		public function resolveFailure() : void
		{
			if (_parentParser) _parentParser.resolveDependencyFailure(this);
		}
	}
}
