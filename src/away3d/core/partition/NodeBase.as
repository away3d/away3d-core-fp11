package away3d.core.partition
{
	import away3d.core.math.Plane3D;
	import away3d.core.traverse.ICollector;
	import away3d.entities.IEntity;

	import flash.geom.Vector3D;
	
	import away3d.arcane;

	use namespace arcane;
	
	/**
	 * The NodeBase class is an abstract base class for any type of space partition tree node. The concrete
	 * subtype will control the creation of its child nodes, which are necessarily of the same type. The exception is
	 * the creation of leaf entity nodes, which is handled by the Partition3D class.
	 *
	 * @see away3d.partition.EntityNode
	 * @see away3d.partition.Partition3D
	 * @see away3d.containers.Scene3D
	 */
	public class NodeBase
	{
		private var _boundsChildrenVisible:Boolean;
		private var _explicitBoundsVisible:Boolean;
		private var _implicitBoundsVisible:Boolean;
		arcane var _parent:NodeBase;
		protected var _childNodes:Vector.<NodeBase>;
		protected var _numChildNodes:uint;
		protected var _boundsPrimitive:IEntity;

		arcane var _numEntities:int;
		arcane var _collectionMark:uint;
		
		/**
		 * Creates a new NodeBase object.
		 */
		public function NodeBase()
		{
			_childNodes = new Vector.<NodeBase>();
		}

		public function get boundsVisible():Boolean
		{
			return _explicitBoundsVisible;
		}

		public function set boundsVisible(value:Boolean):void
		{
			if (_explicitBoundsVisible == value) return;

			_explicitBoundsVisible = value;

			updateImplicitBoundsVisible(_parent? _parent.boundsChildrenVisible : false);

		}

		public function get boundsChildrenVisible():Boolean
		{
			return _boundsChildrenVisible;
		}

		public function set boundsChildrenVisible(value:Boolean):void
		{
			if (_boundsChildrenVisible == value)	return;

			_boundsChildrenVisible = value;

			for (var i:Number = 0; i < _numChildNodes; ++i)
				_childNodes[i].updateImplicitBoundsVisible(_boundsChildrenVisible);
		}

		
		/**
		 * The parent node. Null if this node is the root.
		 */
		public function get parent():NodeBase
		{
			return _parent;
		}
		
		/**
		 * Adds a node to the tree. By default, this is used for both static as dynamic nodes, but for some data
		 * structures such as BSP trees, it can be more efficient to only use this for dynamic nodes, and add the
		 * static child nodes using custom links.
		 *
		 * @param node The node to be added as a child of the current node.
		 */
		arcane function addNode(node:NodeBase):void
		{
			node._parent = this;
			_numEntities += node._numEntities;
			_childNodes[_numChildNodes++] = node;

			node.updateImplicitBoundsVisible(this.boundsChildrenVisible);
			
			// update numEntities in the tree
			var numEntities:int = node._numEntities;
			node = this;
			
			do
				node._numEntities += numEntities;
			while ((node = node._parent) != null);
		}
		
		/**
		 * Removes a child node from the tree.
		 * @param node The child node to be removed.
		 */
		arcane function removeNode(node:NodeBase):void
		{
			// a bit faster than splice(i, 1), works only if order is not important
			// override item to be removed with the last in the list, then remove that last one
			// Also, the "real partition nodes" of the tree will always remain unmoved, first in the list, so if there's
			// an order dependency for them, it's still okay
			var index:uint = _childNodes.indexOf(node);
			_childNodes[index] = _childNodes[--_numChildNodes];
			_childNodes.pop();
			
			// update numEntities in the tree
			var numEntities:int = node._numEntities;
			node = this;
			
			do
				node._numEntities -= numEntities;
			while ((node = node._parent) != null);
		}

		arcane function updateImplicitBoundsVisible(value:Boolean):void
		{
			if (_implicitBoundsVisible == _explicitBoundsVisible || value) return;

			_implicitBoundsVisible = _explicitBoundsVisible || value;

			updateEntityBounds();

			for (var i:Number = 0; i < _numChildNodes; ++i)
				_childNodes[i].updateImplicitBoundsVisible(this._boundsChildrenVisible);
		}

		/**
		 * Tests if the current node is at least partly inside the frustum.
		 * @param viewProjectionRaw The raw data of the view projection matrix
		 *
		 * @return Whether or not the node is at least partly inside the view frustum.
		 */
		public function isInFrustum(planes:Vector.<Plane3D>, numPlanes:int):Boolean
		{
			return true;
		}
		
		/**
		 * Tests if the current node is intersecting with a ray.
		 * @param rayPosition The starting position of the ray
		 * @param rayDirection The direction vector of the ray
		 *
		 * @return Whether or not the node is at least partly intersecting the ray.
		 */
		public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Boolean
		{
			return true;
		}

		public function isCastingShadow():Boolean
		{
			return true;
		}
		
		/**
		 * Finds the partition that contains (or should contain) the given entity.
		 */
		public function findPartitionForEntity(entity:IEntity):NodeBase
		{
			return this;
		}
		
		/**
		 * Allows the traverser to visit the current node. If the traverser's enterNode method returns true, the
		 * traverser will be sent down the child nodes of the tree.
		 * This method should be overridden if the order of traversal is important (such as for BSP trees) - or if static
		 * child nodes are not added using addNode, but are linked to separately.
		 *
		 * @param traverser The traverser visiting the node.
		 *
		 * @see away3d.core.traverse.PartitionTraverser
		 */
		public function acceptTraverser(traverser:ICollector):void
		{
			if (_numEntities == 0 && !_implicitBoundsVisible) return;
			
			if (traverser.enterNode(this)) {
				var i:uint;
				while (i < _numChildNodes)
					_childNodes[i++].acceptTraverser(traverser);

				if (_implicitBoundsVisible)
					_boundsPrimitive.partitionNode.acceptTraverser(traverser);
			}
		}
		
		protected function createBoundsPrimitive():IEntity
		{
			return null;
		}
		
		protected function get numEntities():int
		{
			return _numEntities;
		}

		arcane function updateEntityBounds():void
		{
			if (_boundsPrimitive) {
				_boundsPrimitive.dispose();
				_boundsPrimitive = null;
			}

			if (_implicitBoundsVisible)	{
				_boundsPrimitive = createBoundsPrimitive();
			}
		}

	}
}
