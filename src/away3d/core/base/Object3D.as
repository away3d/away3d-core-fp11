package away3d.core.base
{
	import away3d.arcane;
	import away3d.controllers.*;
	import away3d.core.math.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * Object3D provides a base class for any 3D object that has a (local) transformation.
	 *
	 * Standard Transform:
	 * - The standard order for transformation is [parent transform] * (Translate+Pivot) * (Rotate) * (-Pivot) * (Scale) * [child transform]
	 *   - This is the order of matrix multiplications, left-to-right.
	 *   - The order of transformation is right-to-left, however!
	 *       (Scale) happens before (-Pivot) happens before (Rotate) happens before (Translate+Pivot)
	 *   - with no pivot, the above transform works out to [parent transform] * Translate * Rotate * Scale * [child transform]
	 *       (Scale) happens before (Rotate) happens before (Translate)
	 *   - This is based on code in updateTransform and ObjectContainer3D.updateSceneTransform().
	 *   - Matrix3D prepend = operator on rhs - e.g. transform' = transform * rhs;
	 *   - Matrix3D append =  operator on lhr - e.g. transform' = lhs * transform;
	 *
	 * To affect Scale:
	 * - set scaleX/Y/Z directly, or call scale(delta)
	 *
	 * To affect Pivot:
	 * - set pivotPoint directly, or call movePivot()
	 *
	 * To affect Rotate:
	 * - set rotationX/Y/Z individually (using degrees), set eulers [all 3 angles] (using radians), or call rotateTo()
	 * - call pitch()/yaw()/roll()/rotate() to add an additional rotation *before* the current transform.
	 *     rotationX/Y/Z will be reset based on these operations.
	 *
	 * To affect Translate (post-rotate translate):
	 * - set x/y/z/position or call moveTo().
	 * - call translate(), which modifies x/y/z based on a delta vector.
	 * - call moveForward()/moveBackward()/moveLeft()/moveRight()/moveUp()/moveDown()/translateLocal() to add an
	 *     additional translate *before* the current transform. x/y/z will be reset based on these operations.
	 */
	
	public class Object3D extends NamedAssetBase
	{
		/** @private */
		arcane var _controller:ControllerBase;
		
		private var _smallestNumber:Number = 0.0000000000000000000001;
		private var _transformDirty : Boolean = true;
		
		private var _positionDirty:Boolean;
		private var _rotationDirty:Boolean;
		private var _scaleDirty:Boolean;
		
		// TODO: not used
		// private var _positionValuesDirty:Boolean;
		// private var _rotationValuesDirty:Boolean;
		// private var _scaleValuesDirty:Boolean;
		
		private var _positionChanged:Object3DEvent;
		private var _rotationChanged:Object3DEvent;
		private var _scaleChanged:Object3DEvent;
		
		private var _rotationX : Number = 0;
		private var _rotationY : Number = 0;
		private var _rotationZ : Number = 0;
		private var _eulers : Vector3D = new Vector3D();

		private var _flipY : Matrix3D = new Matrix3D();
		
		private function notifyPositionChange():void
		{
			if (_positionDirty)
				return;
			
			invalidateTransform();
			
			_positionDirty = true;
			
			if (!hasEventListener(Object3DEvent.POSITION_CHANGED))
				return;
			
			if (!_positionChanged)
				_positionChanged = new Object3DEvent(Object3DEvent.POSITION_CHANGED, this);
			
			dispatchEvent(_positionChanged);
		}
		
		private function notifyRotationChange():void
		{
			if (_rotationDirty)
				return;
			
			invalidateTransform();
			
			_rotationDirty = true;
			
			if (!hasEventListener(Object3DEvent.ROTATION_CHANGED))
				return;
			
			if (!_rotationChanged)
				_rotationChanged = new Object3DEvent(Object3DEvent.ROTATION_CHANGED, this);
			
			dispatchEvent(_rotationChanged);
		}
		
		private function notifyScaleChange():void
		{
			if (_scaleDirty)
				return;
			
			invalidateTransform();
			
			_scaleDirty = true;
			
			if (!hasEventListener(Object3DEvent.SCALE_CHANGED))
				return;
			
			if (!_scaleChanged)
				_scaleChanged = new Object3DEvent(Object3DEvent.SCALE_CHANGED, this);
			
			dispatchEvent(_scaleChanged);
		}
		
		protected var _transform : Matrix3D = new Matrix3D();
		protected var _scaleX : Number = 1;
		protected var _scaleY : Number = 1;
		protected var _scaleZ : Number = 1;
		protected var _x : Number = 0;
		protected var _y : Number = 0;
		protected var _z : Number = 0;
		protected var _pivotPoint : Vector3D = new Vector3D();
		protected var _pivotZero : Boolean = true;
		protected var _pos:Vector3D = new Vector3D();
		protected var _rot:Vector3D = new Vector3D();
		protected var _sca:Vector3D = new Vector3D();
		protected var trans:Matrix3D = new Matrix3D();

		/**
		 * An object that can contain any extra data.
		 */
		public var extra : Object;
		
		/**
		 * Defines the x coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get x() : Number
		{
			return _x;
		}
		
		public function set x(val:Number) : void
		{
			if (_x == val)
				return;
			
			_x = val;
			
			notifyPositionChange();
		}
		
		/**
		 * Defines the y coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get y() : Number
		{
			return _y;
		}
		
		public function set y(val:Number) : void
		{
			if (_y == val)
				return;
			
			_y = val;
			
			notifyPositionChange();
		}
		
		/**
		 * Defines the z coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get z() : Number
		{
			return _z;
		}
		
		public function set z(val:Number) : void
		{
			if (_z == val)
				return;
			
			_z = val;
			
			notifyPositionChange();
		}
		
		/**
		 * Defines the euler angle of rotation of the 3d object around the x-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationX() : Number
		{
			return _rotationX * MathConsts.RADIANS_TO_DEGREES;
		}
		
		public function set rotationX(val:Number) : void
		{
			if (rotationX == val)
				return;
			
			_rotationX = val * MathConsts.DEGREES_TO_RADIANS;
			
			notifyRotationChange();
		}
		
		/**
		 * Defines the euler angle of rotation of the 3d object around the y-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationY():Number
		{
			return _rotationY * MathConsts.RADIANS_TO_DEGREES;
		}
		
		public function set rotationY(val:Number):void
		{
			if (rotationY == val)
				return;
			
			_rotationY = val * MathConsts.DEGREES_TO_RADIANS;
			
			notifyRotationChange();
		}
		
		/**
		 * Defines the euler angle of rotation of the 3d object around the z-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationZ():Number
		{
			return _rotationZ * MathConsts.RADIANS_TO_DEGREES;
		}
		
		public function set rotationZ(val:Number):void
		{
			if (rotationZ == val)
				return;
			
			_rotationZ = val * MathConsts.DEGREES_TO_RADIANS;
			
			notifyRotationChange();
		}
		
		/**
		 * Defines the scale of the 3d object along the x-axis, relative to local coordinates.
		 */
		public function get scaleX():Number
		{
			return _scaleX;
		}
		
		public function set scaleX(val:Number):void
		{
			if (_scaleX == val)
				return;
			
			_scaleX = val;
			
			notifyScaleChange();
		}
		
		/**
		 * Defines the scale of the 3d object along the y-axis, relative to local coordinates.
		 */
		public function get scaleY():Number
		{
			return _scaleY;
		}
		
		public function set scaleY(val:Number) : void
		{
			if (_scaleY == val)
				return;
			
			_scaleY = val;
			
			notifyScaleChange();
		}
		
		/**
		 * Defines the scale of the 3d object along the z-axis, relative to local coordinates.
		 */
		public function get scaleZ():Number
		{
			return _scaleZ;
		}
		
		public function set scaleZ(val:Number) : void
		{
			if (_scaleZ == val)
				return;
			
			_scaleZ = val;
			
			notifyScaleChange();
		}
		
		/**
		 * Defines the rotation of the 3d object as a <code>Vector3D</code> object containing euler angles for rotation around x, y and z axis.
		 */
		public function get eulers() : Vector3D
		{
			_eulers.x = _rotationX * MathConsts.RADIANS_TO_DEGREES;
			_eulers.y = _rotationY * MathConsts.RADIANS_TO_DEGREES;
			_eulers.z = _rotationZ * MathConsts.RADIANS_TO_DEGREES;
			
			return _eulers;
		}
		
		public function set eulers(value : Vector3D) : void
		{
			_rotationX = value.x * MathConsts.DEGREES_TO_RADIANS;
			_rotationY = value.y * MathConsts.DEGREES_TO_RADIANS;
			_rotationZ = value.z * MathConsts.DEGREES_TO_RADIANS;
			
			notifyRotationChange();
		}
		
		/**
		 * The transformation of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get transform() : Matrix3D
		{
			if (_transformDirty)
				updateTransform();
			
			_positionDirty = false;
			_rotationDirty = false;
			_scaleDirty = false;
			
			return _transform;
		}
		
		public function set transform(val:Matrix3D) : void
		{
			//ridiculous matrix error
			if (!val.rawData[uint(0)]) {
				var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
				val.copyRawDataTo(raw);
				raw[uint(0)] = _smallestNumber;
				val.copyRawDataFrom(raw);
			}
			
			var elements : Vector.<Vector3D> = val.decompose();
			var vec : Vector3D;
			
			vec = elements[0];
			
			if (_x != vec.x || _y != vec.y || _z != vec.z) {
				_x = vec.x;
				_y = vec.y;
				_z = vec.z;
				
				notifyPositionChange();
			}
			
			vec = elements[1];
			
			if (_rotationX != vec.x || _rotationY != vec.y || _rotationZ != vec.z) {
				_rotationX = vec.x;
				_rotationY = vec.y;
				_rotationZ = vec.z;
				
				notifyRotationChange();
			}
			
			vec = elements[2];
			
			if (_scaleX != vec.x || _scaleY != vec.y || _scaleZ != vec.z) {
				_scaleX = vec.x;
				_scaleY = vec.y;
				_scaleZ = vec.z;
				
				notifyScaleChange();
			}
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
			
			 notifyPositionChange();
		}

		/**
		 * Defines the position of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get position() : Vector3D
		{
			transform.copyColumnTo(3, _pos);
			
			return _pos.clone();
		}

		public function set position(value : Vector3D) : void
		{
			_x = value.x;
			_y = value.y;
			_z = value.z;
			
			notifyPositionChange();
		}
		
		/**
		 * 
		 */
		public function get forwardVector():Vector3D
		{
			return Matrix3DUtils.getForward(transform);
		}
		
		/**
		 * 
		 */
		public function get rightVector():Vector3D
		{
			return Matrix3DUtils.getRight(transform);
		}
		
		/**
		 * 
		 */
		public function get upVector():Vector3D
		{
			return Matrix3DUtils.getUp(transform);
		}
		
		/**
		 * 
		 */
		public function get backVector():Vector3D
		{
			var director:Vector3D = Matrix3DUtils.getForward(transform);
			director.negate();
			
			return director;
		}
		
		/**
		 * 
		 */
		public function get leftVector():Vector3D
		{
			var director:Vector3D = Matrix3DUtils.getRight(transform);
			director.negate();
			
			return director;
		}
		
		/**
		 * 
		 */
		public function get downVector():Vector3D
		{
			var director:Vector3D = Matrix3DUtils.getUp(transform);
			director.negate();
			
			return director;
		}
		
		/**
		 * Creates an Object3D object.
		 */
		public function Object3D()
		{
			_transform.identity();
			
			_flipY.appendScale(1, -1, 1);
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
			
			notifyScaleChange();
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
			
			notifyPositionChange();
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
			
			notifyPositionChange();
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
			
			notifyPositionChange();
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
			
			_transform.copyColumnTo(3, _pos);
			
			_x = _pos.x;
			_y = _pos.y;
			_z = _pos.z;
			
			notifyPositionChange();
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
			clone.name = name;
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
			
			notifyRotationChange();
		}

		/**
		 * Rotates the 3d object around an axis by a defined angle
		 *
		 * @param	axis		The vector defining the axis of rotation
		 * @param	angle		The amount of rotation in degrees
		 */
		public function rotate(axis : Vector3D, angle : Number) : void
		{
			transform.prependRotation(angle, axis);
			
			transform = transform;
		}

		/**
		 * Rotates the 3d object around to face a point defined relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 *
		 * @param	target		The vector defining the point to be looked at
		 * @param	upAxis		An optional vector used to define the desired up orientation of the 3d object after rotation has occurred
		 */
		public function lookAt(target : Vector3D, upAxis : Vector3D = null) : void
		{
			var yAxis : Vector3D, zAxis : Vector3D, xAxis : Vector3D;
			var raw : Vector.<Number>;
			
			upAxis ||= Vector3D.Y_AXIS;
			
			zAxis = target.subtract(position);
			zAxis.normalize();
			
			xAxis = upAxis.crossProduct(zAxis);
			xAxis.normalize();
			
			if (xAxis.length < .05) {
				xAxis = upAxis.crossProduct(Vector3D.Z_AXIS);
			}
			
			yAxis = zAxis.crossProduct(xAxis);
			
			raw = Matrix3DUtils.RAW_DATA_CONTAINER;
			
			raw[uint(0)] = _scaleX*xAxis.x;
			raw[uint(1)] = _scaleX*xAxis.y;
			raw[uint(2)] = _scaleX*xAxis.z;
			raw[uint(3)] = 0;
			
			raw[uint(4)] = _scaleY*yAxis.x;
			raw[uint(5)] = _scaleY*yAxis.y;
			raw[uint(6)] = _scaleY*yAxis.z;
			raw[uint(7)] = 0;
			
			raw[uint(8)] = _scaleZ*zAxis.x;
			raw[uint(9)] = _scaleZ*zAxis.y;
			raw[uint(10)] = _scaleZ*zAxis.z;
			raw[uint(11)] = 0;
			
			raw[uint(12)] = _x;
			raw[uint(13)] = _y;
			raw[uint(14)] = _z;
			raw[uint(15)] = 1;
			
			_transform.copyRawDataFrom(raw);
			
			transform = transform;
			
			if (zAxis.z < 0) {
				rotationY = (180 - rotationY);
				rotationX -= 180;
				rotationZ -= 180;
			}
		}
		
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose() : void
		{
		}

		/**
		 * Invalidates the transformation matrix, causing it to be updated upon the next request
		 */
		arcane function invalidateTransform() : void
		{
			_transformDirty = true;
		}

		protected function updateTransform() : void
		{
			if (_pivotZero) {
				_pos.x = _x;
				_pos.y = _y;
				_pos.z = _z;
			} else {
				_pos.x = -_pivotPoint.x;
				_pos.y = -_pivotPoint.y;
				_pos.z = -_pivotPoint.z;
			}
			_rot.x = _rotationX;
			_rot.y = _rotationY;
			_rot.z = _rotationZ;
			
			_sca.x = _scaleX;
			_sca.y = _scaleY;
			_sca.z = _scaleZ;
			
			_transform.recompose(Vector.<Vector3D>([_pos, _rot, _sca]));
			
			if (!_pivotZero)
				_transform.appendTranslation(_x + _pivotPoint.x, _y + _pivotPoint.y, _z + _pivotPoint.z);

			_transformDirty = false;
		}
	}
}
