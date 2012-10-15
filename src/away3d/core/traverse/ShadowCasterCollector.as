package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.entities.Entity;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;
	import away3d.materials.MaterialBase;

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
			super();
		}

		/**
		 * Adds an IRenderable object to the potentially visible objects.
		 * @param renderable The IRenderable object to add.
		 */
		override public function applyRenderable(renderable : IRenderable) : void
		{
			// the test for material is temporary, you SHOULD be hammered with errors if you try to render anything without a material
			var material : MaterialBase = renderable.material;
			if (renderable.castsShadows && material) {
				var item : RenderableListItem = _renderableListItemPool.getItem();
				item.renderable = renderable;
				item.next = _opaqueRenderableHead;
				item.zIndex = renderable.zIndex;
				item.renderOrderId = material._depthPassId;
				_opaqueRenderableHead = item;
			}
		}

		override public function applyUnknownLight(light : LightBase) : void {}
		override public function applyDirectionalLight(light : DirectionalLight) : void {}
		override public function applyPointLight(light : PointLight) : void {}
		override public function applyLightProbe(light : LightProbe) : void {}
		override public function applySkyBox(renderable : IRenderable) : void {}
	}
}