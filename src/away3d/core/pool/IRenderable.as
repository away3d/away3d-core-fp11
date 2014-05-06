package away3d.core.pool {
	import flash.display.Stage;

	/**
	 * IRenderable is an interface for classes that are used in the rendering pipeline to render the
	 * contents of a partition
	 */
	public interface IRenderable {
		function get next():IRenderable;

		function set next(value:IRenderable):void;

		function get materialId():int;

		function set materialId(value:int):void;

		function get renderOrderId():int;

		function set renderOrderId(value:int):void;

		function get zIndex():Number;

		function set zIndex(value:Number):void;

		function init(stage:Stage):void;

		function dispose():void;

		function invalidateGeometry():void;

		function invalidateIndexData():void;

		function invalidateVertexData(dataType:String):void;
	}
}
