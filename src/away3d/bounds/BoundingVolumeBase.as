package away3d.bounds
{
	import away3d.arcane;
	import away3d.core.base.*;
	import away3d.core.math.Plane3D;
	import away3d.errors.*;
	import away3d.primitives.*;
	
	import flash.geom.*;
	
	use namespace arcane;
	
	/**
	 * An abstract base class for all bounding volume classes. It should not be instantiated directly.
	 */
	public class BoundingVolumeBase
	{
		protected var _min:Vector3D;
		protected var _max:Vector3D;
		protected var _aabbPoints:Vector.<Number> = new Vector.<Number>();
		protected var _aabbPointsDirty:Boolean = true;
		protected var _boundingRenderable:WireframePrimitiveBase;
		
		/**
		 * The maximum extreme of the bounds
		 */
		public function get max():Vector3D
		{
			return _max;
		}
		
		/**
		 * The minimum extreme of the bounds
		 */
		public function get min():Vector3D
		{
			return _min;
		}
		
		/**
		 * Returns a vector of values representing the concatenated cartesian triplet of the 8 axial extremities of the bounding volume.
		 */
		public function get aabbPoints():Vector.<Number>
		{
			if (_aabbPointsDirty)
				updateAABBPoints();
			
			return _aabbPoints;
		}
		
		/**
		 * Returns the bounding renderable object for the bounding volume, in cases where the showBounds
		 * property of the entity is set to true.
		 *
		 * @see away3d.entities.Entity#showBounds
		 */
		public function get boundingRenderable():WireframePrimitiveBase
		{
			if (!_boundingRenderable) {
				_boundingRenderable = createBoundingRenderable();
				updateBoundingRenderable();
			}
			
			return _boundingRenderable;
		}
		
		/**
		 * Creates a new <code>BoundingVolumeBase</code> object
		 */
		public function BoundingVolumeBase()
		{
			_min = new Vector3D();
			_max = new Vector3D();
		}
		
		/**
		 * Sets the bounds to zero size.
		 */
		public function nullify():void
		{
			_min.x = _min.y = _min.z = 0;
			_max.x = _max.y = _max.z = 0;
			_aabbPointsDirty = true;
			if (_boundingRenderable)
				updateBoundingRenderable();
		}
		
		/**
		 * Disposes of the bounds renderable object. Used to clear memory after a bounds rendeable is no longer required.
		 */
		public function disposeRenderable():void
		{
			if (_boundingRenderable)
				_boundingRenderable.dispose();
			_boundingRenderable = null;
		}
		
		/**
		 * Updates the bounds to fit a list of vertices
		 *
		 * @param vertices A Vector.&lt;Number&gt; of vertex data to be bounded.
		 */
		public function fromVertices(vertices:Vector.<Number>):void
		{
			var i:uint;
			var len:uint = vertices.length;
			var minX:Number, minY:Number, minZ:Number;
			var maxX:Number, maxY:Number, maxZ:Number;
			
			if (len == 0) {
				nullify();
				return;
			}
			
			var v:Number;
			
			minX = maxX = vertices[uint(i++)];
			minY = maxY = vertices[uint(i++)];
			minZ = maxZ = vertices[uint(i++)];
			
			while (i < len) {
				v = vertices[i++];
				if (v < minX)
					minX = v;
				else if (v > maxX)
					maxX = v;
				v = vertices[i++];
				if (v < minY)
					minY = v;
				else if (v > maxY)
					maxY = v;
				v = vertices[i++];
				if (v < minZ)
					minZ = v;
				else if (v > maxZ)
					maxZ = v;
			}
			
			fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
		}
		
		/**
		 * Updates the bounds to fit a Geometry object.
		 *
		 * @param geometry The Geometry object to be bounded.
		 */
		public function fromGeometry(geometry:Geometry):void
		{
			var subGeoms:Vector.<ISubGeometry> = geometry.subGeometries;
			var numSubGeoms:uint = subGeoms.length;
			var minX:Number, minY:Number, minZ:Number;
			var maxX:Number, maxY:Number, maxZ:Number;
			
			if (numSubGeoms > 0) {
				var j:uint = 0;
				minX = minY = minZ = Number.POSITIVE_INFINITY;
				maxX = maxY = maxZ = Number.NEGATIVE_INFINITY;
				
				while (j < numSubGeoms) {
					var subGeom:ISubGeometry = subGeoms[j++];
					var vertices:Vector.<Number> = subGeom.vertexData;
					var vertexDataLen:uint = vertices.length;
					var i:uint = subGeom.vertexOffset;
					var stride:uint = subGeom.vertexStride;
					
					while (i < vertexDataLen) {
						var v:Number = vertices[i];
						if (v < minX)
							minX = v;
						else if (v > maxX)
							maxX = v;
						v = vertices[i + 1];
						if (v < minY)
							minY = v;
						else if (v > maxY)
							maxY = v;
						v = vertices[i + 2];
						if (v < minZ)
							minZ = v;
						else if (v > maxZ)
							maxZ = v;
						i += stride;
					}
				}
				
				fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
			} else
				fromExtremes(0, 0, 0, 0, 0, 0);
		}
		
		/**
		 * Sets the bound to fit a given sphere.
		 *
		 * @param center The center of the sphere to be bounded
		 * @param radius The radius of the sphere to be bounded
		 */
		public function fromSphere(center:Vector3D, radius:Number):void
		{
			// this is BETTER overridden, because most volumes will have shortcuts for this
			// but then again, sphere already overrides it, and if we'd call "fromSphere", it'd probably need a sphere bound anyway
			fromExtremes(center.x - radius, center.y - radius, center.z - radius, center.x + radius, center.y + radius, center.z + radius);
		}
		
		/**
		 * Sets the bounds to the given extrema.
		 *
		 * @param minX The minimum x value of the bounds
		 * @param minY The minimum y value of the bounds
		 * @param minZ The minimum z value of the bounds
		 * @param maxX The maximum x value of the bounds
		 * @param maxY The maximum y value of the bounds
		 * @param maxZ The maximum z value of the bounds
		 */
		public function fromExtremes(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number):void
		{
			_min.x = minX;
			_min.y = minY;
			_min.z = minZ;
			_max.x = maxX;
			_max.y = maxY;
			_max.z = maxZ;
			_aabbPointsDirty = true;
			if (_boundingRenderable)
				updateBoundingRenderable();
		}
		
		/**
		 * Tests if the bounds are in the camera frustum.
		 *
		 * @param mvpMatrix The model view projection matrix for the object to which this bounding box belongs.
		 * @return True if the bounding box is at least partially inside the frustum
		 */
		public function isInFrustum(planes:Vector.<Plane3D>, numPlanes:int):Boolean
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Tests if the bounds overlap other bounds, treating both bounds as AABBs.
		 */
		public function overlaps(bounds:BoundingVolumeBase):Boolean
		{
			var min:Vector3D = bounds._min;
			var max:Vector3D = bounds._max;
			return _max.x > min.x &&
				_min.x < max.x &&
				_max.y > min.y &&
				_min.y < max.y &&
				_max.z > min.z &&
				_min.z < max.z;
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
		public function clone():BoundingVolumeBase
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Method for calculating whether an intersection of the given ray occurs with the bounding volume.
		 *
		 * @param position The starting position of the casting ray in local coordinates.
		 * @param direction A unit vector representing the direction of the casting ray in local coordinates.
		 * @param targetNormal The vector to store the bounds' normal at the point of collision
		 * @return A Boolean value representing the detection of an intersection.
		 */
		public function rayIntersection(position:Vector3D, direction:Vector3D, targetNormal:Vector3D):Number
		{
			position = position;
			direction = direction;
			targetNormal = targetNormal;
			return -1;
		}
		
		/**
		 * Method for calculating whether the given position is contained within the bounding volume.
		 *
		 * @param position The position in local coordinates to be checked.
		 * @return A Boolean value representing the detection of a contained position.
		 */
		public function containsPoint(position:Vector3D):Boolean
		{
			position = position;
			return false;
		}
		
		protected function updateAABBPoints():void
		{
			var maxX:Number = _max.x, maxY:Number = _max.y, maxZ:Number = _max.z;
			var minX:Number = _min.x, minY:Number = _min.y, minZ:Number = _min.z;
			_aabbPoints[0] = minX;
			_aabbPoints[1] = minY;
			_aabbPoints[2] = minZ;
			_aabbPoints[3] = maxX;
			_aabbPoints[4] = minY;
			_aabbPoints[5] = minZ;
			_aabbPoints[6] = minX;
			_aabbPoints[7] = maxY;
			_aabbPoints[8] = minZ;
			_aabbPoints[9] = maxX;
			_aabbPoints[10] = maxY;
			_aabbPoints[11] = minZ;
			_aabbPoints[12] = minX;
			_aabbPoints[13] = minY;
			_aabbPoints[14] = maxZ;
			_aabbPoints[15] = maxX;
			_aabbPoints[16] = minY;
			_aabbPoints[17] = maxZ;
			_aabbPoints[18] = minX;
			_aabbPoints[19] = maxY;
			_aabbPoints[20] = maxZ;
			_aabbPoints[21] = maxX;
			_aabbPoints[22] = maxY;
			_aabbPoints[23] = maxZ;
			_aabbPointsDirty = false;
		}
		
		protected function updateBoundingRenderable():void
		{
			throw new AbstractMethodError();
		}
		
		protected function createBoundingRenderable():WireframePrimitiveBase
		{
			throw new AbstractMethodError();
		}
		
		public function classifyToPlane(plane:Plane3D):int
		{
			throw new AbstractMethodError();
		}
		
		public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):void
		{
			throw new AbstractMethodError();
		}
	}
}
