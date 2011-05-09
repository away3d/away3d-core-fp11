package away3d.core.base
{
	import away3d.core.math.MathConsts;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.math.Quaternion;
	import away3d.core.math.Vector3DUtils;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * Object3D provides a base class for any 3D object that has a (local) transformation.
	 */
	public class Object3D extends NamedAssetBase
	{
		/**
		 * An object that can contain any extra data.
		 */
		public var extra : Object;
		
		protected var _transform : Matrix3D = new Matrix3D();
		private var _transformDirty : Boolean = true;
		private var _rotationValuesDirty : Boolean;
		private var _scaleValuesDirty : Boolean;

		private var _rotationX : Number = 0;
		private var _rotationY : Number = 0;
		private var _rotationZ : Number = 0;
		private var _eulers : Vector3D = new Vector3D();

		protected var _scaleX : Number = 1;
		protected var _scaleY : Number = 1;
		protected var _scaleZ : Number = 1;

		protected var _pivotPoint : Vector3D = new Vector3D();
		protected var _pivotZero : Boolean = true;

		private var _lookingAtTarget : Vector3D = new Vector3D();

		private var _flipY : Matrix3D = new Matrix3D();

		// used for calculation holders:
		private static var _quaternion : Quaternion = new Quaternion();

		protected var _x : Number = 0;
		protected var _y : Number = 0;
		protected var _z : Number = 0;

		/**
		 * A calculation placeholder.
		 */
		protected var _pos : Vector3D = new Vector3D();

		/**
		 * Creates an Object3D object.
		 */
		public function Object3D()
		{
			_transform.identity();
			_flipY.appendScale(1, -1, 1);
		}
		
		
		/**
		 * The transformation of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get transform() : Matrix3D
		{
			if (_transformDirty)
				updateTransform();

			return _transform;
		}

		public function set transform(value : Matrix3D) : void
		{
			_transform.copyFrom(value);

			_transformDirty = false;
			_rotationValuesDirty = true;
			_scaleValuesDirty = true;
			value.copyRowTo(3, _pos);
			_x = _pos.x;
			_y = _pos.y;
			_z = _pos.z;
		}

		/**
		 * Appends a uniform scale to the current transformation.
		 * @param value The amount by which to scale.
		 */
		public function scale(value : Number) : void
		{
			_scaleX *= value;
			_scaleY *= value;
			_scaleZ *= value;
//			_scaleValuesDirty = false;
			invalidateTransform();
		}

		/**
		 * Moves the 3d object forwards along it's local z axis
		 *
		 * @param	distance	The length of the movement
		 */
		public function moveForward(distance : Number) : void
		{
			translateLocal(Vector3D.Z_AXIS, distance);
		}

		/**
		 * Moves the 3d object backwards along it's local z axis
		 *
		 * @param	distance	The length of the movement
		 */
		public function moveBackward(distance : Number) : void
		{
			translateLocal(Vector3D.Z_AXIS, -distance);
		}

		/**
		 * Moves the 3d object backwards along it's local x axis
		 *
		 * @param	distance	The length of the movement
		 */
		public function moveLeft(distance : Number) : void
		{
			translateLocal(Vector3D.X_AXIS, -distance);
		}

		/**
		 * Moves the 3d object forwards along it's local x axis
		 *
		 * @param	distance	The length of the movement
		 */
		public function moveRight(distance : Number) : void
		{
			translateLocal(Vector3D.X_AXIS, distance);
		}

		/**
		 * Moves the 3d object forwards along it's local y axis
		 *
		 * @param	distance	The length of the movement
		 */
		public function moveUp(distance : Number) : void
		{
			translateLocal(Vector3D.Y_AXIS, distance);
		}

		/**
		 * Moves the 3d object backwards along it's local y axis
		 *
		 * @param	distance	The length of the movement
		 */
		public function moveDown(distance : Number) : void
		{
			translateLocal(Vector3D.Y_AXIS, -distance);
		}

		/**
		 * Moves the 3d object directly to a point in space
		 *
		 * @param	dx		The amount of movement along the local x axis.
		 * @param	dy		The amount of movement along the local y axis.
		 * @param	dz		The amount of movement along the local z axis.
		 */
		public function moveTo(dx : Number, dy : Number, dz : Number) : void
		{
			if (_x == dx && _y == dy && _z == dz) return;
			_x = dx;
			_y = dy;
			_z = dz;

			invalidateTransform();
		}

		/**
		 * Moves the local point around which the object rotates.
		 *
		 * @param	dx		The amount of movement along the local x axis.
		 * @param	dy		The amount of movement along the local y axis.
		 * @param	dz		The amount of movement along the local z axis.
		 */
		public function movePivot(dx : Number, dy : Number, dz : Number) : void
		{
			_pivotPoint.x = dx;
			_pivotPoint.y = dy;
			_pivotPoint.z = dz;

			invalidateTransform();
		}

		/**
		 * Defines the local point around which the object rotates.
		 */
		public function get pivotPoint() : Vector3D
		{
			return _pivotPoint;
		}

		public function set pivotPoint(pivot : Vector3D) : void
		{
			_pivotPoint = pivot.clone();

			_pivotZero = (_pivotPoint.x == 0) && (_pivotPoint.y == 0) && (_pivotPoint.z == 0);

			invalidateTransform();
		}

		/**
		 * Moves the 3d object along a vector by a defined length
		 *
		 * @param	axis		The vector defining the axis of movement
		 * @param	distance	The length of the movement
		 */
		public function translate(axis : Vector3D, distance : Number) : void
		{
			var x : Number = axis.x, y : Number = axis.y, z : Number = axis.z;
			var len : Number = distance / Math.sqrt(x * x + y * y + z * z);

			_x += x * len;
			_y += y * len;
			_z += z * len;

			invalidateTransform();
		}

		/**
		 * Moves the 3d object along a vector by a defined length
		 *
		 * @param	axis		The vector defining the axis of movement
		 * @param	distance	The length of the movement
		 */
		public function translateLocal(axis : Vector3D, distance : Number) : void
		{
			var x : Number = axis.x, y : Number = axis.y, z : Number = axis.z;
			var len : Number = distance / Math.sqrt(x * x + y * y + z * z);

			transform.prependTranslation(x*len, y*len, z*len);
			_transform.copyRowTo(3, _pos);
			_x = _pos.x;
			_y = _pos.y;
			_z = _pos.z;
		}

		/**
		 * Defines the position of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get position() : Vector3D
		{
			transform.copyRowTo(3, _pos);
			return _pos;
		}

		public function set position(value : Vector3D) : void
		{
			_x = value.x;
			_y = value.y;
			_z = value.z;
			invalidateTransform();
		}

		/**
		 * Rotates the 3d object around it's local x-axis
		 *
		 * @param	angle		The amount of rotation in degrees
		 */
		public function pitch(angle : Number) : void
		{
			rotate(Vector3D.X_AXIS, angle);
		}

		/**
		 * Rotates the 3d object around it's local y-axis
		 *
		 * @param	angle		The amount of rotation in degrees
		 */
		public function yaw(angle : Number) : void
		{
			rotate(Vector3D.Y_AXIS, angle);
		}

		/**
		 * Rotates the 3d object around it's local z-axis
		 *
		 * @param	angle		The amount of rotation in degrees
		 */
		public function roll(angle : Number) : void
		{
			rotate(Vector3D.Z_AXIS, angle);
		}

		public function clone() : Object3D
		{
			var clone : Object3D = new Object3D();
			clone.pivotPoint = pivotPoint;
			clone.transform = transform;
			// todo: implement for all subtypes
			return clone;
		}

		/**
		 * Rotates the 3d object directly to a euler angle
		 *
		 * @param	ax		The angle in degrees of the rotation around the x axis.
		 * @param	ay		The angle in degrees of the rotation around the y axis.
		 * @param	az		The angle in degrees of the rotation around the z axis.
		 */
		public function rotateTo(ax : Number, ay : Number, az : Number) : void
		{
			_rotationX = ax * MathConsts.DEGREES_TO_RADIANS;
			_rotationY = ay * MathConsts.DEGREES_TO_RADIANS;
			_rotationZ = az * MathConsts.DEGREES_TO_RADIANS;
			_rotationValuesDirty = false;

			invalidateTransform();
		}

		/**
		 * Rotates the 3d object around an axis by a defined angle
		 *
		 * @param	axis		The vector defining the axis of rotation
		 * @param	angle		The amount of rotation in degrees
		 */
		public function rotate(axis : Vector3D, angle : Number) : void
		{
			// notify
			invalidateTransform();

			axis.normalize();

			transform.prependRotation(angle, axis);

			_rotationValuesDirty = true;
		}

		/**
		 * Rotates the 3d object around to face a point defined relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 *
		 * @param	target		The vector defining the point to be looked at
		 * @param	upAxis		An optional vector used to define the desired up orientation of the 3d object after rotation has occurred
		 */
		public function lookAt(target : Vector3D, upAxis : Vector3D = null) : void
		{
			_lookingAtTarget = target;

			var yAxis : Vector3D, zAxis : Vector3D, xAxis : Vector3D;
			var raw : Vector.<Number>;

			upAxis ||= Vector3D.Y_AXIS;

			zAxis = target.subtract(position);
			zAxis.normalize();

			xAxis = upAxis.crossProduct(zAxis);
			xAxis.normalize();

//			if (xAxis.length < .05) {
//				xAxis = upAxis.crossProduct(Vector3D.Z_AXIS);
//			}

			yAxis = zAxis.crossProduct(xAxis);

			raw = Matrix3DUtils.RAW_DATA_CONTAINER;
			_transform.copyRawDataTo(raw);

			raw[uint(0)] = _scaleX*xAxis.x;
			raw[uint(1)] = _scaleX*xAxis.y;
			raw[uint(2)] = _scaleX*xAxis.z;

			raw[uint(4)] = _scaleY*yAxis.x;
			raw[uint(5)] = _scaleY*yAxis.y;
			raw[uint(6)] = _scaleY*yAxis.z;

			raw[uint(8)] = _scaleZ*zAxis.x;
			raw[uint(9)] = _scaleZ*zAxis.y;
			raw[uint(10)] = _scaleZ*zAxis.z;

			_transform.copyRawDataFrom(raw);

			_rotationValuesDirty = true;
		}


		/**
		 * Defines the x coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get x() : Number
		{
			return _x;
		}

		public function set x(value : Number) : void
		{
			if (_x == value) return;
			if (value != value) throw new Error("isNaN(x)");
			_x = value;
			invalidateTransform();
		}

		/**
		 * Defines the y coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get y() : Number
		{
			return _y;
		}

		public function set y(value : Number) : void
		{
			if (_y == value) return;
			if (!(value > 0) && !(value <= 0)) throw new Error("isNaN(x)");
			_y = value;
			invalidateTransform();
		}

		/**
		 * Defines the z coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get z() : Number
		{
			return _z;
		}

		public function set z(value : Number) : void
		{
			if (_z == value) return;
			if (!(value > 0) && !(value <= 0)) throw new Error("isNaN(x)");
			_z = value;
			invalidateTransform();
		}

		/**
		 * Defines the euler angle of rotation of the 3d object around the x-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationX() : Number
		{
			if (_rotationValuesDirty) updateTransformValues();

			return _rotationX * MathConsts.RADIANS_TO_DEGREES;
		}

		public function set rotationX(rot : Number) : void
		{
			if (rotationX == rot) return;

			_rotationX = rot * MathConsts.DEGREES_TO_RADIANS;

			invalidateTransform();
		}

		/**
		 * Defines the euler angle of rotation of the 3d object around the y-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationY() : Number
		{
			if (_rotationValuesDirty) updateTransformValues();

			return _rotationY * MathConsts.RADIANS_TO_DEGREES;
		}

		public function set rotationY(rot : Number) : void
		{
			if (rotationY == rot) return;

			_rotationY = rot * MathConsts.DEGREES_TO_RADIANS;

			invalidateTransform();
		}

		/**
		 * Defines the euler angle of rotation of the 3d object around the z-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationZ() : Number
		{
			if (_rotationValuesDirty) updateTransformValues();

			return _rotationZ * MathConsts.RADIANS_TO_DEGREES;
		}

		public function set rotationZ(rot : Number) : void
		{
			if (rotationZ == rot) return;

			_rotationZ = rot * MathConsts.DEGREES_TO_RADIANS;

			invalidateTransform();
		}

		/**
		 * Defines the scale of the 3d object along the x-axis, relative to local coordinates.
		 */
		public function get scaleX() : Number
		{
			if (_scaleValuesDirty) updateTransformValues();
			return _scaleX;
		}

		public function set scaleX(scale : Number) : void
		{
			if (scaleX == scale) return;

			_scaleX = scale;

			invalidateTransform();
		}

		/**
		 * Defines the scale of the 3d object along the y-axis, relative to local coordinates.
		 */
		public function get scaleY() : Number
		{
			if (_scaleValuesDirty) updateTransformValues();
			return _scaleY;
		}

		public function set scaleY(scale : Number) : void
		{
			if (scaleY == scale) return;

			_scaleY = scale;

			invalidateTransform();
		}

		/**
		 * Defines the scale of the 3d object along the z-axis, relative to local coordinates.
		 */
		public function get scaleZ() : Number
		{
			if (_scaleValuesDirty) updateTransformValues();
			return _scaleZ;
		}

		public function set scaleZ(scale : Number) : void
		{
			if (scaleZ == scale) return;

			_scaleZ = scale;

			_transformDirty = true;

			invalidateTransform();
		}

		/**
		 * Defines the rotation of the 3d object as a <code>Vector3D</code> object containing euler angles for rotation around x, y and z axis.
		 */
		public function get eulers() : Vector3D
		{
			if (_rotationValuesDirty) updateTransformValues();

			_eulers.x = _rotationX * MathConsts.RADIANS_TO_DEGREES;
			_eulers.y = _rotationY * MathConsts.RADIANS_TO_DEGREES;
			_eulers.z = _rotationZ * MathConsts.RADIANS_TO_DEGREES;

			return _eulers;
		}

		public function set eulers(value : Vector3D) : void
		{
			_rotationX = value.x * MathConsts.RADIANS_TO_DEGREES;
			_rotationY = value.y * MathConsts.RADIANS_TO_DEGREES;
			_rotationZ = value.z * MathConsts.RADIANS_TO_DEGREES;
			_rotationValuesDirty = false;
			invalidateTransform();
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose(deep : Boolean) : void
		{
		}

		/**
		 * Invalidates the transformation matrix, causing it to be updated upon the next request
		 */
		protected function invalidateTransform() : void
		{
			_transformDirty = true;
		}

		protected function updateTransform() : void
		{
			if (_rotationValuesDirty || _scaleValuesDirty) updateTransformValues();

			_quaternion.fromEulerAngles(_rotationY, _rotationZ, -_rotationX); // Swapped

			if (_pivotZero) {
				Matrix3DUtils.quaternion2matrix(_quaternion, _transform);
				_transform.prependScale(_scaleX, _scaleY, _scaleZ);
				_transform.appendTranslation(_x, _y, _z);
			}
			else {
				_transform.identity();
				_transform.appendTranslation(-_pivotPoint.x, -_pivotPoint.y, -_pivotPoint.z);
				_transform.append(Matrix3DUtils.quaternion2matrix(_quaternion));
				_transform.appendTranslation(_x + _pivotPoint.x, _y + _pivotPoint.y, _z + _pivotPoint.z);
				_transform.prependScale(_scaleX, _scaleY, _scaleZ);
			}

			_transformDirty = false;
		}

		private function updateTransformValues() : void
		{
			var raw : Vector.<Number>;
			var rot : Vector3D;
			var x : Number, y : Number, z : Number;

			if (_rotationValuesDirty) {
//				_quaternion.fromMatrix(_transform);
				rot = Vector3DUtils.matrix2euler(_transform);
				_rotationX = rot.x;
				_rotationY = rot.y;
				_rotationZ = rot.z;
				_rotationValuesDirty = false;
			}

			if (_scaleValuesDirty) {
				raw = Matrix3DUtils.RAW_DATA_CONTAINER;
				_transform.copyRawDataTo(raw);
				x = raw[uint(0)];
				y = raw[uint(1)];
				z = raw[uint(2)];
				_scaleX = Math.sqrt(x * x + y * y + z * z);
				x = raw[uint(4)];
				y = raw[uint(5)];
				z = raw[uint(6)];
				_scaleY = Math.sqrt(x * x + y * y + z * z);
				x = raw[uint(8)];
				y = raw[uint(9)];
				z = raw[uint(10)];
				_scaleZ = Math.sqrt(x * x + y * y + z * z);
				_scaleValuesDirty = false;
			}
		}
    }
}