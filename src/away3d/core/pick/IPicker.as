package away3d.core.pick
{
	import away3d.containers.*;
	
	import flash.geom.*;
	
	/**
	 * Provides an interface for picking objects that can pick 3d objects from a view or scene.
	 */
	public interface IPicker
	{
		/**
		 * Gets the collision object from the screen coordinates of the picking ray.
		 *
		 * @param x The x coordinate of the picking ray in screen-space.
		 * @param y The y coordinate of the picking ray in screen-space.
		 * @param view The view on which the picking object acts.
		 */
		function getViewCollision(x:Number, y:Number, view:View3D):PickingCollisionVO;
		
		/**
		 * Gets the collision object from the scene position and direction of the picking ray.
		 *
		 * @param position The position of the picking ray in scene-space.
		 * @param direction The direction of the picking ray in scene-space.
		 * @param scene The scene on which the picking object acts.
		 */
		function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO;
		
		/**
		 * Determines whether the picker takes account of the mouseEnabled properties of entities. Defaults to true.
		 */
		function get onlyMouseEnabled():Boolean;
		
		function set onlyMouseEnabled(value:Boolean):void;
		
		/**
		 * Disposes memory used by the IPicker object
		 */
		function dispose():void;
	}
}
