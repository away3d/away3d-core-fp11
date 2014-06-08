package away3d.core.render {
	import away3d.core.TriangleSubMesh;
	import away3d.core.base.LineSubMesh;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.sort.IEntitySorter;
	import away3d.core.traverse.ICollector;
	import away3d.entities.Billboard;
	import away3d.entities.SkyBox;
	import away3d.textures.Texture2DBase;

	import flash.display.Stage;

	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;

	public interface IRenderer extends IEventDispatcher{
		function get renderableSorter():IEntitySorter;

		function get shareContext():Boolean;

		function set shareContext(value:Boolean):void;

		function get width():Number;

		function set width(value:Number):void;

		function get height():Number;

		function set height(value:Number):void;

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

		function set backgroundAlpha(value:Number):void;

		function get antiAlias():Number

		function set antiAlias(value:Number):void

		function init(stage:Stage):void;

		function get stage3DProxy():Stage3DProxy;

		/**
		 * @internal
		 */
		function createEntityCollector():ICollector;

		function get background():Texture2DBase;

		function set background(value:Texture2DBase):void;

		function get backgroundR():Number;

		function set backgroundR(value:Number):void;

		function get backgroundG():Number;

		function set backgroundG(value:Number):void;

		function get backgroundB():Number;

		function set backgroundB(value:Number):void;

		function get backgroundAlpha():Number;

		function set layeredView(value:Boolean):void;

		function get layeredView():Boolean;
	}
}
