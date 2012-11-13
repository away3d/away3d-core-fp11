package away3d.core.partition
{
	import away3d.core.traverse.PartitionTraverser;
	import away3d.lights.PointLight;

	/**
	 * LightNode is a space partitioning leaf node that contains a LightBase object.
	 */
	public class PointLightNode extends EntityNode
	{
		private var _light : PointLight;

		/**
		 * Creates a new LightNode object.
		 * @param light The light to be contained in the node.
		 */
		public function PointLightNode(light : PointLight)
		{
			super(light);
			_light = light;
		}

		/**
		 * The light object contained in this node.
		 */
		public function get light() : PointLight
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
				traverser.applyPointLight(_light);
			}
		}
	}
}