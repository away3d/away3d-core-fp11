package away3d.core.traverse {
	import away3d.entities.Camera3D;
	import away3d.core.partition.NodeBase;
	import away3d.entities.IEntity;

	public interface ICollector {
		function clear():void;

		function enterNode(node:NodeBase):Boolean;

		function applyDirectionalLight(entity:IEntity):void;

		function applyEntity(entity:IEntity):void;

		function applyLightProbe(entity:IEntity):void;

		function applyPointLight(entity:IEntity):void;
	}
}
