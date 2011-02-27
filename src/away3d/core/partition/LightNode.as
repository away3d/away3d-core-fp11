package away3d.core.partition
{
	import away3d.core.traverse.PartitionTraverser;
	import away3d.lights.LightBase;

	/**
	 * LightNode is a space partitioning leaf node that contains a LightBase object.
	 */
	public class LightNode extends EntityNode
	{
		private var _light : LightBase;

		/**
		 * Creates a new LightNode object.
		 * @param light The light to be contained in the node.
		 */
		public function LightNode(light : LightBase)
		{
			super(light);
			_light = light;
		}

		/**
		 * The light object contained in this node.
		 */
		public function get light() : LightBase
		{
			return _light;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			super.acceptTraverser(traverser);
			if (traverser.enterNode(this)) {
				traverser.applyLight(_light);
			}
			traverser.leaveNode(this)
		}
	}
}