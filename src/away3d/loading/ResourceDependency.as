package away3d.loading
{
	import away3d.arcane;
	import away3d.loading.parsers.ParserBase;

	use namespace arcane;

	/**
	 * ResourceDependency represents the data required to load, parse and resolve additional files ("dependencies")
	 * required by a parser, used by ResourceLoadSession.
	 *
	 * @see away3d.loading.ResourceManager
	 * @see away3d.loading.ResourceLoadSession
	 */
    public class ResourceDependency
    {
        private var _url : String;
        private var _resource : IResource;
        private var _parentParser : ParserBase;
        private var _id : String;
		private var _data : *;

		/**
		 * Creates a new ResourceDependency object.
		 * @param id The id of the dependency.
		 * @param url The url of the dependency, if the resource needs to be loaded.
		 * @param data The data containing the dependency to be parsed, if the resource was already loaded.
		 * @param parentParser The parser which is dependent on this ResourceDependency object.
		 */
        public function ResourceDependency(id : String,  url : String, data : *, parentParser : ParserBase)
        {
            _id = id;
            _url = url;
            _parentParser = parentParser;
			_data = data;
        }

		/**
		 * The id of the dependency.
		 */
        public function get id() : String
        {
            return _id;
        }

		/**
		 * The url of the dependency.
		 */
        public function get url() : String
        {
            return _url;
        }

		/**
		 * The loaded and parsed resource.
		 */
        public function get resource() : IResource
        {
            return _resource;
        }

        public function set resource(value : IResource) : void
        {
            _resource = value;
            _resource.name = _id;
        }

		/**
		 * The data containing the dependency to be parsed, if the resource was already loaded.
		 */
		public function get data() : *
		{
			return _data;
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
	}
}
