package away3d.core.render {
	import away3d.core.TriangleSubMesh;
	import away3d.core.base.LineSubMesh;
	import away3d.core.sort.IEntitySorter;
	import away3d.core.traverse.ICollector;
	import away3d.entities.Billboard;
	import away3d.entities.Skybox;

	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;

	public interface IRenderer extends IEventDispatcher{
		function get renderableSorter():IEntitySorter;

		function get shareContext():Boolean;

		function get x():Number;

		function get y():Number;

		function get width():Number;

		function get height():Number;

		function get viewPort():Rectangle;

		function get scissorRect():Rectangle;

		/**
		 *
		 * @param sprite
		 */
		function applyBillboard(sprite:Billboard):void;

		/**
		 *
		 * @param triangleSubMesh
		 */
		function applyLineSubMesh(triangleSubMesh:LineSubMesh):void;

		/**
		 *
		 * @param skybox
		 */
		function applySkybox(skybox:Skybox):void;

		/**
		 *
		 * @param triangleSubMesh
		 */
		function applyTriangleSubMesh(triangleSubMesh:TriangleSubMesh):void;

		function dispose():void;

		/**
		 *
		 * @param entityCollector
		 */
		function render(entityCollector:ICollector):void;

		function get backgroundR():Number;

		function set backgroundR(value:Number):void;

		function get backgroundG():Number;

		function set backgroundG(value:Number):void;

		function get backgroundB():Number;

		function set backgroundB(value:Number):void;

		function get backgroundAlpha():Number;

		function set backgroundAlpha(value:Number):void;

		function get antiAlias():Number

		function set antiAlias(value:Number):void

		/**
		 * @internal
		 */
		function createEntityCollector():ICollector;
	}
}
