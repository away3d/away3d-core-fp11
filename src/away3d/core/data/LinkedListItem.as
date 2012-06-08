package away3d.core.data
{

	import away3d.core.base.IRenderable;

	public final class LinkedListItem
	{
		public var next:LinkedListItem;
		public var renderable : IRenderable;

		// for faster access while sorting
		public var materialId : int;
		public var renderOrderId : int;
		public var zIndex : Number;

		public function clone():LinkedListItem {
			var theClone:LinkedListItem = new LinkedListItem();
			theClone.renderable = renderable;
			theClone.materialId = materialId;
			theClone.renderOrderId = renderOrderId;
			theClone.zIndex = zIndex;
			return theClone;
		}
	}
}
