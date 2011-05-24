package away3d.core.partition
{
	import away3d.bounds.AxisAlignedBoundingBox;
	import away3d.cameras.Camera3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.entities.Entity;

	import flash.geom.Matrix3D;

	public class OctreeNode extends NodeBase
	{
		private var _centerX : Number;
		private var _centerY : Number;
		private var _centerZ : Number;
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
			_halfExtent = size * .5;
			_centerX = centerX;
			_centerY = centerY;
			_centerZ = centerZ;
			_quadSize = size;
			_depth = depth;

			_leaf = depth == maxDepth;

			if (!_leaf) {
				var hhs : Number = _halfExtent*.5;
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

		override public function isInFrustum(camera : Camera3D) : Boolean
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var mvpMatrix : Matrix3D = camera.viewProjection;
			mvpMatrix.copyRawDataTo(raw);
			var c11 : Number = raw[uint(0)], c12 : Number = raw[uint(4)], c13 : Number = raw[uint(8)], c14 : Number = raw[uint(12)];
			var c21 : Number = raw[uint(1)], c22 : Number = raw[uint(5)], c23 : Number = raw[uint(9)], c24 : Number = raw[uint(13)];
			var c31 : Number = raw[uint(2)], c32 : Number = raw[uint(6)], c33 : Number = raw[uint(10)], c34 : Number = raw[uint(14)];
			var c41 : Number = raw[uint(3)], c42 : Number = raw[uint(7)], c43 : Number = raw[uint(11)], c44 : Number = raw[uint(15)];
			var a : Number, b : Number, c : Number, d : Number;
			var dd : Number, rr : Number;

			// this is basically a p/n vertex test in object space against the frustum planes derived from the mvp
			// with a lot of inlining

		// left plane
			a = c41 + c11; b = c42 + c12; c = c43 + c13; d = c44 + c14;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = _halfExtent*(a + b + c);
			if (dd + rr < -d) return false;
		// right plane
			a = c41 - c11; b = c42 - c12; c = c43 - c13; d = c44 - c14;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = _halfExtent*(a + b + c);
			if (dd + rr < -d) return false;
		// bottom plane
			a = c41 + c21; b = c42 + c22; c = c43 + c23; d = c44 + c24;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = _halfExtent*(a + b + c);
			if (dd + rr < -d) return false;
		// top plane
			a = c41 - c21; b = c42 - c22; c = c43 - c23; d = c44 - c24;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = _halfExtent*(a + b + c);
			if (dd + rr < -d) return false;
		// near plane
			a = c31; b = c32; c = c33; d = c34;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = _halfExtent*(a + b + c);
			if (dd + rr < -d) return false;
		// far plane
			a = c41 - c31; b = c42 - c32; c = c43 - c33; d = c44 - c34;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = _halfExtent*(a + b + c);
			if (dd + rr < -d) return false;

			return true;
		}

		override public function findPartitionForEntity(entity : Entity) : NodeBase
		{
			entity.sceneTransform.transformVectors(entity.bounds.aabbPoints, _entityWorldBounds);

			return findPartitionForBounds(_entityWorldBounds);
		}

		private function findPartitionForBounds(entityWorldBounds : Vector.<Number>) : OctreeNode
		{
			var i : int;
			var x : Number, y : Number, z : Number;
			var left : Boolean, right : Boolean;
			var far : Boolean, near : Boolean;
			var top : Boolean, bottom : Boolean;

			if (_leaf)
				return this;

			while (i < 24) {
				x = entityWorldBounds[i++];
				y = entityWorldBounds[i++];
				z = entityWorldBounds[i++];

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