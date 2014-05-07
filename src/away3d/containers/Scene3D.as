package away3d.containers
{
	import away3d.arcane;
	import away3d.core.base.Object3D;
	import away3d.core.partition.NodeBase;
	import away3d.core.partition.Partition3D;
	import away3d.core.traverse.ICollector;
	import away3d.entities.IEntity;
	import away3d.events.Scene3DEvent;
	
	import flash.events.EventDispatcher;
	
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
		private var _expandedPartitions:Vector.<Partition3D> = new Vector.<Partition3D>();
		private var _partitions:Vector.<Partition3D> = new Vector.<Partition3D>();

		arcane var _sceneGraphRoot:ObjectContainer3D;
		arcane var _collectionMark:uint = 0;

		/**
		 * Creates a new Scene3D object.
		 */
		public function Scene3D()
		{
			_sceneGraphRoot = new ObjectContainer3D();
			_sceneGraphRoot.setScene(this);
			_sceneGraphRoot.isRoot = true;
			_sceneGraphRoot.partition = new Partition3D(new NodeBase());
		}
		
		/**
		 * Sends a PartitionTraverser object down the scene partitions
		 * @param traverser The traverser which will pass through the partitions.
		 *
		 * @see away3d.core.traverse.PartitionTraverser
		 * @see away3d.core.traverse.EntityCollector
		 */
		public function traversePartitions(traverser:ICollector):void
		{
			var i:uint;
			var len:uint = _partitions.length;
			
			traverser.scene = this;
			
			while (i < len) {
				_collectionMark++;
				_partitions[i++].traverse(traverser);
			}
		}
		
		/**
		 * The root partition to be used by the Scene3D.
		 */
		public function get partition():Partition3D
		{
			return _sceneGraphRoot.partition;
		}
		
		public function set partition(value:Partition3D):void
		{
			_sceneGraphRoot.partition = value;
			
			dispatchEvent(new Scene3DEvent(Scene3DEvent.PARTITION_CHANGED, _sceneGraphRoot));
		}
		
		public function contains(child:Object3D):Boolean
		{
			return _sceneGraphRoot.contains(child);
		}
		
		/**
		 * Adds a child to the scene's root.
		 * @param child The child to be added to the scene
		 * @return A reference to the added child.
		 */
		public function addChild(child:Object3D):Object3D
		{
			return _sceneGraphRoot.addChild(child);
		}
		
		/**
		 * Removes a child from the scene's root.
		 * @param child The child to be removed from the scene.
		 */
		public function removeChild(child:Object3D):void
		{
			_sceneGraphRoot.removeChild(child);
		}
		
		/**
		 * Removes a child from the scene's root.
		 * @param index Index of child to be removed from the scene.
		 */
		public function removeChildAt(index:uint):void
		{
			_sceneGraphRoot.removeChildAt(index);
		}
		
		/**
		 * Retrieves the child with the given index
		 * @param index The index for the child to be retrieved.
		 * @return The child with the given index
		 */
		public function getChildAt(index:uint):Object3D
		{
			return _sceneGraphRoot.getChildAt(index);
		}
		
		/**
		 * The amount of children directly contained by the scene.
		 */
		public function get numChildren():uint
		{
			return _sceneGraphRoot.numChildren;
		}
		
		/**
		 * When an entity is added to the scene, or to one of its children, add it to the partition tree.
		 * @private
		 */
		arcane function registerEntity(object:Object3D):void
		{
			if (object.partition)
				registerPartition(object.partition);

			if (object.isEntity)
				object.assignedPartition.markForUpdate(object);
		}
		
		/**
		 * When an entity is removed from the scene, or from one of its children, remove it from its former partition tree.
		 * @private
		 */
		arcane function unregisterEntity(object:Object3D):void
		{
			if (object.partition)
				unregisterPartition(object.partition);

			if (object.isEntity)
				object.assignedPartition.removeEntity(object as IEntity);
		}

		/**
		 * When a partition is assigned to an object somewhere in the scene graph, add the partition to the list if it isn't in there yet
		 */
		arcane function registerPartition(partition:Partition3D):void
		{
			_expandedPartitions.push(partition);
			if (_partitions.indexOf(partition) == -1)
				_partitions.push(partition);
		}
		
		/**
		 * When a partition is removed from an object somewhere in the scene graph, remove the partition from the list
		 */
		arcane function unregisterPartition(partition:Partition3D):void
		{
			_expandedPartitions.splice(_expandedPartitions.indexOf(partition), 1);

			//if no more partition references found, remove from partitions array
			if (_expandedPartitions.indexOf(partition) == -1)
				_partitions.splice(_partitions.indexOf(partition), 1);
		}
	}
}
