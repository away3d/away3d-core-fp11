package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.core.partition.NodeBase;

	use namespace arcane;

	public class ShadowCasterCollector extends EntityCollector
	{
		/**
		 * Creates a new EntityCollector object.
		 */
		public function ShadowCasterCollector()
		{
			super();
		}

		/**
		 *
		 */
		override public function enterNode(node:NodeBase):Boolean
		{
			var enter:Boolean = scene._collectionMark != node._collectionMark && node.isCastingShadow();

			if (!enter) {
				node._collectionMark = scene._collectionMark;
				return false;
			}

			return super.enterNode(node);
		}
	}
}
