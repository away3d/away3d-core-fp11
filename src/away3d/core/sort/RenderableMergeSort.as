package away3d.core.sort
{
	import away3d.arcane;
	import away3d.core.data.RenderableListItem;
	import away3d.core.traverse.EntityCollector;

	use namespace arcane;

	/**
	 * RenderableSorter sorts the potentially visible IRenderable objects collected by EntityCollector for optimal
	 * rendering performance. Objects are sorted first by material, then by distance to the camera. Opaque objects
	 * are sorted front to back, while objects that require blending are sorted back to front, to ensure correct
	 * blending.
	 */
	public class RenderableMergeSort extends EntitySorterBase
	{
		/**
		 * Creates a RenderableSorter objects
		 */
		public function RenderableMergeSort()
		{
		}

		/**
		 * @inheritDoc
		 */
		override public function sort(collector : EntityCollector) : void
		{
			collector.opaqueRenderableHead = mergeSort(collector.opaqueRenderableHead, true);
			collector.blendedRenderableHead = mergeSort(collector.blendedRenderableHead, false);
		}

		private function mergeSort(head : RenderableListItem, useMaterial : Boolean) : RenderableListItem
		{
			var headB : RenderableListItem;
			var fast : RenderableListItem, slow : RenderableListItem;

			if (!head || !head.next) return head;

			// split in two sublists
			slow = head;
			fast = head.next;

			while (fast) {
				fast = fast.next;
				if (fast) {
					slow = slow.next;
					fast = fast.next;
				}
			}

			headB = slow.next;
			slow.next = null;

			// recurse
			head = mergeSort(head, useMaterial);
			headB = mergeSort(headB, useMaterial);

			// merge sublists while respecting order
			var result : RenderableListItem;
			var curr : RenderableListItem;
			var l : RenderableListItem;
			var cmp : int;

			if (!head) return headB;
			if (!headB) return head;

			while (head && headB) {

				if (useMaterial) {
					// first sort per render order id (reduces program3D switches),
					// then on material id (reduces setting props),
					// then on zIndex (reduces overdraw)
					var aid : uint = head.renderOrderId;
					var bid : uint = headB.renderOrderId;

					if (aid == bid) {
						var ma : uint = head.materialId;
						var mb : uint = headB.materialId;

						if (ma == mb) {
							if (head.zIndex < headB.zIndex) cmp = 1;
							else cmp = -1;
						}
						else if (ma > mb) cmp = 1;
						else cmp = -1;
					}
					else if (aid > bid) cmp = 1;
					else cmp = -1;
				}
				else {
					if (head.zIndex < headB.zIndex) cmp = -1;
					else cmp = 1;
				}

				if (cmp < 0) {
					l = head;
					head = head.next;
				}
				else {
					l = headB;
					headB = headB.next;
				}

				if (!result) {
					result = l;
					curr = l;
				}
				else {
					curr.next = l;
					curr = l;
				}
			}

			if (head) curr.next = head;
			else if (headB) curr.next = headB;

			return result;
		}


		/**
		 * Sorts per material, then per zIndex, front to back, for opaques
		 *
		 * is inlined
		 */
		/*private function opaqueSortFunction(a : IRenderable, b : IRenderable) : int
		{
			var aid : uint = a.material.uniqueId;
			var bid : uint = b.material.uniqueId;

			if (aid == bid) {
				var za : Number = a.zIndex;
				var zb : Number = b.zIndex;
				if (za == zb) return 0;
				else if (za < zb) return 1;
				else return -1;
			}
			else if (aid > bid) return 1;
			else return -1;
		}*/

		/**
		 * Sorts per material, but back to front, for materials that require blending
		 *
		 * is inlined
		 */
		/*private function blendedSortFunction(a : IRenderable, b : IRenderable) : int
		{
			var za : Number = a.zIndex;
			var zb : Number = b.zIndex;
			if (za == zb) return 0;
			else if (za < zb) return -1;
			else return 1;
		}*/
	}
}