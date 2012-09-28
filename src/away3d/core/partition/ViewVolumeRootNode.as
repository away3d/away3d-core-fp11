package away3d.core.partition
{
	import away3d.arcane;
	import away3d.core.traverse.PartitionTraverser;

	import flash.geom.Vector3D;

	use namespace arcane;

	// TODO: handle dynamic objects, right now, if not a static, it's being treated the same as a NullPartition
	public class ViewVolumeRootNode extends NodeBase
	{
		// todo: provide a better data structure to find the containing view volume faster
		private var _viewVolumes : Vector.<ViewVolume>;

		public function ViewVolumeRootNode()
		{
			_viewVolumes = new Vector.<ViewVolume>();
		}

		public function addViewVolume(viewVolume : ViewVolume) : void
		{
			if (_viewVolumes.indexOf(viewVolume) == -1)
				_viewVolumes.push(viewVolume);

			addNode(viewVolume);
		}

		public function removeViewVolume(viewVolume : ViewVolume) : void
		{
			var index : int = _viewVolumes.indexOf(viewVolume);
			if (index >= 0)
				_viewVolumes.splice(index, 1);
		}

		override public function set showDebugBounds(value : Boolean) : void
		{
			var numVolumes : uint = _viewVolumes.length;
			for (var i : uint = 0; i < numVolumes; ++i) {
				_viewVolumes[i].showDebugBounds = value;
			}
		}

		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			var volume : ViewVolume = getVolumeContaining(traverser.entryPoint);
			if (!volume) {
				trace("WARNING: No view volume found for the current position.");
				return;
			}
			volume.acceptTraverser(traverser);
		}

		private function getVolumeContaining(entryPoint : Vector3D) : ViewVolume
		{
			var numVolumes : uint = _viewVolumes.length;
			for (var i : uint = 0; i < numVolumes; ++i) {
				if (_viewVolumes[i].contains(entryPoint))
					return _viewVolumes[i];
			}

			return null;
		}
	}
}
