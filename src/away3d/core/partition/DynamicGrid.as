package away3d.core.partition
{
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.entities.Entity;
	
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * DynamicGrid is used by certain partitioning systems that require vislists for regions of dynamic data.
	 */
	public class DynamicGrid
	{
		private var _minX:Number;
		private var _minY:Number;
		private var _minZ:Number;
		private var _leaves:Vector.<InvertedOctreeNode>;
		private var _numCellsX:uint;
		private var _numCellsY:uint;
		private var _numCellsZ:uint;
		private var _cellWidth:Number;
		private var _cellHeight:Number;
		private var _cellDepth:Number;
		private var _showDebugBounds:Boolean;
		
		public function DynamicGrid(minBounds:Vector3D, maxBounds:Vector3D, numCellsX:uint, numCellsY:uint, numCellsZ:uint)
		{
			_numCellsX = numCellsX;
			_numCellsY = numCellsY;
			_numCellsZ = numCellsZ;
			_minX = minBounds.x;
			_minY = minBounds.y;
			_minZ = minBounds.z;
			_cellWidth = (maxBounds.x - _minX)/numCellsX;
			_cellHeight = (maxBounds.y - _minY)/numCellsY;
			_cellDepth = (maxBounds.z - _minZ)/numCellsZ;
			_leaves = createLevel(numCellsX, numCellsY, numCellsZ, _cellWidth, _cellHeight, _cellDepth);
		}
		
		public function get numCellsX():uint
		{
			return _numCellsX;
		}
		
		public function get numCellsY():uint
		{
			return _numCellsY;
		}
		
		public function get numCellsZ():uint
		{
			return _numCellsZ;
		}
		
		public function getCellAt(x:uint, y:uint, z:uint):InvertedOctreeNode
		{
			if (x >= _numCellsX || y >= _numCellsY || z >= _numCellsZ)
				throw new Error("Index out of bounds!");
			
			return _leaves[x + (y + z*_numCellsY)*_numCellsX];
		}
		
		private function createLevel(numCellsX:uint, numCellsY:uint, numCellsZ:uint, cellWidth:Number, cellHeight:Number, cellDepth:Number):Vector.<InvertedOctreeNode>
		{
			var nodes:Vector.<InvertedOctreeNode> = new Vector.<InvertedOctreeNode>(numCellsX*numCellsY*numCellsZ);
			var parents:Vector.<InvertedOctreeNode>;
			var node:InvertedOctreeNode;
			var i:uint;
			var minX:Number, minY:Number, minZ:Number;
			var numParentsX:uint, numParentsY:uint, numParentsZ:uint;
			
			if (numCellsX != 1 || numCellsY != 1 || numCellsZ != 1) {
				numParentsX = Math.ceil(numCellsX/2);
				numParentsY = Math.ceil(numCellsY/2);
				numParentsZ = Math.ceil(numCellsZ/2);
				parents = createLevel(numParentsX, numParentsY, numParentsZ, cellWidth*2, cellHeight*2, cellDepth*2);
			}
			
			minZ = _minZ;
			for (var z:uint = 0; z < numCellsZ; ++z) {
				minY = _minY;
				for (var y:uint = 0; y < numCellsY; ++y) {
					minX = _minX;
					for (var x:uint = 0; x < numCellsX; ++x) {
						node = new InvertedOctreeNode(new Vector3D(minX, minY, minZ), new Vector3D(minX + cellWidth, minY + cellHeight, minZ + cellDepth));
						if (parents) {
							var index:int = (x >> 1) + ((y >> 1) + (z >> 1)*numParentsY)*numParentsX;
							node.setParent(parents[index]);
						}
						nodes[i++] = node;
						minX += cellWidth;
					}
					minY += cellHeight;
				}
				minZ += cellDepth;
			}
			
			return nodes;
		}
		
		public function findPartitionForEntity(entity:Entity):NodeBase
		{
			var bounds:BoundingVolumeBase = entity.worldBounds;
			var min:Vector3D = bounds.min;
			var max:Vector3D = bounds.max;
			
			var minX:Number = min.x;
			var minY:Number = min.y;
			var minZ:Number = min.z;
			var maxX:Number = max.x;
			var maxY:Number = max.y;
			var maxZ:Number = max.z;
			
			var minIndexX:int = (minX - _minX)/_cellWidth;
			var maxIndexX:int = (maxX - _minX)/_cellWidth;
			var minIndexY:int = (minY - _minY)/_cellHeight;
			var maxIndexY:int = (maxY - _minY)/_cellHeight;
			var minIndexZ:int = (minZ - _minZ)/_cellDepth;
			var maxIndexZ:int = (maxZ - _minZ)/_cellDepth;
			
			if (minIndexX < 0)
				minIndexX = 0;
			else if (minIndexX >= _numCellsX)
				minIndexX = _numCellsX - 1;
			if (minIndexY < 0)
				minIndexY = 0;
			else if (minIndexY >= _numCellsY)
				minIndexY = _numCellsY - 1;
			if (minIndexZ < 0)
				minIndexZ = 0;
			else if (minIndexZ >= _numCellsZ)
				minIndexZ = _numCellsZ - 1;
			if (maxIndexX < 0)
				maxIndexX = 0;
			else if (maxIndexX >= _numCellsX)
				maxIndexX = _numCellsX - 1;
			if (maxIndexY < 0)
				maxIndexY = 0;
			else if (maxIndexY >= _numCellsY)
				maxIndexY = _numCellsY - 1;
			if (maxIndexZ < 0)
				maxIndexZ = 0;
			else if (maxIndexZ >= _numCellsZ)
				maxIndexZ = _numCellsZ - 1;
			
			var node:NodeBase = _leaves[minIndexX + (minIndexY + minIndexZ*_numCellsY)*_numCellsX];
			
			// could do this with log2, but not sure if at all faster in expected case (would usually be 0 or at worst 1 iterations, or dynamic grid was set up poorly)
			while (minIndexX != maxIndexX && minIndexY != maxIndexY && minIndexZ != maxIndexZ) {
				maxIndexX >>= 1;
				minIndexX >>= 1;
				maxIndexY >>= 1;
				minIndexY >>= 1;
				maxIndexZ >>= 1;
				minIndexZ >>= 1;
				node = node._parent;
			}
			
			return node;
		}
		
		public function get showDebugBounds():Boolean
		{
			return _showDebugBounds;
		}
		
		public function set showDebugBounds(value:Boolean):void
		{
			var numLeaves:uint = _leaves.length;
			_showDebugBounds = showDebugBounds;
			for (var i:int = 0; i < numLeaves; ++i)
				_leaves[i].showDebugBounds = value;
		}
		
		public function getCellsIntersecting(minBounds:Vector3D, maxBounds:Vector3D):Vector.<InvertedOctreeNode>
		{
			var cells:Vector.<InvertedOctreeNode> = new Vector.<InvertedOctreeNode>();
			var minIndexX:int = (minBounds.x - _minX)/_cellWidth;
			var maxIndexX:int = (maxBounds.x - _minX)/_cellWidth;
			var minIndexY:int = (minBounds.y - _minY)/_cellHeight;
			var maxIndexY:int = (maxBounds.y - _minY)/_cellHeight;
			var minIndexZ:int = (minBounds.z - _minZ)/_cellDepth;
			var maxIndexZ:int = (maxBounds.z - _minZ)/_cellDepth;
			
			if (minIndexX < 0)
				minIndexX = 0;
			else if (minIndexX >= _numCellsX)
				minIndexX = _numCellsX - 1;
			if (maxIndexX < 0)
				maxIndexX = 0;
			else if (maxIndexX >= _numCellsX)
				maxIndexX = _numCellsX - 1;
			
			if (minIndexY < 0)
				minIndexY = 0;
			else if (minIndexY >= _numCellsY)
				minIndexY = _numCellsY - 1;
			if (maxIndexY < 0)
				maxIndexY = 0;
			else if (maxIndexY >= _numCellsY)
				maxIndexY = _numCellsY - 1;
			
			if (maxIndexZ < 0)
				maxIndexZ = 0;
			else if (maxIndexZ >= _numCellsZ)
				maxIndexZ = _numCellsZ - 1;
			if (minIndexZ < 0)
				minIndexZ = 0;
			else if (minIndexZ >= _numCellsZ)
				minIndexZ = _numCellsZ - 1;
			
			var i:uint;
			for (var z:uint = minIndexZ; z <= maxIndexZ; ++z) {
				for (var y:uint = minIndexY; y <= maxIndexY; ++y) {
					for (var x:uint = minIndexX; x <= maxIndexX; ++x)
						cells[i++] = getCellAt(x, y, z);
				}
			}
			
			return cells;
		}
	}
}
