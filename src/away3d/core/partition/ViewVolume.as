package away3d.core.partition
{
	import away3d.arcane;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Entity;
	import away3d.primitives.WireframeCube;
	import away3d.primitives.WireframePrimitiveBase;

	import flash.geom.Vector3D;

	use namespace arcane;

	// todo: provide markVisibleVolume to pass in another view volume to find all statics in the scene that intersect with target ViewVolume, for constructing view volumes more easily
	public class ViewVolume extends NodeBase
	{
		private var _width : Number;
		private var _height : Number;
		private var _depth : Number;
		private var _gridSize : Number;
		private var _numCellsX : uint;
		private var _numCellsY : uint;
		private var _numCellsZ : uint;
		private var _cells : Vector.<ViewCell>;
		private var _yCellStride : uint;
		private var _zCellStride : uint;
		private var _minX : Number;
		private var _minY : Number;
		private var _minZ : Number;
		private var _maxX : Number;
		private var _maxY : Number;
		private var _maxZ : Number;

		/**
		 * Creates a new ViewVolume with given dimensions. A ViewVolume is a region where the camera or a shadow casting light could reside in.
		 *
		 * @param minBound The minimum boundaries of the view volume (the bottom-left-near corner)
		 * @param maxBound The maximum boundaries of the view volume (the top-right-far corner)
		 * @param gridSize The size of cell subdivisions for the view volume. The default value is -1, meaning the view volume will not be subdivided. This is the value that should usually be used when setting visibility info manually.
		 */
		public function ViewVolume(minBound : Vector3D, maxBound : Vector3D, gridSize : Number = -1)
		{
			_minX = minBound.x;
			_minY = minBound.y;
			_minZ = minBound.z;
			_maxX = maxBound.x;
			_maxY = maxBound.y;
			_maxZ = maxBound.z;
			_width = _maxX - _minX;
			_height = _maxY - _minY;
			_depth = _maxZ - _minZ;
			_gridSize = gridSize;
			initCells();
		}

		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			var entryPoint : Vector3D = traverser.entryPoint;

			var cell : ViewCell = getCellContaining(entryPoint);

			var visibleStatics : Vector.<EntityNode> = cell.visibleStatics;
			var numVisibles : uint = visibleStatics.length;
			for (var i : int = 0; i < numVisibles; ++i)
				visibleStatics[i].acceptTraverser(traverser);
		}

		public function addVisibleStatic(entity : Entity, indexX : uint = 1, indexY : uint = 1, indexZ : uint = 1) : void
		{
			if (!entity.static)
				throw new Error("Entity being added as a visible static object must have static set to true");

			var index : int = getCellIndex(indexX, indexY, indexZ);
			_cells[index].visibleStatics ||= new Vector.<EntityNode>();
			_cells[index].visibleStatics.push(entity.getEntityPartitionNode());
			updateNumEntities(_numEntities+1);
		}

		public function removeVisibleStatic(entity : Entity, indexX : uint = 1, indexY : uint = 1, indexZ : uint = 1) : void
		{
			var index : int = getCellIndex(indexX, indexY, indexZ);
			var statics : Vector.<EntityNode> = _cells[index].visibleStatics;
			if (!statics) return;
			index = statics.indexOf(entity.getEntityPartitionNode());
			if (index >= 0) statics.splice(index, 1);
		}

		private function initCells() : void
		{
			if (_gridSize == -1)
				_numCellsX = _numCellsY = _numCellsZ = 1;
			else {
				_numCellsX = Math.ceil(_width/_numCellsX);
				_numCellsY = Math.ceil(_height/_numCellsY);
				_numCellsZ = Math.ceil(_depth/_numCellsZ);
			}

			_yCellStride = _numCellsX;
			_zCellStride = _numCellsX*_numCellsY;

			_cells = new Vector.<ViewCell>(_numCellsX*_numCellsY*_numCellsZ);

			if (_gridSize == -1)
				_cells.push(new ViewCell());

			// else: do not automatically populate with cells as it may be sparse!
		}

		/**
		 * Enable the use of a cell. Do this if the camera or casting light can potentially be in this cell.
		 * If the ViewVolume was constructed with gridSize -1, it does not need to be called
		 * @param indexX The x-index of the cell
		 * @param indexY The y-index of the cell
		 * @param indexZ The z-index of the cell
		 */
		public function markCellAccessible(indexX : uint, indexY : uint, indexZ : uint) : void
		{
			var index : int = getCellIndex(indexX, indexY, indexZ);
			_cells[index] ||= new ViewCell();
		}

		/**
		 * Disables the use of a cell. Do this only if the camera or casting light can never be in this cell.
		 * @param indexX The x-index of the cell
		 * @param indexY The y-index of the cell
		 * @param indexZ The z-index of the cell
		 */
		public function markCellInaccessible(indexX : uint, indexY : uint, indexZ : uint) : void
		{
			var index : int = getCellIndex(indexX, indexY, indexZ);
			_cells[index] = null;
		}

		public function get width() : Number
		{
			return _width;
		}

		public function get height() : Number
		{
			return _height;
		}

		public function get depth() : Number
		{
			return _depth;
		}

		public function get numCellsX() : uint
		{
			return _numCellsX;
		}

		public function get numCellsY() : uint
		{
			return _numCellsY;
		}

		public function get numCellsZ() : uint
		{
			return _numCellsZ;
		}

		public function get minX() : Number
		{
			return _minX;
		}

		public function get minY() : Number
		{
			return _minY;
		}

		public function get minZ() : Number
		{
			return _minZ;
		}

		public function get maxX() : Number
		{
			return _maxX;
		}

		public function get maxY() : Number
		{
			return _maxY;
		}

		public function get maxZ() : Number
		{
			return _maxZ;
		}

		private function getCellIndex(indexX : uint, indexY : uint, indexZ : uint) : uint
		{
			if (indexX >= _numCellsX || indexY >= _numCellsY || indexZ >= _numCellsZ)
				throw new Error("Index out of bounds");

			return indexX + indexY * _yCellStride + indexZ * _zCellStride;
		}

		public function contains(entryPoint : Vector3D) : Boolean
		{
			return 	entryPoint.x >=  _minX && entryPoint.x <= _maxX &&
					entryPoint.y >=  _minY && entryPoint.x <= _maxY &&
					entryPoint.z >=  _minZ && entryPoint.x <= _maxZ;
		}

		private function getCellContaining(entryPoint : Vector3D) : ViewCell
		{
			var cellIndex : uint;

			if (_gridSize == -1)
				cellIndex = 0;
			else {
				var indexX : int = (entryPoint.x - _minX) / _width * _numCellsX;
				var indexY : int = (entryPoint.y - _minY) / _height * _numCellsY;
				var indexZ : int = (entryPoint.z - _minZ) / _depth * _numCellsZ;
				cellIndex = indexX + indexY * _yCellStride + indexZ * _zCellStride;
			}
			return _cells[cellIndex];
		}

		override protected function createDebugBounds() : WireframePrimitiveBase
		{
			var cube : WireframeCube = new WireframeCube(_width, _height, _depth, 0xff0000);
			cube.x = (_minX + _maxX)*.5;
			cube.y = (_minY + _maxY)*.5;
			cube.z = (_minZ + _maxZ)*.5;
			return cube;
		}
	}
}

import away3d.core.partition.EntityNode;

class ViewCell
{
	public var visibleStatics : Vector.<EntityNode> = new Vector.<EntityNode>();
	// TODO: add visible dynamic regions
}