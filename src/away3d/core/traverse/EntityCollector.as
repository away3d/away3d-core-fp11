package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.EntityListItem;
	import away3d.core.data.EntityListItemPool;
	import away3d.core.data.RenderableListItem;
	import away3d.core.data.RenderableListItemPool;
	import away3d.core.math.Plane3D;
	import away3d.core.partition.NodeBase;
	import away3d.entities.Entity;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;
	import away3d.materials.MaterialBase;
	
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * The EntityCollector class is a traverser for scene partitions that collects all scene graph entities that are
	 * considered potientially visible.
	 *
	 * @see away3d.partition.Partition3D
	 * @see away3d.partition.Entity
	 */
	public class EntityCollector extends PartitionTraverser
	{
		protected var _skyBox:IRenderable;
		protected var _opaqueRenderableHead:RenderableListItem;
		protected var _blendedRenderableHead:RenderableListItem;
		private var _entityHead:EntityListItem;
		protected var _renderableListItemPool:RenderableListItemPool;
		protected var _entityListItemPool:EntityListItemPool;
		protected var _lights:Vector.<LightBase>;
		private var _directionalLights:Vector.<DirectionalLight>;
		private var _pointLights:Vector.<PointLight>;
		private var _lightProbes:Vector.<LightProbe>;
		protected var _numEntities:uint;
		protected var _numLights:uint;
		protected var _numTriangles:uint;
		protected var _numMouseEnableds:uint;
		protected var _camera:Camera3D;
		private var _numDirectionalLights:uint;
		private var _numPointLights:uint;
		private var _numLightProbes:uint;
		protected var _cameraForward:Vector3D;
		private var _customCullPlanes:Vector.<Plane3D>;
		private var _cullPlanes:Vector.<Plane3D>;
		private var _numCullPlanes:uint;
		
		/**
		 * Creates a new EntityCollector object.
		 */
		public function EntityCollector()
		{
			init();
		}
		
		private function init():void
		{
			_lights = new Vector.<LightBase>();
			_directionalLights = new Vector.<DirectionalLight>();
			_pointLights = new Vector.<PointLight>();
			_lightProbes = new Vector.<LightProbe>();
			_renderableListItemPool = new RenderableListItemPool();
			_entityListItemPool = new EntityListItemPool();
		}
		
		/**
		 * The camera that provides the visible frustum.
		 */
		public function get camera():Camera3D
		{
			return _camera;
		}
		
		public function set camera(value:Camera3D):void
		{
			_camera = value;
			_entryPoint = _camera.scenePosition;
			_cameraForward = _camera.forwardVector;
			_cullPlanes = _camera.frustumPlanes;
		}
		
		public function get cullPlanes():Vector.<Plane3D>
		{
			return _customCullPlanes;
		}
		
		public function set cullPlanes(value:Vector.<Plane3D>):void
		{
			_customCullPlanes = value;
		}
		
		/**
		 * The amount of IRenderable objects that are mouse-enabled.
		 */
		public function get numMouseEnableds():uint
		{
			return _numMouseEnableds;
		}
		
		/**
		 * The sky box object if encountered.
		 */
		public function get skyBox():IRenderable
		{
			return _skyBox;
		}
		
		/**
		 * The list of opaque IRenderable objects that are considered potentially visible.
		 * @param value
		 */
		public function get opaqueRenderableHead():RenderableListItem
		{
			return _opaqueRenderableHead;
		}
		
		public function set opaqueRenderableHead(value:RenderableListItem):void
		{
			_opaqueRenderableHead = value;
		}
		
		/**
		 * The list of IRenderable objects that require blending and are considered potentially visible.
		 * @param value
		 */
		public function get blendedRenderableHead():RenderableListItem
		{
			return _blendedRenderableHead;
		}
		
		public function set blendedRenderableHead(value:RenderableListItem):void
		{
			_blendedRenderableHead = value;
		}
		
		public function get entityHead():EntityListItem
		{
			return _entityHead;
		}
		
		/**
		 * The lights of which the affecting area intersects the camera's frustum.
		 */
		public function get lights():Vector.<LightBase>
		{
			return _lights;
		}
		
		public function get directionalLights():Vector.<DirectionalLight>
		{
			return _directionalLights;
		}
		
		public function get pointLights():Vector.<PointLight>
		{
			return _pointLights;
		}
		
		public function get lightProbes():Vector.<LightProbe>
		{
			return _lightProbes;
		}
		
		/**
		 * Clears all objects in the entity collector.
		 */
		public function clear():void
		{
			if (_camera) {
				_entryPoint = _camera.scenePosition;
				_cameraForward = _camera.forwardVector;
			}
			_cullPlanes = _customCullPlanes? _customCullPlanes : (_camera? _camera.frustumPlanes : null);
			_numCullPlanes = _cullPlanes? _cullPlanes.length : 0;
			_numTriangles = _numMouseEnableds = 0;
			_blendedRenderableHead = null;
			_opaqueRenderableHead = null;
			_entityHead = null;
			_renderableListItemPool.freeAll();
			_entityListItemPool.freeAll();
			_skyBox = null;
			if (_numLights > 0)
				_lights.length = _numLights = 0;
			if (_numDirectionalLights > 0)
				_directionalLights.length = _numDirectionalLights = 0;
			if (_numPointLights > 0)
				_pointLights.length = _numPointLights = 0;
			if (_numLightProbes > 0)
				_lightProbes.length = _numLightProbes = 0;
		}
		
		/**
		 * Returns true if the current node is at least partly in the frustum. If so, the partition node knows to pass on the traverser to its children.
		 *
		 * @param node The Partition3DNode object to frustum-test.
		 */
		override public function enterNode(node:NodeBase):Boolean
		{
			var enter:Boolean = _collectionMark != node._collectionMark && node.isInFrustum(_cullPlanes, _numCullPlanes);
			node._collectionMark = _collectionMark;
			return enter;
		}
		
		/**
		 * Adds a skybox to the potentially visible objects.
		 * @param renderable The skybox to add.
		 */
		override public function applySkyBox(renderable:IRenderable):void
		{
			_skyBox = renderable;
		}
		
		/**
		 * Adds an IRenderable object to the potentially visible objects.
		 * @param renderable The IRenderable object to add.
		 */
		override public function applyRenderable(renderable:IRenderable):void
		{
			var material:MaterialBase;
			var entity:Entity = renderable.sourceEntity;
			if (renderable.mouseEnabled)
				++_numMouseEnableds;
			_numTriangles += renderable.numTriangles;
			
			material = renderable.material;
			if (material) {
				var item:RenderableListItem = _renderableListItemPool.getItem();
				item.renderable = renderable;
				item.materialId = material._uniqueId;
				item.renderOrderId = material._renderOrderId;
				item.cascaded = false;
				var dx:Number = _entryPoint.x - entity.x;
				var dy:Number = _entryPoint.y - entity.y;
				var dz:Number = _entryPoint.z - entity.z;
				// project onto camera's z-axis
				item.zIndex = dx*_cameraForward.x + dy*_cameraForward.y + dz*_cameraForward.z + entity.zOffset;
				item.renderSceneTransform = renderable.getRenderSceneTransform(_camera);
				if (material.requiresBlending) {
					item.next = _blendedRenderableHead;
					_blendedRenderableHead = item;
				} else {
					item.next = _opaqueRenderableHead;
					_opaqueRenderableHead = item;
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function applyEntity(entity:Entity):void
		{
			++_numEntities;
			
			var item:EntityListItem = _entityListItemPool.getItem();
			item.entity = entity;
			
			item.next = _entityHead;
			_entityHead = item;
		}
		
		/**
		 * Adds a light to the potentially visible objects.
		 * @param light The light to add.
		 */
		override public function applyUnknownLight(light:LightBase):void
		{
			_lights[_numLights++] = light;
		}
		
		override public function applyDirectionalLight(light:DirectionalLight):void
		{
			_lights[_numLights++] = light;
			_directionalLights[_numDirectionalLights++] = light;
		}
		
		override public function applyPointLight(light:PointLight):void
		{
			_lights[_numLights++] = light;
			_pointLights[_numPointLights++] = light;
		}
		
		override public function applyLightProbe(light:LightProbe):void
		{
			_lights[_numLights++] = light;
			_lightProbes[_numLightProbes++] = light;
		}
		
		/**
		 * The total number of triangles collected, and which will be pushed to the render engine.
		 */
		public function get numTriangles():uint
		{
			return _numTriangles;
		}
		
		/**
		 * Cleans up any data at the end of a frame.
		 */
		public function cleanUp():void
		{
		}
	}
}
