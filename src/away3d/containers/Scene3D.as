package away3d.containers
{
	import flash.events.EventDispatcher;
	import away3d.arcane;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.core.partition.Partition3D;
	import away3d.core.partition.NodeBase;
	import away3d.entities.Entity;

	use namespace arcane;

	/**
	 * The Scene3D class represents an independent 3D scene in which 3D objects can be created and manipulated.
	 * Multiple Scene3D instances can be created in the same SWF file.
	 *
	 * Scene management happens through the scene graph, which is exposed using addChild and removeChild methods.
	 * Internally, the Scene3D object also manages any space partition objects that have been assigned to objects in
	 * the scene graph, of which there is at least 1.
	 */
	public class Scene3D extends EventDispatcher
	{
		private var _sceneGraphRoot : ObjectContainer3D;
		private var _partitions : Vector.<Partition3D>;

		/**
		 * Creates a new Scene3D object.
		 */
		public function Scene3D()
		{
			_partitions = new Vector.<Partition3D>();
			_sceneGraphRoot = new ObjectContainer3D();
			_sceneGraphRoot.scene = this;
			_sceneGraphRoot.partition = new Partition3D(new NodeBase());
		}

		/**
		 * Sends a PartitionTraverser object down the scene partitions
		 * @param traverser The traverser which will pass through the partitions.
		 *
		 * @see away3d.core.traverse.PartitionTraverser
		 * @see away3d.core.traverse.EntityCollector
		 */
		public function traversePartitions(traverser : PartitionTraverser) : void
		{
			var i : uint;
			var len : uint = _partitions.length;

			traverser.scene = this;

			while (i < len)
				_partitions[i++].traverse(traverser);
		}

		/**
		 * The root partition to be used by the Scene3D.
		 */
		public function get partition() : Partition3D
		{
			return _sceneGraphRoot.partition;
		}

		public function set partition(value : Partition3D) : void
		{
			_sceneGraphRoot.partition = value;
		}

		/**
		 * Adds a child to the scene's root.
		 * @param child The child to be added to the scene
		 * @return A reference to the added child.
		 */
		public function addChild(child : ObjectContainer3D) : ObjectContainer3D
		{
			return _sceneGraphRoot.addChild(child);
		}

		/**
		 * Removes a child from the scene's root.
		 * @param child The child to be removed from the scene.
		 */
		public function removeChild(child : ObjectContainer3D) : void
		{
			_sceneGraphRoot.removeChild(child);
		}

		/**
		 * Retrieves the child with the given index
		 * @param index The index for the child to be retrieved.
		 * @return The child with the given index
		 */
		public function getChildAt(index : uint) : ObjectContainer3D
		{
			return _sceneGraphRoot.getChildAt(index);
		}

		/**
		 * The amount of children directly contained by the scene.
		 */
		public function get numChildren() : uint
		{
			return _sceneGraphRoot.numChildren;
		}

		/**
		 * When an entity is added to the scene, or to one of its children, add it to the partition tree.
		 * @private
		 */
		arcane function registerEntity(entity : Entity) : void
		{
			var partition : Partition3D = entity.implicitPartition;
			addPartitionUnique(partition);
			
			partition.markForUpdate(entity);
		}

		/**
		 * When an entity is removed from the scene, or from one of its children, remove it from its former partition tree.
		 * @private
		 */
		arcane function unregisterEntity(entity : Entity) : void
		{
			entity.implicitPartition.removeEntity(entity);
		}

		/**
		 * When an entity has moved or changed size, update its position in its partition tree.
		 */
		arcane function invalidateEntityBounds(entity : Entity) : void
		{
			entity.implicitPartition.markForUpdate(entity);
		}

		/**
		 * When a partition is assigned to an object somewhere in the scene graph, add the partition to the list if it isn't in there yet
		 */
		arcane function registerPartition(entity : Entity) : void
		{
			addPartitionUnique(entity.implicitPartition);
		}

		/**
		 * When a partition is removed from an object somewhere in the scene graph, remove the partition from the list if it isn't in there yet
		 */
		arcane function unregisterPartition(entity : Entity) : void
		{
			// todo: wait... is this even correct?
			// shouldn't we check the number of children in implicitPartition and remove partition if 0?
			entity.implicitPartition.removeEntity(entity);
		}

		/**
		 * Add a partition if it's not in the list
		 */
		protected function addPartitionUnique(partition : Partition3D) : void
		{
			if (_partitions.indexOf(partition) == -1)
				_partitions.push(partition);
		}
	}
}
