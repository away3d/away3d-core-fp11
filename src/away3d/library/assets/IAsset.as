package away3d.library.assets
{
	import flash.events.IEventDispatcher;

	public interface IAsset extends IEventDispatcher
	{
		function get name() : String;
		function set name(val : String) : void;
		function get assetNamespace() : String;
		function get assetType() : String;
		function get assetFullPath() : Array;
		
		function assetPathEquals(name : String, ns : String) : Boolean;
		function resetAssetPath(name : String, ns : String=null, overrideOriginal : Boolean = true) : void;
	}
}