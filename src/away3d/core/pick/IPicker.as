package away3d.core.pick
{
	import away3d.containers.*;
	
	import flash.geom.*;
	
	/**
	 * @author robbateman
	 */
	public interface IPicker
	{
		function getViewCollision(x:Number, y:Number, view:View3D):PickingCollisionVO;
		
		function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO;
	}
}
