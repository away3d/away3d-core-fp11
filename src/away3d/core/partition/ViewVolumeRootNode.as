package away3d.core.partition
{
	import away3d.arcane;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Entity;
	
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	public class ViewVolumeRootNode extends NodeBase
	{
		// todo: provide a better data structure to find the containing view volume faster
		private var _viewVolumes:Vector.<ViewVolume>;
		private var _activeVolume:ViewVolume;
		private var _dynamicGrid:DynamicGrid;
		
		public function ViewVolumeRootNode()
		{
			_viewVolumes = new Vector.<ViewVolume>();
		}
		
		override public function set showDebugBounds(value:Boolean):void
		{
			super.showDebugBounds = value;
			if (_dynamicGrid)
				_dynamicGrid.showDebugBounds = true;
		}
		
		override public function findPartitionForEntity(entity:Entity):NodeBase
		{
			return _dynamicGrid? _dynamicGrid.findPartitionForEntity(entity) : this;
		}
		
		public function get dynamicGrid():DynamicGrid
		{
			return _dynamicGrid;
		}
		
		public function set dynamicGrid(value:DynamicGrid):void
		{
			_dynamicGrid = value;
			_dynamicGrid.showDebugBounds = showDebugBounds;
		}
		
		public function addViewVolume(viewVolume:ViewVolume):void
		{
			if (_viewVolumes.indexOf(viewVolume) == -1)
				_viewVolumes.push(viewVolume);
			
			addNode(viewVolume);
		}
		
		public function removeViewVolume(viewVolume:ViewVolume):void
		{
			var index:int = _viewVolumes.indexOf(viewVolume);
			if (index >= 0)
				_viewVolumes.splice(index, 1);
		}
		
		override public function acceptTraverser(traverser:PartitionTraverser):void
		{
			if (!(_activeVolume && _activeVolume.contains(traverser.entryPoint))) {
				var volume:ViewVolume = getVolumeContaining(traverser.entryPoint);
				
				if (!volume)
					trace("WARNING: No view volume found for the current position.");
				
				// keep the active one if no volume is found (it may be just be a small error)
				else if (volume != _activeVolume) {
					if (_activeVolume)
						_activeVolume._active = false;
					_activeVolume = volume;
					if (_activeVolume)
						_activeVolume._active = true;
				}
			}
			
			super.acceptTraverser(traverser);
		}
		
		private function getVolumeContaining(entryPoint:Vector3D):ViewVolume
		{
			var numVolumes:uint = _viewVolumes.length;
			for (var i:uint = 0; i < numVolumes; ++i) {
				if (_viewVolumes[i].contains(entryPoint))
					return _viewVolumes[i];
			}
			
			return null;
		}
	}
}
