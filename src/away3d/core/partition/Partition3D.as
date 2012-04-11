package away3d.core.partition
{
	import away3d.arcane;
	import away3d.core.traverse.EntityCollector;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.core.traverse.ShadowCasterCollector;
	import away3d.entities.Entity;
	import flash.utils.Dictionary;

	use namespace arcane;

	/**
	 * Partition3D is the core of a space partition system. The space partition system typically subdivides the 3D scene
	 * hierarchically into a number of non-overlapping subspaces, forming a tree data structure. This is used to more
	 * efficiently perform frustum culling, potential visibility determination and collision detection.
	 */
	public class Partition3D
	{
		private var _rootNode : NodeBase;
		private var _updatesMade : Boolean;
		private var _updateQueue : EntityNode;
		private var _updateDict:Dictionary = new Dictionary;
		private var _deleteVector:Vector.<Object> = new Vector.<Object>;
		/**
		 * Creates a new Partition3D object.
		 * @param rootNode The root node of the space partition system. This will indicate which type of data structure will be used.
		 */
		public function Partition3D(rootNode : NodeBase)
		{
			_rootNode = rootNode || new NullNode();
		}

		public function get showDebugBounds() : Boolean
		{
			return _rootNode.showDebugBounds;
		}

		public function set showDebugBounds(value : Boolean) : void
		{

		}

		/**
		 * Sends a traverser through the partition tree.
		 * @param traverser
		 *
		 * @see away3d.core.traverse.PartitionTraverser
		 */
		public function traverse(traverser : PartitionTraverser) : void
		{
			if (_updatesMade && traverser is EntityCollector && !(traverser is ShadowCasterCollector))
				updateEntities();
			
			_rootNode.acceptTraverser(traverser);
		}

		/**
		 * Mark a scene graph entity for updating. This will trigger a reassignment within the tree, based on the
		 * object's bounding box, upon the next traversal.
		 * @param entity The entity to be updated in the tree.
		 */
		arcane function markForUpdate(entity : Entity) : void
		{
			var node : EntityNode = entity.getEntityPartitionNode();
		
			_updateDict[node] = true;
			_updatesMade = true;
		}

		/**
		 * Removes an entity from the partition tree.
		 * @param entity The entity to be removed.
		 */
		arcane function removeEntity(entity : Entity) : void
		{
			var node : EntityNode = entity.getEntityPartitionNode();
			var t : EntityNode;
			
			node.removeFromParent();
			delete _updateDict[node];
		}
		
		/**
		 * Updates all entities that were marked for update.
		 */
		private function updateEntities() : void
		{
			var node : EntityNode;
			var targetNode : NodeBase;
			
			for (var i:Object in _updateDict)
			{
				node = i as EntityNode;
				targetNode = _rootNode.findPartitionForEntity(node.entity);
				if (node.parent != targetNode) {
					node.removeFromParent();					
					targetNode.addNode(node);
				}
				//call an internal update on the entity to fire any attached logic
				node.entity.internalUpdate();
				_deleteVector.push(i);
			}
			for (var k:uint = 0; k < _deleteVector.length; k++)
			{
				delete _updateDict[_deleteVector[k]];
			}
			_deleteVector.length = 0;
			_updatesMade = false;
		}
	}
}