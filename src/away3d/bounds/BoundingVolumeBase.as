package away3d.bounds
{
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
    import away3d.core.math.Plane3D;
    import away3d.errors.AbstractMethodError;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * An abstract base class for all bounding volume classes. It should not be instantiated directly.
	 */
	public class BoundingVolumeBase
	{
		protected var _min : Vector3D;
		protected var _max : Vector3D;
		protected var _aabbPoints : Vector.<Number> = new Vector.<Number>();
		protected var _aabbPointsDirty : Boolean = true;

		/**
		 * Creates a new BoundingVolumeBase object
		 */
		public function BoundingVolumeBase()
		{
			_min = new Vector3D();
			_max = new Vector3D();
		}

		/**
		 * Sets the bounds to zero size.
		 */
		public function nullify() : void
		{
			_min.x = _min.y = _min.z = 0;
			_max.x = _max.y = _max.z = 0;
			_aabbPointsDirty = true;
		}

		/**
		 * The maximum extrema of the bounds
		 */
		public function get max() : Vector3D
		{
			return _max;
		}

		/**
		 * The minimum extrema of the bounds
		 */
		public function get min() : Vector3D
		{
			return _min;
		}

		/**
		 * Updates the bounds to fit a list of vertices
		 * @param vertices A Vector.<Number> of vertex data to be bounded.
		 */
		public function fromVertices(vertices : Vector.<Number>) : void
		{
			var i : uint;
			var len : uint = vertices.length;
			var minX : Number, minY : Number, minZ : Number;
			var maxX : Number, maxY : Number, maxZ : Number;

			if (len == 0) {
				nullify();
				return;
			}

			var v : Number;

			minX = maxX = vertices[uint(i++)];
			minY = maxY = vertices[uint(i++)];
			minZ = maxZ = vertices[uint(i++)];

			while (i < len) {
				v = vertices[i++];
				if (v < minX) minX = v;
				else if (v > maxX) maxX = v;
				v = vertices[i++];
				if (v < minY) minY = v;
				else if (v > maxY) maxY = v;
				v = vertices[i++];
				if (v < minZ) minZ = v;
				else if (v > maxZ) maxZ = v;
			}

			fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
		}

		/**
		 * Updates the bounds to fit a Geometry object.
		 * @param geometry The Geometry object to be bounded.
		 */
		public function fromGeometry(geometry : Geometry) : void
		{
			var subs : Vector.<SubGeometry> = geometry.subGeometries;
			var j : uint;
			var lenS : uint = subs.length;
			var lenV : uint;
			var vertices : Vector.<Number>;
			var i : uint;
			var v : Number;
			var minX : Number, minY : Number, minZ : Number;
			var maxX : Number, maxY : Number, maxZ : Number;

			minX = minY = minZ = Number.POSITIVE_INFINITY;
			maxX = maxY = maxZ = Number.NEGATIVE_INFINITY;

			while (j < lenS) {
				vertices = subs[j++].vertexData;
				lenV = vertices.length;
				i = 0;
				while (i < lenV) {
					v = vertices[i++];
					if (v < minX) minX = v;
					else if (v > maxX) maxX = v;
					v = vertices[i++];
					if (v < minY) minY = v;
					else if (v > maxY) maxY = v;
					v = vertices[i++];
					if (v < minZ) minZ = v;
					else if (v > maxZ) maxZ = v;
				}
			}

			fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
		}

		/**
		 * Sets the bound to fit a given sphere.
		 * @param center The center of the sphere to be bounded
		 * @param radius The radius of the sphere to be bounded
		 */
		public function fromSphere(center : Vector3D, radius : Number) : void
		{
			// this is BETTER overridden, because most volumes will have shortcuts for this
			// but then again, sphere already overrides it, and if we'd call "fromSphere", it'd probably need a sphere bound anyway
			fromExtremes(center.x-radius, center.y-radius, center.z-radius, center.x+radius, center.y+radius, center.z+radius);
		}

		/**
		 * Sets the bounds to the given extrema
		 */
		public function fromExtremes(minX : Number, minY : Number, minZ : Number, maxX : Number, maxY : Number, maxZ : Number) : void
		{
			_min.x = minX;
			_min.y = minY;
			_min.z = minZ;
			_max.x = maxX;
			_max.y = maxY;
			_max.z = maxZ;
			_aabbPointsDirty = true;
		}

		/**
		 * Tests if the bounds are in the camera frustum.
		 * @param mvpMatrix The model view projection matrix for the object to which this bounding box belongs.
		 * @return True if the bounding box is at least partially inside the frustum
		 */
		public function isInFrustum(mvpMatrix : Matrix3D) : Boolean
		{
			throw new AbstractMethodError();
			return false;
		}

        /*public function classifyAgainstPlane(plane : Plane3D) : int
        {
            throw new AbstractMethodError();
            return -1;
        }*/

		/**
		 * Clones the current BoundingVolume object
		 * @return An exact duplicate of this object
		 */
		public function clone() : BoundingVolumeBase
		{
			throw new AbstractMethodError();
		}

		public function get aabbPoints() : Vector.<Number>
		{
			if (_aabbPointsDirty)
				updateAABBPoints();

			return _aabbPoints;
		}

		protected function updateAABBPoints() : void
		{
			var i : uint;
			var maxX : Number = _max.x, maxY : Number = _max.y, maxZ : Number = _max.z;
			var minX : Number = _min.x, minY : Number = _min.y, minZ : Number = _min.z;
			_aabbPoints[i++] = minX; _aabbPoints[i++] = minY; _aabbPoints[i++] = minZ;
			_aabbPoints[i++] = maxX; _aabbPoints[i++] = minY; _aabbPoints[i++] = minZ;
			_aabbPoints[i++] = minX; _aabbPoints[i++] = maxY; _aabbPoints[i++] = minZ;
			_aabbPoints[i++] = maxX; _aabbPoints[i++] = maxY; _aabbPoints[i++] = minZ;
			_aabbPoints[i++] = minX; _aabbPoints[i++] = minY; _aabbPoints[i++] = maxZ;
			_aabbPoints[i++] = maxX; _aabbPoints[i++] = minY; _aabbPoints[i++] = maxZ;
			_aabbPoints[i++] = minX; _aabbPoints[i++] = maxY; _aabbPoints[i++] = maxZ;
			_aabbPoints[i++] = maxX; _aabbPoints[i++] = maxY; _aabbPoints[i] = maxZ;
			_aabbPointsDirty = false;
		}
	}
}