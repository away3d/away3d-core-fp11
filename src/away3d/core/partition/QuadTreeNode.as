package away3d.core.partition
{
	import away3d.bounds.AxisAlignedBoundingBox;
	import away3d.cameras.Camera3D;
	import away3d.entities.Entity;

	public class QuadTreeNode extends NodeBase
	{
		private var _centerX : Number;
		private var _centerZ : Number;
		private var _quadSize : Number;
		private var _depth : Number;
		private var _leaf : Boolean;

		private var _rightFar : QuadTreeNode;
		private var _leftFar : QuadTreeNode;
		private var _rightNear : QuadTreeNode;
		private var _leftNear : QuadTreeNode;

		private var _aabb : AxisAlignedBoundingBox;

		private var _entityWorldBounds : Vector.<Number> = new Vector.<Number>();

		public function QuadTreeNode(maxDepth : int = 5, size : Number = 10000, height : Number = 1000000, centerX : Number = 0, centerZ : Number = 0, depth : int = 0)
		{
			var hs : Number = size * .5;
			// todo: replace aabb & frustum test with proper quadtree testing code
			_aabb = new AxisAlignedBoundingBox();
			_aabb.fromExtremes(centerX - hs, -height*.5, centerZ - hs, centerX + hs, height*.5, centerZ + hs);
			_centerX = centerX;
			_centerZ = centerZ;
			_quadSize = size;
			_depth = depth;

			_leaf = depth == maxDepth;

			if (!_leaf) {
				var hhs : Number = hs*.5;
				addNode(_leftNear = new QuadTreeNode(maxDepth, hs, height, centerX - hhs, centerZ - hhs, depth + 1));
				addNode(_rightNear = new QuadTreeNode(maxDepth, hs, height, centerX + hhs, centerZ - hhs, depth + 1));
				addNode(_leftFar = new QuadTreeNode(maxDepth, hs, height, centerX - hhs, centerZ + hhs, depth + 1));
				addNode(_rightFar = new QuadTreeNode(maxDepth, hs, height, centerX + hhs, centerZ + hhs, depth + 1));
			}
		}

		override public function isInFrustum(camera : Camera3D) : Boolean
		{
			if (_aabb.isInFrustum(camera.viewProjection))
				return true;
			else
				return false;
		}

		override public function findPartitionForEntity(entity : Entity) : NodeBase
		{
			entity.sceneTransform.transformVectors(entity.bounds.aabbPoints, _entityWorldBounds);

			return findPartitionForBounds(_entityWorldBounds);
		}

		private function findPartitionForBounds(entityWorldBounds : Vector.<Number>) : QuadTreeNode
		{
			var i : int;
			var x : Number, z : Number;
			var left : Boolean, right : Boolean;
			var far : Boolean, near : Boolean;

			if (_leaf)
				return this;

			while (i < 24) {
				x = entityWorldBounds[i];
				z = entityWorldBounds[i + 2];
				i += 3;

				if (x > _centerX) {
					if (left) return this;
					right = true;
				}
				else {
					if (right) return this;
					left = true;
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

			if (near) {
				if (left) return _leftNear.findPartitionForBounds(entityWorldBounds);
				else return _rightNear.findPartitionForBounds(entityWorldBounds);
			}
			else {
				if (left) return _leftFar.findPartitionForBounds(entityWorldBounds);
				else return _rightFar.findPartitionForBounds(entityWorldBounds);
			}
		}
	}
}