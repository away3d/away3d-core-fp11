package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.core.data.RenderableListItemPool;
	import away3d.core.math.Plane3D;
	import away3d.lights.LightBase;
	import away3d.materials.MaterialBase;
	import away3d.core.partition.NodeBase;
	import away3d.entities.Entity;

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
		protected var _skyBox : IRenderable;
		protected var _entities : Vector.<Entity>;
		protected var _opaqueRenderableHead : RenderableListItem;
		protected var _blendedRenderableHead : RenderableListItem;
		protected var _renderableListItemPool : RenderableListItemPool;
		protected var _lights : Vector.<LightBase>;
		protected var _numEntities : uint;
		protected var _numOpaques : uint;
		protected var _numBlended : uint;
		protected var _numLights : uint;
		protected var _numTriangles : uint;
		protected var _numMouseEnableds : uint;
		protected var _camera : Camera3D;

		/**
		 * Creates a new EntityCollector object.
		 */
		public function EntityCollector()
		{
			init();
		}

		private function init() : void
		{
//			_opaqueRenderables = new Vector.<IRenderable>();
//			_blendedRenderables = new Vector.<IRenderable>();
			_lights = new Vector.<LightBase>();
			_entities = new Vector.<Entity>();
			_renderableListItemPool = new RenderableListItemPool();
		}

		public function get numOpaques() : uint
		{
			return _numOpaques;
		}

		public function get numBlended() : uint
		{
			return _numBlended;
		}

		/**
		 * The camera that provides the visible frustum.
		 */
		public function get camera() : Camera3D
		{
			return _camera;
		}

		public function set camera(value : Camera3D) : void
		{
			_camera = value;
		}

		/**
		 * The amount of IRenderable objects that are mouse-enabled.
		 */
		public function get numMouseEnableds() : uint
		{
			return _numMouseEnableds;
		}

		/**
		 * The sky box object if encountered.
		 */
		public function get skyBox() : IRenderable
		{
			return _skyBox;
		}

		/**
		 * The list of opaque IRenderable objects that are considered potentially visible.
		 * @param value
		 */
		public function get opaqueRenderableHead() : RenderableListItem
		{
			return _opaqueRenderableHead;
		}

		public function set opaqueRenderableHead(value : RenderableListItem) : void
		{
			_opaqueRenderableHead = value;
		}

		/**
		 * The list of IRenderable objects that require blending and are considered potentially visible.
		 * @param value
		 */
		public function get blendedRenderableHead() : RenderableListItem
		{
			return _blendedRenderableHead;
		}

		public function set blendedRenderableHead(value : RenderableListItem) : void
		{
			_blendedRenderableHead = value;
		}

		/**
		 * The lights of which the affecting area intersects the camera's frustum.
		 */
		public function get lights() : Vector.<LightBase>
		{
			return _lights;
		}

		/**
		 * Clears all objects in the entity collector.
		 * @param time The time taken by the last render
		 * @param camera The camera that provides the frustum.
		 */
		public function clear() : void
		{
			_numTriangles = _numMouseEnableds = 0;
			_blendedRenderableHead = null;
			_opaqueRenderableHead = null;
			_renderableListItemPool.freeAll();
			if (_numLights > 0) _lights.length = _numLights = 0;
		}

		/**
		 * Returns true if the current node is at least partly in the frustum. If so, the partition node knows to pass on the traverser to its children.
		 *
		 * @param node The Partition3DNode object to frustum-test.
		 */
		override public function enterNode(node : NodeBase) : Boolean
		{
			return node.isInFrustum(_camera);
		}

		/**
		 * Adds a skybox to the potentially visible objects.
		 * @param renderable The skybox to add.
		 */
		override public function applySkyBox(renderable : IRenderable) : void
		{
			_skyBox = renderable;
		}

		/**
		 * Adds an IRenderable object to the potentially visible objects.
		 * @param renderable The IRenderable object to add.
		 */
		override public function applyRenderable(renderable : IRenderable) : void
		{
			var material : MaterialBase;

			if (renderable.mouseEnabled) ++_numMouseEnableds;
			_numTriangles += renderable.numTriangles;

			material = renderable.material;
			if (material) {
				var item : RenderableListItem = _renderableListItemPool.getItem();
				item.renderable = renderable;
				item.materialId = material._uniqueId;
				item.zIndex = renderable.zIndex;
				if (material.requiresBlending) {
					item.next = _blendedRenderableHead;
					_blendedRenderableHead = item;
					++_numBlended;
				}
				else {
					item.next = _opaqueRenderableHead;
					_opaqueRenderableHead = item;
					++_numOpaques;
				}
			}
		}

		/**
		 * Adds a light to the potentially visible objects.
		 * @param light The light to add.
		 */
		override public function applyLight(light : LightBase) : void
		{
			_lights[_numLights++] = light;
		}

		/**
		 * The total number of triangles collected, and which will be pushed to the render engine.
		 */
		public function get numTriangles() : uint
		{
			return _numTriangles;
		}

		/**
		 * @inheritDoc
		 */
		override public function applyEntity(entity : Entity) : void
		{
			_entities[_numEntities++] = entity;
		}

		/**
		 * Cleans up any data at the end of a frame.
		 */
		public function cleanUp() : void
		{
			if (_numEntities > 0) {
				for (var i : uint = 0; i < _numEntities; ++i)
					_entities[i].popModelViewProjection();
				_entities.length = _numEntities = 0;
			}
		}
	}
}