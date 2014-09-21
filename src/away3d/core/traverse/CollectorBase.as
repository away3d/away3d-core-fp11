package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.entities.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.core.pool.EntityListItem;
	import away3d.core.pool.EntityListItemPool;
	import away3d.core.geom.Plane3D;
	import away3d.core.partition.NodeBase;
	import away3d.entities.IEntity;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class CollectorBase implements ICollector
	{
		public var customCullPlanes:Vector.<Plane3D>;
		public var cullPlanes:Vector.<Plane3D>;
		public var numCullPlanes:Number = 0;
		public var numEntities:Number = 0;
		public var numInteractiveEntities:Number = 0;

		protected var _entityHead:EntityListItem;
		protected var entityListItemPool:EntityListItemPool;

		private var _scene:Scene3D;
		private var _camera:Camera3D;
		private var _entryPoint:Vector3D;

		public function CollectorBase()
		{
			entityListItemPool = new EntityListItemPool();
		}

		public function get camera():Camera3D
		{
			return _camera;
		}

		public function set camera(camera:Camera3D):void
		{
			_camera = camera;
			_entryPoint = camera.scenePosition;
			cullPlanes = _camera.frustumPlanes;
		}

		public function clear():void
		{
			numEntities = numInteractiveEntities = 0;
			cullPlanes = customCullPlanes ? customCullPlanes : (_camera ? _camera.frustumPlanes : null);
			numCullPlanes = cullPlanes ? cullPlanes.length : 0;
			_entityHead = null;
			entityListItemPool.freeAll();
		}

		public function enterNode(node:NodeBase):Boolean
		{
			var enter:Boolean = scene._collectionMark != node._collectionMark && node.isInFrustum(cullPlanes, numCullPlanes);

			node._collectionMark = scene._collectionMark;

			return enter;
		}


		public function applyEntity(entity:IEntity):void
		{
			numEntities++;

			if (entity.isMouseEnabled)
				this.numInteractiveEntities++;

			var item:EntityListItem = entityListItemPool.getItem();
			item.entity = entity;

			item.next = _entityHead;
			_entityHead = item;
		}

		public function get entityHead():EntityListItem
		{
			return _entityHead;
		}

		public function get entryPoint():Vector3D
		{
			return _entryPoint;
		}

		public function get scene():Scene3D
		{
			return _scene;
		}

		public function set scene(value:Scene3D):void
		{
			_scene = value;
		}

		public function applyDirectionalLight(entity:IEntity):void
		{
		}

		public function applyLightProbe(entity:IEntity):void
		{
			//don't do anything here
		}

		public function applyPointLight(entity:IEntity):void
		{
			//don't do anything here
		}

		public function applySkybox(entity:IEntity):void
		{
			//don't do anything here
		}
	}
}
