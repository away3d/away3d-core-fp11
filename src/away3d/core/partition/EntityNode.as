package away3d.core.partition
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Sprite3D;
	import away3d.errors.AbstractMethodError;
	import away3d.entities.Entity;

	use namespace arcane;

	/**
	 * The EntityNode class provides an abstract base class for leaf nodes in a partition tree, containing
	 * entities to be fed to the EntityCollector traverser.
	 * The concrete subtype of Entity is responsible for creating a matching subtype of EntityNode.
	 *
	 * @see away3d.scenegraph.Entity
	 * @see away3d.core.traverse.EntityCollector
	 */
	public class EntityNode extends NodeBase
	{
		private var _entity : Entity;

		/**
		 * The link to the next object in the list to be updated
		 * @private
		 */
		arcane var _updateQueueNext : EntityNode;

		/**
		 * Creates a new EntityNode object.
		 * @param entity The Entity to be contained in this leaf node.
		 */
		public function EntityNode(entity : Entity)
		{
			super();
			_entity = entity;
		}

		/**
		 * The entity contained in this leaf node.
		 */
		public function get entity() : Entity
		{
			return _entity;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			traverser.applyEntity(_entity);
		}

		/**
		 * Detaches the node from its parent.
		 */
		public function removeFromParent() : void
		{
			if (_parent) _parent.removeNode(this);
		}

		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(camera : Camera3D) : Boolean
		{
			_entity.pushModelViewProjection(camera);
			return _entity.bounds.isInFrustum(_entity.modelViewProjection);
		}
	}
}