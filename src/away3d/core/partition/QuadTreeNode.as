package away3d.core.partition {
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.math.Plane3D;
	import away3d.entities.Entity;

	import flash.geom.Vector3D;

	use namespace arcane;

	public class QuadTreeNode extends NodeBase
	{
		private var _centerX : Number;
		private var _centerZ : Number;
		private var _depth : Number;
		private var _leaf : Boolean;
		private var _height : Number;

		private var _rightFar : QuadTreeNode;
		private var _leftFar : QuadTreeNode;
		private var _rightNear : QuadTreeNode;
		private var _leftNear : QuadTreeNode;

		private var _halfExtentXZ : Number;
		private var _halfExtentY : Number;


		public function QuadTreeNode(maxDepth : int = 5, size : Number = 10000, height : Number = 1000000, centerX : Number = 0, centerZ : Number = 0, depth : int = 0)
		{
			var hs : Number = size * .5;

			_centerX = centerX;
			_centerZ = centerZ;
			_height = height;
			_depth = depth;
			_halfExtentXZ = size*.5;
			_halfExtentY = height*.5;

			_leaf = depth == maxDepth;

			if (!_leaf) {
				var hhs : Number = hs*.5;
				addNode(_leftNear = new QuadTreeNode(maxDepth, hs, height, centerX - hhs, centerZ - hhs, depth + 1));
				addNode(_rightNear = new QuadTreeNode(maxDepth, hs, height, centerX + hhs, centerZ - hhs, depth + 1));
				addNode(_leftFar = new QuadTreeNode(maxDepth, hs, height, centerX - hhs, centerZ + hhs, depth + 1));
				addNode(_rightFar = new QuadTreeNode(maxDepth, hs, height, centerX + hhs, centerZ + hhs, depth + 1));
			}
		}

		// todo: fix to infinite height so that height needn't be passed in constructor
		override public function isInFrustum(planes : Vector.<Plane3D>, numPlanes : int) : Boolean
		{
			for (var i : uint = 0; i < numPlanes; ++i) {
				var plane : Plane3D = planes[i];
				var flippedExtentX : Number = plane.a < 0? - _halfExtentXZ : _halfExtentXZ;
				var flippedExtentY : Number = plane.b < 0? - _halfExtentY : _halfExtentY;
				var flippedExtentZ : Number = plane.c < 0? - _halfExtentXZ : _halfExtentXZ;
				var projDist : Number = plane.a * (_centerX + flippedExtentX) + plane.b * flippedExtentY + plane.c * (_centerZ + flippedExtentZ) - plane.d;
				if (projDist < 0) return false;
			}

			return true;
		}

		override public function findPartitionForEntity(entity : Entity) : NodeBase
		{
			var bounds : BoundingVolumeBase = entity.worldBounds;
			var min : Vector3D = bounds.min;
			var max : Vector3D = bounds.max;
			return findPartitionForBounds(min.x, min.z, max.x, max.z);
		}

		private function findPartitionForBounds(minX : Number, minZ : Number, maxX : Number, maxZ : Number) : QuadTreeNode
		{
			var left : Boolean, right : Boolean;
			var far : Boolean, near : Boolean;

			if (_leaf)
				return this;

			right = maxX > _centerX;
			left = minX < _centerX;
			far = maxZ  > _centerZ;
			near = minZ < _centerZ;

			if (left && right) return this;

			if (near) {
				if (far) return this;

				if (left) return _leftNear.findPartitionForBounds(minX, minZ, maxX, maxZ);
				else return _rightNear.findPartitionForBounds(minX, minZ, maxX, maxZ);
			}
			else {
				if (left) return _leftFar.findPartitionForBounds(minX, minZ, maxX, maxZ);
				else return _rightFar.findPartitionForBounds(minX, minZ, maxX, maxZ);
			}
		}
	}
}
