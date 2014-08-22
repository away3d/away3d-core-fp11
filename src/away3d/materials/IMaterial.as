package away3d.materials {
	import away3d.core.base.IMaterialOwner;
	import away3d.library.assets.IAsset;

	public interface IMaterial extends IAsset {
		function get width():Number;

		function get height():Number;

		function get requiresBlending():Boolean;

        function set blendMode(value:String):void;

        function get blendMode():String;

		function get materialId():Number;

		function get renderOrderId():int;

		function addOwner(owner:IMaterialOwner):void;

		function removeOwner(owner:IMaterialOwner):void;
	}
}