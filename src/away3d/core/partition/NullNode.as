package away3d.core.partition
{
	/**
	 * NullNode is a node that performs no space partitioning, but simply stores all objects in a
	 * list of leaf nodes. This partitioning system is most useful for simple content, or content that is always in the
	 * screen, such as a 3d user interface.
	 */
	public class NullNode extends NodeBase
	{
		/**
		 * Creates a new NullNode object.
		 */
		public function NullNode()
		{
		}
	}
}