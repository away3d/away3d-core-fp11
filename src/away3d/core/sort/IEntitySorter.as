package away3d.core.sort {
	import away3d.core.traverse.EntityCollector;

	/**
	 * EntitySorterBase provides an abstract base class to sort geometry information in an EntityCollector object for
	 * rendering.
	 */
	public interface IEntitySorter
	{
		/**
		 * Sort the potentially visible data in an EntityCollector for rendering.
		 * @param collector The EntityCollector object containing the potentially visible data.
		 */
		function sort(collector : EntityCollector) : void;
	}
}