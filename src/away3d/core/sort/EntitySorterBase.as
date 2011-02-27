package away3d.core.sort
{
	import away3d.core.traverse.EntityCollector;
	import away3d.errors.AbstractMethodError;

	/**
	 * EntitySorterBase provides an abstract base class to sort geometry information in an EntityCollector object for
	 * rendering.
	 */
	public class EntitySorterBase
	{
		/**
		 * Sort the potentially visible data in an EntityCollector for rendering.
		 * @param collector The EntityCollector object containing the potentially visible data.
		 */
		public function sort(collector : EntityCollector) : void
		{
			throw new AbstractMethodError();
		}
	}
}