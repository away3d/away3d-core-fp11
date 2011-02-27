package away3d.loading
{
	/**
	 * IResource provides a common interface to be used by objects that can be loaded or parsed.
	 *
	 * @see away3d.loading.ResourceManager
	 * @see away3d.loading.AssetLoader
	 */
    public interface IResource
    {
		/**
		 * The name of the resource.
		 */
        function get name() : String;
        function set name(value : String) : void;

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
        function dispose(deep : Boolean) : void;
    }
}
