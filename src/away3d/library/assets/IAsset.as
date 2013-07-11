package away3d.library.assets
{
	import flash.events.IEventDispatcher;
	
	public interface IAsset extends IEventDispatcher
	{
		/**
		 * The name of the asset.
		 */
		function get name():String;
		
		function set name(val:String):void;

		/**
		 * The id of the asset.
		 */
		function get id():String;
		
		function set id(val:String):void;

		/**
		 * The namespace of the asset. This allows several assets with the same name to coexist in different contexts.
		 */
		function get assetNamespace():String;

		/**
		 * The type of the asset.
		 */
		function get assetType():String;

		/**
		 * The full path of the asset.
		 */
		function get assetFullPath():Array;
		
		function assetPathEquals(name:String, ns:String):Boolean;
		
		function resetAssetPath(name:String, ns:String = null, overrideOriginal:Boolean = true):void;
		
		/**
		 * Cleans up resources used by this asset.
		 */
		function dispose():void;
	}
}
