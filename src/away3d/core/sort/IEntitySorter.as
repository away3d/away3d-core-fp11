package away3d.core.sort
{
	import away3d.core.pool.IRenderable;
	import away3d.core.traverse.EntityCollector;
	
	/**
	 * EntitySorterBase provides an abstract base class to sort geometry information in an EntityCollector object for
	 * rendering.
	 */
	public interface IEntitySorter
	{
		function sortBlendedRenderables(head:IRenderable):IRenderable;

		function sortOpaqueRenderables(head:IRenderable):IRenderable;
	}
}
