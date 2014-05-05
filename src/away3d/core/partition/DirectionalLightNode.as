package away3d.core.partition
{
	import away3d.core.traverse.ICollector;
	import away3d.entities.IEntity;

	/**
	 * LightNode is a space partitioning leaf node that contains a LightBase object.
	 */
	public class DirectionalLightNode extends EntityNode
	{
		private var _light:IEntity;
		
		/**
		 * Creates a new LightNode object.
		 * @param directionalLight The light to be contained in the node.
		 */
		public function DirectionalLightNode(directionalLight:IEntity)
		{
			super(directionalLight);
			_light = directionalLight;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser:ICollector):void
		{
			//do not run frustum checks on lights
			traverser.applyDirectionalLight(_light);
		}
	}
}
