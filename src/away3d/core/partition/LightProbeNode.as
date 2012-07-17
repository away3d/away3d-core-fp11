package away3d.core.partition
{
	import away3d.core.traverse.PartitionTraverser;
	import away3d.lights.LightProbe;

	/**
	 * LightNode is a space partitioning leaf node that contains a LightBase object.
	 */
	public class LightProbeNode extends EntityNode
	{
		private var _light : LightProbe;

		/**
		 * Creates a new LightNode object.
		 * @param light The light to be contained in the node.
		 */
		public function LightProbeNode(light : LightProbe)
		{
			super(light);
			_light = light;
		}

		/**
		 * The light object contained in this node.
		 */
		public function get light() : LightProbe
		{
			return _light;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			if (traverser.enterNode(this)) {
				super.acceptTraverser(traverser);
				traverser.applyLightProbe(_light);
			}
			traverser.leaveNode(this);
		}
	}
}