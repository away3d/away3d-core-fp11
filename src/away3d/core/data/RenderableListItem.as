package away3d.core.data
{
	import away3d.core.base.IRenderable;

	public final class RenderableListItem
	{
		public var next : RenderableListItem;
		public var renderable : IRenderable;

		// for faster access while sorting
		public var materialId : int;
		public var zIndex : Number;
	}
}
