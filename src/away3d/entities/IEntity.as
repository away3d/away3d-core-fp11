package away3d.entities {
	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.Scene3D;
	import away3d.controllers.ControllerBase;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.Partition3D;
	import away3d.core.pick.IPickingCollider;
	import away3d.core.pick.PickingCollisionVO;
	import away3d.core.render.IRenderer;
	import away3d.library.assets.IAsset;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public interface IEntity extends IAsset {
		function get x():Number;

		function get y():Number;

		function get z():Number;

		function get rotationX():Number;

		function get rotationY():Number;

		function get rotationZ():Number;

		function get scaleX():Number;

		function get scaleY():Number;

		function get scaleZ():Number;

		function get bounds():BoundingVolumeBase;

		function get castsShadows():Boolean;

		function set castsShadows(value:Boolean):void;

		function get inverseSceneTransform():Matrix3D;

		function get partitionNode():EntityNode;

		function get pickingCollider():IPickingCollider;

		function get scene():Scene3D;

		function get scenePosition():Vector3D;

		function get sceneTransform():Matrix3D;

		function get worldBounds():BoundingVolumeBase;

		function get zOffset():Number;

		function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Boolean;

		function lookAt(target:Vector3D, upAxis:Vector3D = null):void;

		function get pickingCollisionVO():PickingCollisionVO;

		function get controller():ControllerBase;

		function get assignedPartition():Partition3D;

		function testCollision(shortestCollisionDistance:Number, findClosest:Boolean):Boolean;

		function get isMouseEnabled():Boolean;

		function isVisible():Boolean;

		function internalUpdate():void;

		/**
		 * The transformation matrix that transforms from model to world space, adapted with any special operations needed to render.
		 * For example, assuring certain alignedness which is not inherent in the scene transform. By default, this would
		 * return the scene transform.
		 */
		function getRenderSceneTransform(camera:Camera3D):Matrix3D;

		function collectRenderables(renderer:IRenderer):void;
	}
}
