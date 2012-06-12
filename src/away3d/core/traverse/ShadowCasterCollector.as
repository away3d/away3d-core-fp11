package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.entities.Entity;
	import away3d.lights.LightBase;

	use namespace arcane;


	/**
	 * The EntityCollector class is a traverser for scene partitions that collects all scene graph entities that are
	 * considered potientially visible.
	 *
	 * @see away3d.partition.Partition3D
	 * @see away3d.partition.Entity
	 */
	public class ShadowCasterCollector extends EntityCollector
	{
		/**
		 * Creates a new EntityCollector object.
		 */
		public function ShadowCasterCollector()
		{
			_entities = new Vector.<Entity>();
		}

		/**
		 * @inheritDoc
		 */
		override public function applySkyBox(renderable : IRenderable) : void
		{
		}

		/**
		 * Adds an IRenderable object to the potentially visible objects.
		 * @param renderable The IRenderable object to add.
		 */
		override public function applyRenderable(renderable : IRenderable) : void
		{
			// the test for material is temporary, you SHOULD be hammered with errors if you try to render anything without a material
			if (renderable.castsShadows && renderable.material) {
				_numOpaques++;
				var item : RenderableListItem = _renderableListItemPool.getItem();
				item.renderable = renderable;
				item.next = _opaqueRenderableHead;
				item.zIndex = renderable.zIndex;
				item.renderOrderId = renderable.material._uniqueId;
				_opaqueRenderableHead = item;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function applyUnknownLight(light : LightBase) : void
		{
		}
	}
}