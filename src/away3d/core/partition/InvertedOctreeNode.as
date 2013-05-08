package away3d.core.partition {
	import away3d.arcane;
	import away3d.core.math.Plane3D;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.primitives.WireframeCube;
	import away3d.primitives.WireframePrimitiveBase;

	import flash.geom.Vector3D;

	/**
	 * InvertedOctreeNode is an octree data structure not used hierarchically for culling, but for fast dynamic insertion.
	 * The data structure is essentially a grid, but "overarching" parent container nodes for entities striding across nodes.
	 * If this is visible, so is the parent.
	 * Traversal happens invertedly too.
	 */
	public class InvertedOctreeNode extends NodeBase
	{
		private var _minX : Number;
		private var _minY : Number;
		private var _minZ : Number;
		private var _maxX : Number;
		private var _maxY : Number;
		private var _maxZ : Number;
		private var _centerX : Number;
		private var _centerY : Number;
		private var _centerZ : Number;
		private var _halfExtentX : Number;
		private var _halfExtentY : Number;
		private var _halfExtentZ : Number;

		use namespace arcane;

		public function InvertedOctreeNode(minBounds : Vector3D, maxBounds : Vector3D)
		{
			_minX = minBounds.x;
			_minY = minBounds.y;
			_minZ = minBounds.z;
			_maxX = maxBounds.x;
			_maxY = maxBounds.y;
			_maxZ = maxBounds.z;
			_centerX = (_maxX + _minX)*.5;
			_centerY = (_maxY + _minY)*.5;
			_centerZ = (_maxZ + _minZ)*.5;
			_halfExtentX  = (_maxX - _minX)*.5;
			_halfExtentY  = (_maxY - _minY)*.5;
			_halfExtentZ  = (_maxZ - _minZ)*.5;
		}

		arcane function setParent(value : InvertedOctreeNode) : void
		{
			_parent = value;
		}

		override public function isInFrustum(planes : Vector.<Plane3D>, numPlanes : int) : Boolean
		{
			for (var i : uint = 0; i < numPlanes; ++i) {
				var plane : Plane3D = planes[i];
				var flippedExtentX : Number = plane.a < 0? - _halfExtentX : _halfExtentX;
				var flippedExtentY : Number = plane.b < 0? - _halfExtentY : _halfExtentY;
				var flippedExtentZ : Number = plane.c < 0? - _halfExtentZ : _halfExtentZ;
				var projDist : Number = plane.a * (_centerX + flippedExtentX) + plane.b * (_centerY + flippedExtentY) + plane.c * (_centerZ + flippedExtentZ) - plane.d;
				if (projDist < 0) return false;
			}

			return true;
		}

		override protected function createDebugBounds() : WireframePrimitiveBase
		{
			var cube : WireframeCube = new WireframeCube(_maxX - _minX, _maxY - _minY, _maxZ - _minZ, 0x8080ff);
			cube.x = _centerX;
			cube.y = _centerY;
			cube.z = _centerZ;
			return cube;
		}

		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			super.acceptTraverser(traverser);
			if (_parent) _parent.acceptTraverser(traverser);
		}
	}
}
