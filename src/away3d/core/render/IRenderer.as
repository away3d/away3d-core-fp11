package away3d.core.render {
	import away3d.core.TriangleSubMesh;
	import away3d.core.base.LineSubMesh;
	import away3d.core.sort.IEntitySorter;
	import away3d.core.traverse.ICollector;
	import away3d.entities.Sprite3D;
	import away3d.prefabs.SkyBox;

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
		function applyBillboard(sprite:Sprite3D):void;

		/**
		 *
		 * @param triangleSubMesh
		 */
		function applyLineSubMesh(triangleSubMesh:LineSubMesh):void;

		/**
		 *
		 * @param skybox
		 */
		function applySkybox(skybox:SkyBox):void;

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

		/**
		 * @internal
		 */
		function get backgroundR():Number;

		/**
		 * @internal
		 */
		function get backgroundG():Number;

		/**
		 * @internal
		 */
		function get backgroundB():Number;

		/**
		 * @internal
		 */
		function get backgroundAlpha():Number;

		/**
		 * @internal
		 */
		function get createEntityCollector():ICollector;
	}
}
