package away3d.core.partition
{
	import away3d.arcane;
	import away3d.entities.Entity;
	import away3d.primitives.WireframePrimitiveBase;

	use namespace arcane;

	public class ViewVolumePartition extends Partition3D
	{
		public function ViewVolumePartition()
		{
			super(new ViewVolumeRootNode());
		}

		override arcane function markForUpdate(entity : Entity) : void
		{
			// ignore if static, will be handled separately by visibility list
			if (!entity.static)
				super.markForUpdate(entity);
		}

		public function addViewVolume(viewVolume : ViewVolume) : void
		{
			ViewVolumeRootNode(_rootNode).addViewVolume(viewVolume);
		}

		public function removeViewVolume(viewVolume : ViewVolume) : void
		{
			ViewVolumeRootNode(_rootNode).removeViewVolume(viewVolume);
		}
	}
}
