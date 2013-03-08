package away3d.core.partition
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.math.Plane3D;
	import away3d.entities.Entity;
	import away3d.primitives.WireframeCube;
	import away3d.primitives.WireframePrimitiveBase;

	use namespace arcane;

	public class OctreeNode extends NodeBase
	{
		private var _centerX : Number;
		private var _centerY : Number;
		private var _centerZ : Number;
		private var _minX : Number;
		private var _minY : Number;
		private var _minZ : Number;
		private var _maxX : Number;
		private var _maxY : Number;
		private var _maxZ : Number;
		private var _quadSize : Number;
		private var _depth : Number;
		private var _leaf : Boolean;

		private var _rightTopFar : OctreeNode;
		private var _leftTopFar : OctreeNode;
		private var _rightBottomFar : OctreeNode;
		private var _leftBottomFar : OctreeNode;
		private var _rightTopNear : OctreeNode;
		private var _leftTopNear : OctreeNode;
		private var _rightBottomNear : OctreeNode;
		private var _leftBottomNear : OctreeNode;

		private var _entityWorldBounds : Vector.<Number> = new Vector.<Number>();
		private var _halfExtent : Number;

		public function OctreeNode(maxDepth : int = 5, size : Number = 10000, centerX : Number = 0, centerY : Number = 0, centerZ : Number = 0, depth : int = 0)
		{
			init(size, centerX, centerY, centerZ, depth, maxDepth);
		}

		private function init(size : Number, centerX : Number, centerY : Number, centerZ : Number, depth : int, maxDepth : int) : void
		{
			_halfExtent = size * .5;
			_centerX = centerX;
			_centerY = centerY;
			_centerZ = centerZ;
			_quadSize = size;
			_depth = depth;
			_minX = centerX - _halfExtent;
			_minY = centerY - _halfExtent;
			_minZ = centerZ - _halfExtent;
			_maxX = centerX + _halfExtent;
			_maxY = centerY + _halfExtent;
			_maxZ = centerZ + _halfExtent;

			_leaf = depth == maxDepth;

			if (!_leaf) {
				var hhs : Number = _halfExtent * .5;
				addNode(_leftTopNear = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY + hhs, centerZ - hhs, depth + 1));
				addNode(_rightTopNear = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY + hhs, centerZ - hhs, depth + 1));
				addNode(_leftBottomNear = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY - hhs, centerZ - hhs, depth + 1));
				addNode(_rightBottomNear = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY - hhs, centerZ - hhs, depth + 1));
				addNode(_leftTopFar = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY + hhs, centerZ + hhs, depth + 1));
				addNode(_rightTopFar = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY + hhs, centerZ + hhs, depth + 1));
				addNode(_leftBottomFar = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY - hhs, centerZ + hhs, depth + 1));
				addNode(_rightBottomFar = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY - hhs, centerZ + hhs, depth + 1));
			}
		}


		override protected function createDebugBounds() : WireframePrimitiveBase
		{
			var cube : WireframeCube = new WireframeCube(_quadSize, _quadSize, _quadSize);
			cube.x = _centerX;
			cube.y = _centerY;
			cube.z = _centerZ;
			return cube;
		}

		override public function isInFrustum(camera : Camera3D) : Boolean
		{
			var planes : Vector.<Plane3D> = camera.frustumPlanes;
			for (var i : uint = 0; i < 6; ++i) {
				var plane : Plane3D = planes[i];
				var flippedExtentX : Number = plane.a < 0? - _halfExtent : _halfExtent;
				var flippedExtentY : Number = plane.b < 0? - _halfExtent : _halfExtent;
				var flippedExtentZ : Number = plane.c < 0? - _halfExtent : _halfExtent;
				var projDist : Number = plane.a * (_centerX + flippedExtentX) + plane.b * (_centerY + flippedExtentY) + plane.c * (_centerZ + flippedExtentZ) + plane.d;
				if (projDist < 0) return false;
			}

			return true;
		}

		override public function findPartitionForEntity(entity : Entity) : NodeBase
		{
			entity.sceneTransform.transformVectors(entity.bounds.aabbPoints, _entityWorldBounds);

			return findPartitionForBounds(_entityWorldBounds);
		}

		// TODO: this can be done quicker through inversion
		private function findPartitionForBounds(entityWorldBounds : Vector.<Number>) : OctreeNode
		{
			var x : Number, y : Number, z : Number;
			var left : Boolean, right : Boolean;
			var far : Boolean, near : Boolean;
			var top : Boolean, bottom : Boolean;

			if (_leaf)
				return this;

			for (var i : uint = 0; i < 24; i += 3) {
				x = entityWorldBounds[uint(i)];
				y = entityWorldBounds[uint(i+1)];
				z = entityWorldBounds[uint(i+2)];

				if (x > _centerX) {
					if (left) return this;
					right = true;
				}
				else {
					if (right) return this;
					left = true;
				}

				if (y > _centerY) {
					if (bottom) return this;
					top = true;
				}
				else {
					if (top) return this;
					bottom = true;
				}

				if (z > _centerZ) {
					if (near) return this;
					far = true;
				}
				else {
					if (far) return this;
					near = true;
				}
			}

			if (top) {
				if (near) {
					if (left) return _leftTopNear.findPartitionForBounds(entityWorldBounds);
					else return _rightTopNear.findPartitionForBounds(entityWorldBounds);
				}
				else {
					if (left) return _leftTopFar.findPartitionForBounds(entityWorldBounds);
					else return _rightTopFar.findPartitionForBounds(entityWorldBounds);
				}
			}
			else {
				if (near) {
					if (left) return _leftBottomNear.findPartitionForBounds(entityWorldBounds);
					else return _rightBottomNear.findPartitionForBounds(entityWorldBounds);
				}
				else {
					if (left) return _leftBottomFar.findPartitionForBounds(entityWorldBounds);
					else return _rightBottomFar.findPartitionForBounds(entityWorldBounds);
				}
			}
		}
	}
}