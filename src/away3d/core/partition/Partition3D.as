package away3d.core.partition
{
	import away3d.arcane;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Entity;
	
	use namespace arcane;
	
	/**
	 * Partition3D is the core of a space partition system. The space partition system typically subdivides the 3D scene
	 * hierarchically into a number of non-overlapping subspaces, forming a tree data structure. This is used to more
	 * efficiently perform frustum culling, potential visibility determination and collision detection.
	 */
	public class Partition3D
	{
		protected var _rootNode:NodeBase;
		private var _updatesMade:Boolean;
		private var _updateQueue:EntityNode;
		
		/**
		 * Creates a new Partition3D object.
		 * @param rootNode The root node of the space partition system. This will indicate which type of data structure will be used.
		 */
		public function Partition3D(rootNode:NodeBase)
		{
			_rootNode = rootNode || new NullNode();
		}
		
		public function get showDebugBounds():Boolean
		{
			return _rootNode.showDebugBounds;
		}
		
		public function set showDebugBounds(value:Boolean):void
		{
			_rootNode.showDebugBounds = value;
		}
		
		/**
		 * Sends a traverser through the partition tree.
		 * @param traverser
		 *
		 * @see away3d.core.traverse.PartitionTraverser
		 */
		public function traverse(traverser:PartitionTraverser):void
		{
			if (_updatesMade)
				updateEntities();
			
			++PartitionTraverser._collectionMark;
			
			_rootNode.acceptTraverser(traverser);
		}
		
		/**
		 * Mark a scene graph entity for updating. This will trigger a reassignment within the tree, based on the
		 * object's bounding box, upon the next traversal.
		 * @param entity The entity to be updated in the tree.
		 */
		arcane function markForUpdate(entity:Entity):void
		{
			var node:EntityNode = entity.getEntityPartitionNode();
			// already marked to be updated
			var t:EntityNode = _updateQueue;
			
			// if already marked for update
			while (t) {
				if (node == t)
					return;
				
				t = t._updateQueueNext;
			}
			
			node._updateQueueNext = _updateQueue;
			
			_updateQueue = node;
			_updatesMade = true;
		}
		
		/**
		 * Removes an entity from the partition tree.
		 * @param entity The entity to be removed.
		 */
		arcane function removeEntity(entity:Entity):void
		{
			var node:EntityNode = entity.getEntityPartitionNode();
			var t:EntityNode;
			
			node.removeFromParent();
			
			// remove from update list if it's in
			if (node == _updateQueue)
				_updateQueue = node._updateQueueNext;
			else {
				t = _updateQueue;
				while (t && t._updateQueueNext != node)
					t = t._updateQueueNext;
				if (t)
					t._updateQueueNext = node._updateQueueNext;
			}
			
			node._updateQueueNext = null;
			
			// any updates have been made undone
			if (!_updateQueue)
				_updatesMade = false;
		}
		
		/**
		 * Updates all entities that were marked for update.
		 */
		private function updateEntities():void
		{
			var node:EntityNode = _updateQueue;
			var targetNode:NodeBase;
			var t:EntityNode;
			
			// clear updateQueue early to allow for newly marked entity updates
			_updateQueue = null;
			_updatesMade = false;
			
			do {
				targetNode = _rootNode.findPartitionForEntity(node.entity);
				
				// if changed, find and attach the mesh node to the best suited partition node
				if (node.parent != targetNode) {
					if (node)
						node.removeFromParent();
					
					targetNode.addNode(node);
				}
				
				t = node._updateQueueNext;
				node._updateQueueNext = null;
				
				//call an internal update on the entity to fire any attached logic
				node.entity.internalUpdate();
				
			} while ((node = t) != null);
		}
	}
}
