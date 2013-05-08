package away3d.core.partition {
	import away3d.core.math.Plane3D;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.primitives.SkyBox;

	/**
	 * SkyBoxNode is a space partitioning leaf node that contains a SkyBox object.
	 */
	public class SkyBoxNode extends EntityNode
	{
		private var _skyBox : SkyBox;

		/**
		 * Creates a new SkyBoxNode object.
		 * @param skyBox The SkyBox to be contained in the node.
		 */
		public function SkyBoxNode(skyBox : SkyBox)
		{
			super(skyBox);
			_skyBox = skyBox;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			if (traverser.enterNode(this)) {
				super.acceptTraverser(traverser);
				traverser.applySkyBox(_skyBox);
			}
		}


		override public function isInFrustum(planes : Vector.<Plane3D>, numPlanes : int) : Boolean
		{
			planes=planes;
			numPlanes=numPlanes;
			return true;
		}
	}
}