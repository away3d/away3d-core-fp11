package away3d.core.math
{
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;

	/**
	 * A Quaternion object which can be used to represent rotations.
	 */
	public final class Quaternion
	{
		/**
		 * The x value of the quaternion.
		 */
		public var x : Number = 0;

		/**
		 * The y value of the quaternion.
		 */
		public var y : Number = 0;

		/**
		 * The z value of the quaternion.
		 */
		public var z : Number = 0;

		/**
		 * The w value of the quaternion.
		 */
		public var w : Number = 1;

		/**
		 * Creates a new Quaternion object.
		 * @param x The x value of the quaternion.
		 * @param y The y value of the quaternion.
		 * @param z The z value of the quaternion.
		 * @param w The w value of the quaternion.
		 */
		public function Quaternion(x : Number = 0, y : Number = 0, z : Number = 0, w : Number = 1)
		{
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		/**
		 * Returns the magnitude of the quaternion object.
		 */
		public function get magnitude() : Number
		{
			return Math.sqrt(w * w + x * x + y * y + z * z);
		}

		/**
		 * Fills the quaternion object with the result from a multiplication of two quaternion objects.
		 *
		 * @param	qa	The first quaternion in the multiplication.
		 * @param	qb	The second quaternion in the multiplication.
		 */
		public function multiply(qa : Quaternion, qb : Quaternion) : void
		{
			var w1 : Number = qa.w, x1 : Number = qa.x, y1 : Number = qa.y, z1 : Number = qa.z;
			var w2 : Number = qb.w, x2 : Number = qb.x, y2 : Number = qb.y, z2 : Number = qb.z;

			w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2;
			x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2;
			y = w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2;
			z = w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2;
		}

		public function multiplyVector(vector : Vector3D, target : Quaternion = null) : Quaternion
		{
			target ||= new Quaternion();

			var x2 : Number = vector.x;
			var y2 : Number = vector.y;
			var z2 : Number = vector.z;

			target.w = - x * x2 - y * y2 - z * z2;
			target.x = w * x2 + y * z2 - z * y2;
			target.y = w * y2 - x * z2 + z * x2;
			target.z = w * z2 + x * y2 - y * x2;

			return target;
		}

		/**
		 * Fills the quaternion object with values representing the given rotation around a vector.
		 *
		 * @param	axis	The axis around which to rotate
		 * @param	angle	The angle in radians of the rotation.
		 */
		public function fromAxisAngle(axis : Vector3D, angle : Number) : void
		{
			var sin_a : Number = Math.sin(angle / 2);
			var cos_a : Number = Math.cos(angle / 2);

			x = axis.x * sin_a;
			y = axis.y * sin_a;
			z = axis.z * sin_a;
			w = cos_a;
			normalize();
		}

		/**
		 * Spherically interpolates between two quaternions, providing an interpolation between rotations with constant angle change rate.
		 * @param qa The first quaternion to interpolate.
		 * @param qb The second quaternion to interpolate.
		 * @param t The interpolation weight, a value between 0 and 1.
		 */
		public function slerp(qa : Quaternion, qb : Quaternion, t : Number) : void
		{
			var w1 : Number = qa.w, x1 : Number = qa.x, y1 : Number = qa.y, z1 : Number = qa.z;
			var w2 : Number = qb.w, x2 : Number = qb.x, y2 : Number = qb.y, z2 : Number = qb.z;
			var dot : Number = w1 * w2 + x1 * x2 + y1 * y2 + z1 * z2;

			// shortest direction
			if (dot < 0) {
				dot = -dot;
				w2 = -w2;
				x2 = -x2;
				y2 = -y2;
				z2 = -z2;
			}

			if (dot < 0.95) {
				// interpolate angle linearly
				var angle : Number = Math.acos(dot);
				var s : Number = 1 / Math.sin(angle);
				var s1 : Number = Math.sin(angle * (1 - t)) * s;
				var s2 : Number = Math.sin(angle * t) * s;
				w = w1 * s1 + w2 * s2;
				x = x1 * s1 + x2 * s2;
				y = y1 * s1 + y2 * s2;
				z = z1 * s1 + z2 * s2;
			}
			else {
				// nearly identical angle, interpolate linearly
				w = w1 + t * (w2 - w1);
				x = x1 + t * (x2 - x1);
				y = y1 + t * (y2 - y1);
				z = z1 + t * (z2 - z1);
				var len : Number = 1.0 / Math.sqrt(w * w + x * x + y * y + z * z);
				w *= len;
				x *= len;
				y *= len;
				z *= len;
			}
		}

		/**
		 * Linearly interpolates between two quaternions.
		 * @param qa The first quaternion to interpolate.
		 * @param qb The second quaternion to interpolate.
		 * @param t The interpolation weight, a value between 0 and 1.
		 */
		public function lerp(qa : Quaternion, qb : Quaternion, t : Number) : void
		{
			var w1 : Number = qa.w, x1 : Number = qa.x, y1 : Number = qa.y, z1 : Number = qa.z;
			var w2 : Number = qb.w, x2 : Number = qb.x, y2 : Number = qb.y, z2 : Number = qb.z;
			var len : Number;

			// shortest direction
			if (w1 * w2 + x1 * x2 + y1 * y2 + z1 * z2 < 0) {
				w2 = -w2;
				x2 = -x2;
				y2 = -y2;
				z2 = -z2;
			}

			w = w1 + t * (w2 - w1);
			x = x1 + t * (x2 - x1);
			y = y1 + t * (y2 - y1);
			z = z1 + t * (z2 - z1);

			len = 1.0 / Math.sqrt(w * w + x * x + y * y + z * z);
			w *= len;
			x *= len;
			y *= len;
			z *= len;
		}

		/**
		 * Fills the quaternion object with values representing the given euler rotation.
		 *
		 * @param	ax		The angle in radians of the rotation around the ax axis.
		 * @param	ay		The angle in radians of the rotation around the ay axis.
		 * @param	az		The angle in radians of the rotation around the az axis.
		 */
		public function fromEulerAngles(ax : Number, ay : Number, az : Number) : void
		{
			var halfX : Number = ax*.5, halfY : Number = ay*.5, halfZ : Number = az*.5;
			var cosX : Number = Math.cos(halfX), sinX : Number = Math.sin(halfX);
			var cosY : Number = Math.cos(halfY), sinY : Number = Math.sin(halfY);
			var cosZ : Number = Math.cos(halfZ), sinZ : Number = Math.sin(halfZ);

			w = cosX*cosY*cosZ + sinX*sinY*sinZ;
			x = sinX*cosY*cosZ - cosX*sinY*sinZ;
			y = cosX*sinY*cosZ + sinX*cosY*sinZ;
			z = cosX*cosY*sinZ - sinX*sinY*cosZ;
		}

		/**
		 * Fills a target Vector3D object with the Euler angles that form the rotation represented by this quaternion.
		 * @param target An optional Vector3D object to contain the Euler angles. If not provided, a new object is created.
		 * @return The Vector3D containing the Euler angles.
		 */
		public function toEulerAngles(target : Vector3D = null) : Vector3D
		{
			target ||= new Vector3D();
			target.x = Math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y));
			target.y = Math.asin(2 * (w * y - z * x));
			target.z = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
			return target;
		}

		/**
		 * Normalises the quaternion object.
		 */
		public function normalize(val : Number = 1) : void
		{
			var mag : Number = val / Math.sqrt(x * x + y * y + z * z + w * w);

			x *= mag;
			y *= mag;
			z *= mag;
			w *= mag;
		}

		/**
		 * Used to trace the values of a quaternion.
		 *
		 * @return A string representation of the quaternion object.
		 */
		public function toString() : String
		{
			return "{x:" + x + " y:" + y + " z:" + z + " w:" + w + "}";
		}

		/**
		 * Converts the quaternion to a Matrix3D object representing an equivalent rotation.
		 * @param target An optional Matrix3D container to store the transformation in. If not provided, a new object is created.
		 * @return A Matrix3D object representing an equivalent rotation.
		 */
		public function toMatrix3D(target : Matrix3D = null) : Matrix3D
		{
			var rawData : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var xy2 : Number = 2.0 * x * y, xz2 : Number = 2.0 * x * z, xw2 : Number = 2.0 * x * w;
			var yz2 : Number = 2.0 * y * z, yw2 : Number = 2.0 * y * w, zw2 : Number = 2.0 * z * w;
			var xx : Number = x * x, yy : Number = y * y, zz : Number = z * z, ww : Number = w * w;

			rawData[0] = xx - yy - zz + ww;
			rawData[4] = xy2 - zw2;
			rawData[8] = xz2 + yw2;
			rawData[12] = 0;
			rawData[1] = xy2 + zw2;
			rawData[5] = -xx + yy - zz + ww;
			rawData[9] = yz2 - xw2;
			rawData[13] = 0;
			rawData[2] = xz2 - yw2;
			rawData[6] = yz2 + xw2;
			rawData[10] = -xx - yy + zz + ww;
			rawData[14] = 0;
			rawData[3] = 0.0;
			rawData[7] = 0.0;
			rawData[11] = 0;
			rawData[15] = 1;

			if (!target) return new Matrix3D(rawData);

			target.copyRawDataFrom(rawData);

			return target;
		}

		/**
		 * Extracts a quaternion rotation matrix out of a given Matrix3D object.
		 * @param matrix The Matrix3D out of which the rotation will be extracted.
		 */
		public function fromMatrix(matrix : Matrix3D) : void
		{
			var v : Vector3D = matrix.decompose(Orientation3D.QUATERNION)[1];
			x = v.x;
			y = v.y;
			z = v.z;
			w = v.w;
		}

		/**
		 * Converts the quaternion to a Vector.&lt;Number&gt; matrix representation of a rotation equivalent to this quaternion.
		 * @param target The Vector.&lt;Number&gt; to contain the raw matrix data.
		 * @param exclude4thRow If true, the last row will be omitted, and a 4x3 matrix will be generated instead of a 4x4.
		 */
		public function toRawData(target : Vector.<Number>, exclude4thRow : Boolean = false) : void
		{
			var xy2 : Number = 2.0 * x * y, xz2 : Number = 2.0 * x * z, xw2 : Number = 2.0 * x * w;
			var yz2 : Number = 2.0 * y * z, yw2 : Number = 2.0 * y * w, zw2 : Number = 2.0 * z * w;
			var xx : Number = x * x, yy : Number = y * y, zz : Number = z * z, ww : Number = w * w;

			target[0] = xx - yy - zz + ww;
			target[1] = xy2 - zw2;
			target[2] = xz2 + yw2;
			target[4] = xy2 + zw2;
			target[5] = -xx + yy - zz + ww;
			target[6] = yz2 - xw2;
			target[8] = xz2 - yw2;
			target[9] = yz2 + xw2;
			target[10] = -xx - yy + zz + ww;
			target[3] = target[7] = target[11] = 0;

			if (!exclude4thRow) {
				target[12] = target[13] = target[14] = 0;
				target[15] = 1;
			}
		}

		/**
		 * Clones the quaternion.
		 * @return An exact duplicate of the current Quaternion.
		 */
		public function clone() : Quaternion
		{
			return new Quaternion(x, y, z, w);
		}


		/**
		 * Rotates a point.
		 * @param vector The Vector3D object to be rotated.
		 * @param target An optional Vector3D object that will contain the rotated coordinates. If not provided, a new object will be created.
		 * @return A Vector3D object containing the rotated point.
		 */
		public function rotatePoint(vector : Vector3D, target : Vector3D = null) : Vector3D
		{
			var x1 : Number, y1 : Number, z1 : Number, w1 : Number;
			var x2 : Number = vector.x, y2 : Number = vector.y, z2 : Number = vector.z;

			target ||= new Vector3D();

			// p*q'
			w1 = - x * x2 - y * y2 - z * z2;
			x1 = w * x2 + y * z2 - z * y2;
			y1 = w * y2 - x * z2 + z * x2;
			z1 = w * z2 + x * y2 - y * x2;

			target.x = -w1 * x + x1 * w - y1 * z + z1 * y;
			target.y = -w1 * y + x1 * z + y1 * w - z1 * x;
			target.z = -w1 * z - x1 * y + y1 * x + z1 * w;

			return target;
		}

		/**
		 * Copies the data from a quaternion into this instance.
		 * @param q The quaternion to copy from.
		 */
		public function copyFrom(q : Quaternion) : void
		{
			x = q.x;
			y = q.y;
			z = q.z;
			w = q.w;
		}
	}
}