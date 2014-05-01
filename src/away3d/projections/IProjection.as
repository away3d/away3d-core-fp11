package away3d.projections {
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public interface IProjection extends IEventDispatcher {
		function get coordinateSystem():uint;

		function get frustumCorners():Vector.<Number>;

		function get matrix():Matrix3D;

		function get near():Number;

		function set near(value:Number):void;

		function get far():Number;

		function set far(value:Number):void;

		function get originX():Number;

		function get originY():Number;

		function get aspectRatio():Number;

		function set aspectRatio(value:Number):void;

		function project(point3d:Vector3D, v:Vector3D = null):Vector3D;

		function unproject(nX:Number, nY:Number, sZ:Number, v:Vector3D = null):Vector3D;

		function updateScissorRect(x:Number, y:Number, width:Number, height:Number):void;

		function updateViewport(x:Number, y:Number, width:Number, height:Number):void;
	}
}
