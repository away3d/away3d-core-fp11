package away3d.core.traverse
{
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.lights.LightBase;
	import away3d.materials.MaterialBase;
	import away3d.core.partition.NodeBase;
	import away3d.entities.Entity;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

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
		override public function applySkyBox(renderable : IRenderable) : void {}

		/**
		 * Adds an IRenderable object to the potentially visible objects.
		 * @param renderable The IRenderable object to add.
		 */
		override public function applyRenderable(renderable : IRenderable) : void
		{
			if (renderable.shadowCaster)
				_opaqueRenderables[_numOpaques++] = renderable;
		}

		/**
		 * @inheritDoc
		 */
		override public function applyLight(light : LightBase) : void {}
	}
}