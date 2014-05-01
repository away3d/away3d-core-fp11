package away3d.core.traverse {
	import away3d.arcane;
	import away3d.entities.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.core.data.EntityListItem;
	import away3d.core.data.EntityListItemPool;
	import away3d.core.math.Plane3D;
	import away3d.core.partition.NodeBase;
	import away3d.entities.IEntity;

	use namespace arcane;

	public class CollectorBase implements ICollector {
		public var scene:Scene3D;
		public var customCullPlanes:Vector.<Plane3D>;
		public var cullPlanes:Vector.<Plane3D>;
		public var numCullPlanes:Number = 0;
		public var entityHead:EntityListItem;
		public var numEntities:Number = 0;
		public var numInteractiveEntities:Number = 0;

		protected var entityListItemPool:EntityListItemPool;

		private var _camera:Camera3D;

		public function CollectorBase() {
			entityListItemPool = new EntityListItemPool();
		}

		public function get camera():Camera3D {
			return _camera;
		}

		public function set camera(camera:Camera3D):void {
			_camera = camera;
			cullPlanes = _camera.frustumPlanes;
		}

		public function clear():void {
			numEntities = numInteractiveEntities = 0;
			cullPlanes = customCullPlanes ? customCullPlanes : (_camera ? _camera.frustumPlanes : null);
			numCullPlanes = cullPlanes ? cullPlanes.length : 0;
			entityHead = null;
			entityListItemPool.freeAll();
		}

		public function enterNode(node:NodeBase):Boolean {
			var enter:Boolean = scene._collectionMark != node._collectionMark && node.isInFrustum(cullPlanes, numCullPlanes);

			node._collectionMark = scene._collectionMark;

			return enter;
		}

		public function applyDirectionalLight(entity:IEntity):void {
		}

		public function applyEntity(entity:IEntity):void {
			numEntities++;

			if (entity.isMouseEnabled)
				this.numInteractiveEntities++;

			var item:EntityListItem = entityListItemPool.getItem();
			item.entity = entity;

			item.next = entityHead;
			entityHead = item;
		}

		public function applyLightProbe(entity:IEntity):void {
		}

		public function applyPointLight(entity:IEntity):void {
		}
	}
}
