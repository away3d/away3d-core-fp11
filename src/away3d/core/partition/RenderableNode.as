package away3d.core.partition
{
	import away3d.core.base.IRenderable;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Entity;

	/**
	 * RenderableNode is a space partitioning leaf node that contains any Entity that is itself a IRenderable
	 * object. This excludes Mesh (since the renderable objects are its SubMesh children).
	 */
	public class RenderableNode extends EntityNode
	{
		private var _renderable : IRenderable;

		/**
		 * Creates a new RenderableNode object.
		 * @param mesh The mesh to be contained in the node.
		 */
		public function RenderableNode(renderable : IRenderable)
		{
			super(Entity(renderable));
			_renderable = renderable;	// also keep a stronger typed reference
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			super.acceptTraverser(traverser);
			if (traverser.enterNode(this))
				traverser.applyRenderable(_renderable);
			traverser.leaveNode(this);
		}

	}
}