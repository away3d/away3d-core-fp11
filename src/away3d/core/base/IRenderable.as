package away3d.core.base {
	/**
	 * IRenderable is an interface for classes that are used in the rendering pipeline to render the
	 * contents of a partition
	 */
	public interface IRenderable extends IMaterialOwner {
		function get next():IRenderable;

		function get materialID():int;

		function get renderOrderId():int;

		function get zIndex():Number;

		function dispose():void;

		function invalidateGeometry():void;

		function invalidateIndexData():void;

		function invalidateVertexData(dataType:String):void;
	}
}
