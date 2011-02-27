package away3d.bounds
{
	import away3d.core.math.Matrix3DUtils;

	import flash.geom.Matrix3D;

	/**
	 * AxisAlignedBoundingBox represents a bounding box volume that has its planes aligned to the local coordinate axes of the bounded object.
	 * This is useful for most meshes.
	 */
	public class AxisAlignedBoundingBox extends BoundingVolumeBase
	{
		private var _centerX : Number = 0;
		private var _centerY : Number = 0;
		private var _centerZ : Number = 0;
		private var _halfExtentsX : Number = 0;
		private var _halfExtentsY : Number = 0;
		private var _halfExtentsZ : Number = 0;

		/**
		 * Creates a new AxisAlignedBoundingBox object.
		 */
		public function AxisAlignedBoundingBox()
		{
		}

		/**
		 * @inheritDoc
		 */
		override public function nullify() : void
		{
			_centerX = _centerY = _centerZ = 0;
			_halfExtentsX = _halfExtentsY = _halfExtentsZ = 0;
		}

		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(mvpMatrix : Matrix3D) : Boolean
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
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
			rr = a*_halfExtentsX + b*_halfExtentsY+ c*_halfExtentsZ;
			if (dd + rr < -d) return false;
		// right plane
			a = c41 - c11; b = c42 - c12; c = c43 - c13; d = c44 - c14;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = a*_halfExtentsX + b*_halfExtentsY+ c*_halfExtentsZ;
			if (dd + rr < -d) return false;
		// bottom plane
			a = c41 + c21; b = c42 + c22; c = c43 + c23; d = c44 + c24;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = a*_halfExtentsX + b*_halfExtentsY+ c*_halfExtentsZ;
			if (dd + rr < -d) return false;
		// top plane
			a = c41 - c21; b = c42 - c22; c = c43 - c23; d = c44 - c24;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = a*_halfExtentsX + b*_halfExtentsY+ c*_halfExtentsZ;
			if (dd + rr < -d) return false;
		// near plane
			a = c31; b = c32; c = c33; d = c34;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = a*_halfExtentsX + b*_halfExtentsY+ c*_halfExtentsZ;
			if (dd + rr < -d) return false;
		// far plane
			a = c41 - c31; b = c42 - c32; c = c43 - c33; d = c44 - c34;
			dd = a*_centerX + b*_centerY + c*_centerZ;
			if (a < 0) a = -a; if (b < 0) b = -b; if (c < 0) c = -c;
			rr = a*_halfExtentsX + b*_halfExtentsY+ c*_halfExtentsZ;
			if (dd + rr < -d) return false;

			return true;
		}

		/**
		 * @inheritDoc
		 */
		override public function fromExtremes(minX : Number, minY : Number, minZ : Number, maxX : Number, maxY : Number, maxZ : Number) : void
		{
			super.fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
			_centerX = (maxX + minX)*.5;
			_centerY = (maxY + minY)*.5;
			_centerZ = (maxZ + minZ)*.5;
			_halfExtentsX = (maxX - minX)*.5;
			_halfExtentsY = (maxY - minY)*.5;
			_halfExtentsZ = (maxZ - minZ)*.5;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone() : BoundingVolumeBase
		{
			var clone : AxisAlignedBoundingBox = new AxisAlignedBoundingBox();
			clone.fromExtremes(_min.x, _min.y, _min.z, _max.x, _max.y, _max.z);
			return clone;
		}
	}
}