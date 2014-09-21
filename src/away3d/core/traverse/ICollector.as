package away3d.core.traverse
{
	import away3d.containers.Scene3D;
	import away3d.core.partition.NodeBase;
	import away3d.core.pool.EntityListItem;
	import away3d.entities.Camera3D;
	import away3d.entities.IEntity;

	import flash.geom.Vector3D;

	public interface ICollector
	{
		function clear():void;

		function enterNode(node:NodeBase):Boolean;

		function applyDirectionalLight(entity:IEntity):void;

		function applyEntity(entity:IEntity):void;

		function applyLightProbe(entity:IEntity):void;

		function applyPointLight(entity:IEntity):void;

		function applySkybox(entity:IEntity):void;

		function get entityHead():EntityListItem;

		function get entryPoint():Vector3D;

		function get camera():Camera3D;

		function set camera(value:Camera3D):void;

		function get scene():Scene3D;

		function set scene(scene:Scene3D):void;
	}
}
