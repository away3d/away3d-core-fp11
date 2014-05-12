package away3d.core.base
{
	import away3d.arcane;
	import away3d.bounds.AxisAlignedBoundingBox;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.pool.IRenderable;
	import away3d.entities.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.controllers.ControllerBase;
	import away3d.core.math.MathConsts;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.Partition3D;
	import away3d.core.pick.IPickingCollider;
	import away3d.core.pick.PickingCollisionVO;
	import away3d.errors.AbstractMethodError;
	import away3d.events.Object3DEvent;
	import away3d.events.Scene3DEvent;
	import away3d.library.assets.NamedAssetBase;
	import away3d.prefabs.PrefabBase;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;
	
	/**
	 * Dispatched when the position of the 3d object changes.
	 *
	 * @eventType away3d.events.Object3DEvent
	 */
	[Event(name="positionChanged", type="away3d.events.Object3DEvent")]
	
	/**
	 * Dispatched when the scale of the 3d object changes.
	 *
	 * @eventType away3d.events.Object3DEvent
	 */
	[Event(name="scaleChanged", type="away3d.events.Object3DEvent")]
	
	/**
	 * Dispatched when the rotation of the 3d object changes.
	 *
	 * @eventType away3d.events.Object3DEvent
	 */
	[Event(name="rotationChanged", type="away3d.events.Object3DEvent")]
	
	/**
	 * Object3D provides a base class for any 3D object that has a (local) transformation.<br/><br/>
	 *
	 * Standard Transform:
	 * <ul>
	 *     <li> The standard order for transformation is [parent transform] * (Translate+Pivot) * (Rotate) * (-Pivot) * (Scale) * [child transform] </li>
	 *     <li> This is the order of matrix multiplications, left-to-right. </li>
	 *     <li> The order of transformation is right-to-left, however!
	 *          (Scale) happens before (-Pivot) happens before (Rotate) happens before (Translate+Pivot)
	 *          with no pivot, the above transform works out to [parent transform] * Translate * Rotate * Scale * [child transform]
	 *          (Scale) happens before (Rotate) happens before (Translate) </li>
	 *     <li> This is based on code in updateTransform and ObjectContainer3D.updateSceneTransform(). </li>
	 *     <li> Matrix3D prepend = operator on rhs - e.g. transform' = transform * rhs; </li>
	 *     <li> Matrix3D append =  operator on lhr - e.g. transform' = lhs * transform; </li>
	 * </ul>
	 *
	 * To affect Scale:
	 * <ul>
	 *     <li> set scaleX/Y/Z directly, or call scale(delta) </li>
	 * </ul>
	 *
	 * To affect Pivot:
	 * <ul>
	 *     <li> set pivotPoint directly, or call movePivot() </li>
	 * </ul>
	 *
	 * To affect Rotate:
	 * <ul>
	 *    <li> set rotationX/Y/Z individually (using degrees), set eulers [all 3 angles] (using radians), or call rotateTo()</li>
	 *    <li> call pitch()/yaw()/roll()/rotate() to add an additional rotation *before* the current transform.
	 *         rotationX/Y/Z will be reset based on these operations. </li>
	 * </ul>
	 *
	 * To affect Translate (post-rotate translate):
	 *
	 * <ul>
	 *    <li> set x/y/z/position or call moveTo(). </li>
	 *    <li> call translate(), which modifies x/y/z based on a delta vector. </li>
	 *    <li> call moveForward()/moveBackward()/moveLeft()/moveRight()/moveUp()/moveDown()/translateLocal() to add an
	 *         additional translate *before* the current transform. x/y/z will be reset based on these operations. </li>
	 * </ul>
	 */
	
	public class Object3D extends NamedAssetBase
	{
		private var _smallestNumber:Number = 0.0000000000000000000001;
		private var _controller:ControllerBase;
		private var _boundsVisible:Boolean;
		private var _depth:Number;
		private var _height:Number;
		private var _width:Number;

		protected var _scene:Scene3D;
		protected var _parent:ObjectContainer3D;
		protected var _sceneTransform:Matrix3D = new Matrix3D();
		protected var _sceneTransformDirty:Boolean = true;
		protected var _isEntity:Boolean;

		private var _explicitPartition:Partition3D;
		protected var _implicitPartition:Partition3D;
		private var _partitionNode:EntityNode;

		private var _sceneTransformChanged:Object3DEvent;
		private var _sceneChanged:Object3DEvent;
		protected var _transform:Matrix3D = new Matrix3D();
		protected var _transformDirty:Boolean = true;

		private var _inverseSceneTransform:Matrix3D = new Matrix3D();
		private var _inverseSceneTransformDirty:Boolean = true;
		private var _scenePosition:Vector3D = new Vector3D();
		private var _scenePositionDirty:Boolean = true;
		private var _explicitVisibility:Boolean = true;
		protected var _implicitVisibility:Boolean = true;
		private var _explicitMouseEnabled:Boolean = true;
		protected var _implicitMouseEnabled:Boolean = true;
		private var _listenToSceneTransformChanged:Boolean;
		private var _listenToSceneChanged:Boolean;

		private var _positionDirty:Boolean;
		private var _rotationDirty:Boolean;
		private var _scaleDirty:Boolean;

		private var _positionChanged:Object3DEvent;
		private var _rotationChanged:Object3DEvent;
		private var _scaleChanged:Object3DEvent;

		private var _rotationX:Number = 0;
		private var _rotationY:Number = 0;
		private var _rotationZ:Number = 0;

		private var _eulers:Vector3D = new Vector3D();
		private var _flipY:Matrix3D = new Matrix3D();

		private var _listenToPositionChanged:Boolean;
		private var _listenToRotationChanged:Boolean;
		private var _listenToScaleChanged:Boolean;
		protected var _zOffset:Number = 0;

		protected var _scaleX:Number = 1;
		protected var _scaleY:Number = 1;
		protected var _scaleZ:Number = 1;
		protected var _x:Number = 0;
		protected var _y:Number = 0;
		protected var _z:Number = 0;
		protected var _pivot:Vector3D = new Vector3D();
		private var _orientationMatrix:Matrix3D = new Matrix3D();
		protected var _pivotZero:Boolean = true;
		protected var _pivotDirty:Boolean = true;

		protected var _pos:Vector3D = new Vector3D();
		protected var _rot:Vector3D = new Vector3D();
		protected var _sca:Vector3D = new Vector3D();
		protected var _transformComponents:Vector.<Vector3D>;

		protected var _ignoreTransform:Boolean = false;

		private var _shaderPickingDetails:Boolean;
		protected var _pickingCollisionVO:PickingCollisionVO;

		protected var _bounds:BoundingVolumeBase;
		protected var _boundsInvalid:Boolean = true;
		private var _worldBounds:BoundingVolumeBase;
		private var _worldBoundsInvalid:Boolean = true;

		protected var _pickingCollider:IPickingCollider;
		arcane var _staticNode:Boolean;

		protected var _renderables:Vector.<IRenderable> = new Vector.<IRenderable>();

		arcane var sourcePrefab:PrefabBase;

		public var alignmentMode:String = AlignmentMode.REGISTRATION_POINT;
		public var orientationMode:String = OrientationMode.DEFAULT;


		private var _castsShadows:Boolean = true;

		public function get castsShadows():Boolean {
			return _castsShadows;
		}

		public function set castsShadows(value:Boolean):void {
			_castsShadows = value;
		}

		public function get bounds():BoundingVolumeBase {
			if(_boundsInvalid) {
				updateBounds();
			}
			return _bounds;
		}

		public function set bounds(value:BoundingVolumeBase):void {
			if(bounds == value) return;

			_bounds = value;
			_worldBounds = value.clone();
			invalidateBounds();

			if(_boundsVisible) {
				_partitionNode.updateEntityBounds();
			}
		}

		/**
		 * Indicates the depth of the display object, in pixels. The depth is
		 * calculated based on the bounds of the content of the display object. When
		 * you set the <code>depth</code> property, the <code>scaleZ</code> property
		 * is adjusted accordingly, as shown in the following code:
		 *
		 * <p>Except for TextField and Video objects, a display object with no
		 * content (such as an empty sprite) has a depth of 0, even if you try to
		 * set <code>depth</code> to a different value.</p>
		 */
		public function get depth():Number
		{
			if (_boundsInvalid)
				updateBounds();

			return _depth;
		}

		public function set depth(val:Number):void
		{
			if (_depth == val)
				return;

			_depth == val;

			_scaleZ = val/bounds.aabb.depth;

			invalidateScale();
		}

		/**
		 * Defines the rotation of the 3d object as a <code>Vector3D</code> object containing euler angles for rotation around x, y and z axis.
		 */
		public function get eulers():Vector3D
		{
			_eulers.x = _rotationX*MathConsts.RADIANS_TO_DEGREES;
			_eulers.y = _rotationY*MathConsts.RADIANS_TO_DEGREES;
			_eulers.z = _rotationZ*MathConsts.RADIANS_TO_DEGREES;

			return _eulers;
		}

		public function set eulers(value:Vector3D):void
		{
			_rotationX = value.x*MathConsts.DEGREES_TO_RADIANS;
			_rotationY = value.y*MathConsts.DEGREES_TO_RADIANS;
			_rotationZ = value.z*MathConsts.DEGREES_TO_RADIANS;

			invalidateRotation();
		}

		/**
		 * Indicates the height of the display object, in pixels. The height is
		 * calculated based on the bounds of the content of the display object. When
		 * you set the <code>height</code> property, the <code>scaleY</code> property
		 * is adjusted accordingly, as shown in the following code:
		 *
		 * <p>Except for TextField and Video objects, a display object with no
		 * content (such as an empty sprite) has a height of 0, even if you try to
		 * set <code>height</code> to a different value.</p>
		 */
		public function get height():Number
		{
			if (_boundsInvalid)
				updateBounds();

			return _height;
		}

		public function set height(val:Number):void
		{
			if (_height == val)
				return;

			_height == val;

			_scaleY = val/bounds.aabb.height;

			invalidateScale();
		}

		/**
		 * Indicates the instance container index of the DisplayObject. The object can be
		 * identified in the child list of its parent display object container by
		 * calling the <code>getChildByIndex()</code> method of the display object
		 * container.
		 *
		 * <p>If the DisplayObject has no parent container, index defaults to 0.</p>
		 */
		public function get index():Number
		{
			if (_parent)
				return _parent.getChildIndex(this);

			return 0;
		}

		/**
		 * The inverse scene transform object that transforms from world to model space.
		 */
		public function get inverseSceneTransform():Matrix3D
		{
			if (_inverseSceneTransformDirty) {
				_inverseSceneTransform.copyFrom(sceneTransform);
				_inverseSceneTransform.invert();
				_inverseSceneTransformDirty = false;
			}

			return _inverseSceneTransform;
		}

		/**
		 * Does not apply any transformations to this object. Allows static objects to be described in world coordinates without any matrix calculations.
		 */
		public function get ignoreTransform():Boolean
		{
			return _ignoreTransform;
		}

		public function set ignoreTransform(value:Boolean):void
		{
			if(_ignoreTransform == value) return;

			_ignoreTransform = value;

			if (value) {
				_sceneTransform.identity();
				_scenePosition.setTo(0, 0, 0);
			}

			invalidateSceneTransform();
		}

		/**
		 * Specifies whether this object receives mouse, or other user input,
		 * messages. The default value is <code>true</code>, which means that by
		 * default any InteractiveObject instance that is on the display list
		 * receives mouse events or other user input events. If
		 * <code>mouseEnabled</code> is set to <code>false</code>, the instance does
		 * not receive any mouse events(or other user input events like keyboard
		 * events). Any children of this instance on the display list are not
		 * affected. To change the <code>mouseEnabled</code> behavior for all
		 * children of an object on the display list, use
		 * <code>away3d.containers.ObjectContainer3D.mouseChildren</code>.
		 *
		 * <p> No event is dispatched by setting this property. You must use the
		 * <code>addEventListener()</code> method to create interactive
		 * functionality.</p>
		 */
		public function get mouseEnabled():Boolean
		{
			return _explicitMouseEnabled;
		}

		public function set mouseEnabled(value:Boolean):void
		{
			if (_explicitMouseEnabled == value) return;

			_explicitMouseEnabled = value;

			updateImplicitMouseEnabled(_parent? _parent.mouseChildren : true);
		}

		public function get isEntity():Boolean {
			return _isEntity;
		}

		/**
		 * Indicates the ObjectContainer3D object that contains this display
		 * object. Use the <code>parent</code> property to specify a relative path to
		 * display objects that are above the current display object in the display
		 * list hierarchy.
		 *
		 * <p>You can use <code>parent</code> to move up multiple levels in the
		 * display list as in the following:</p>
		 */
		public function get parent():ObjectContainer3D
		{
			return _parent;
		}

		/**
		 * Defines whether or not the object will be moved or animated at runtime. This property is used by some partitioning systems to improve performance.
		 * Warning: if set to true, they may not be processed by certain partition systems using static visibility lists, unless they're specifically assigned to the visibility list.
		 */
		public function get staticNode():Boolean
		{
			return _staticNode;
		}

		public function set staticNode(value:Boolean):void
		{
			_staticNode = value;
		}

		public function get partition():Partition3D {
			return _explicitPartition;
		}

		public function set partition(value:Partition3D):void
		{
			if (_explicitPartition == value) return;

			if (_scene && _explicitPartition)
				_scene.unregisterPartition(_explicitPartition);

			_explicitPartition = value;

			if (_scene && value)
				_scene.registerPartition(value);

			updateImplicitPartition(_parent? _parent.assignedPartition : null);
		}

		public function get partitionNode():EntityNode {
			if(!_partitionNode) _partitionNode = createEntityPartitionNode();
			return _partitionNode;
		}

		public function get pickingCollider():IPickingCollider
		{
			return _pickingCollider;
		}

		public function set pickingCollider(value:IPickingCollider):void
		{
			_pickingCollider = value;
		}

		/**
		 * Defines the local point around which the object rotates.
		 */
		public function get pivot():Vector3D
		{
			return _pivot;
		}

		public function set pivot(pivot:Vector3D):void
		{
			if(!_pivot) _pivot = new Vector3D();
			_pivot.x = pivot.x;
			_pivot.y = pivot.y;
			_pivot.z = pivot.z;

			invalidatePivot();
		}

		/**
		 * Defines the euler angle of rotation of the 3d object around the x-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationX():Number
		{
			return _rotationX*MathConsts.RADIANS_TO_DEGREES;
		}

		public function set rotationX(val:Number):void
		{
			if (rotationX == val)
				return;

			_rotationX = val*MathConsts.DEGREES_TO_RADIANS;

			invalidateRotation();
		}

		/**
		 * Defines the euler angle of rotation of the 3d object around the y-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationY():Number
		{
			return _rotationY*MathConsts.RADIANS_TO_DEGREES;
		}

		public function set rotationY(val:Number):void
		{
			if (rotationY == val)
				return;

			_rotationY = val*MathConsts.DEGREES_TO_RADIANS;

			invalidateRotation();
		}

		/**
		 * Defines the euler angle of rotation of the 3d object around the z-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get rotationZ():Number
		{
			return _rotationZ*MathConsts.RADIANS_TO_DEGREES;
		}

		public function set rotationZ(val:Number):void
		{
			if (rotationZ == val)
				return;

			_rotationZ = val*MathConsts.DEGREES_TO_RADIANS;

			invalidateRotation();
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

			invalidateScale();
		}

		/**
		 * Defines the scale of the 3d object along the y-axis, relative to local coordinates.
		 */
		public function get scaleY():Number
		{
			return _scaleY;
		}

		public function set scaleY(val:Number):void
		{
			if (_scaleY == val)
				return;

			_scaleY = val;

			invalidateScale();
		}

		/**
		 * Defines the scale of the 3d object along the z-axis, relative to local coordinates.
		 */
		public function get scaleZ():Number
		{
			return _scaleZ;
		}

		public function set scaleZ(val:Number):void
		{
			if (_scaleZ == val)
				return;

			_scaleZ = val;

			invalidateScale();
		}

		public function get scene():Scene3D{
			return _scene;
		}

		/**
		 * The global position of the ObjectContainer3D in the scene. The value of the return object should not be changed.
		 */
		public function get scenePosition():Vector3D
		{
			if (_scenePositionDirty) {
				if(!_pivotZero && alignmentMode == AlignmentMode.PIVOT_POINT) {
					var pivotScale:Vector3D = new Vector3D();
					pivotScale.x = _pivot.x/_scaleX;
					pivotScale.y = _pivot.y/_scaleY;
					pivotScale.z = _pivot.z/_scaleZ;
					Matrix3DUtils.transformVector(sceneTransform, pivotScale, _scenePosition);
				}else{
					sceneTransform.copyColumnTo(3, _scenePosition);
				}

				_scenePositionDirty = false;
			}

			return _scenePosition;
		}

		/**
		 * The transformation matrix that transforms from model to world space.
		 */
		public function get sceneTransform():Matrix3D
		{
			if (_sceneTransformDirty)
				updateSceneTransform();

			return _sceneTransform;
		}

		public function get shaderPickingDetails():Boolean
		{
			return this._shaderPickingDetails;
		}

		public function get boundsVisible():Boolean
		{
			return _boundsVisible;
		}

		public function set boundsVisible(value:Boolean):void
		{
			if (value == _boundsVisible) return;

			_boundsVisible = value;

			_partitionNode.boundsVisible = value;
		}

		/**
		 * The transformation of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get transform():Matrix3D
		{
			if(_transformDirty) {
				updateTransform();
			}
			return _transform;
		}

		public function set transform(val:Matrix3D):void
		{
			//ridiculous matrix error
			var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			val.copyRawDataTo(raw);
			if (!raw[uint(0)]) {
				raw[uint(0)] = _smallestNumber;
				val.copyRawDataFrom(raw);
			}

			var elements:Vector.<Vector3D> = Matrix3DUtils.decompose(val);
			var vec:Vector3D;

			vec = elements[0];

			if (_x != vec.x || _y != vec.y || _z != vec.z) {
				_x = vec.x;
				_y = vec.y;
				_z = vec.z;

				invalidatePosition();
			}

			vec = elements[1];

			if (_rotationX != vec.x || _rotationY != vec.y || _rotationZ != vec.z) {
				_rotationX = vec.x;
				_rotationY = vec.y;
				_rotationZ = vec.z;

				invalidateRotation();
			}

			vec = elements[2];

			if (_scaleX != vec.x || _scaleY != vec.y || _scaleZ != vec.z) {
				_scaleX = vec.x;
				_scaleY = vec.y;
				_scaleZ = vec.z;

				invalidateScale();
			}
		}
		/**
		 * Whether or not the display object is visible. Display objects that are not
		 * visible are disabled. For example, if <code>visible=false</code> for an
		 * InteractiveObject instance, it cannot be clicked.
		 */
		public function get visible():Boolean
		{
			return _explicitVisibility;
		}

		public function set visible(value:Boolean):void
		{
			if (_explicitVisibility == value) return;

			_explicitVisibility = value;

			updateImplicitVisibility(_parent? _parent.isVisible : true);
		}

		/**
		 * Indicates the width of the display object, in pixels. The width is
		 * calculated based on the bounds of the content of the display object. When
		 * you set the <code>width</code> property, the <code>scaleX</code> property
		 * is adjusted accordingly, as shown in the following code:
		 *
		 * <p>Except for TextField and Video objects, a display object with no
		 * content(such as an empty sprite) has a width of 0, even if you try to set
		 * <code>width</code> to a different value.</p>
		 */
		public function get width():Number
		{
			if (_boundsInvalid) updateBounds();

			return _width;
		}

		public function set width(val:Number):void
		{
			if (_width == val) return;

			_width == val;
			_scaleX = val/this.bounds.aabb.width;
			invalidateScale();
		}

		/**
		 *
		 */
		public function get worldBounds():BoundingVolumeBase
		{
			// Since this getter is invoked every iteration of the render loop, and
			// the prefab construct could affect the bounds of the entity, the prefab is
			// validated here to give it a chance to rebuild.
			if (sourcePrefab)
				sourcePrefab.validate();

			if (_worldBoundsInvalid) {
				_worldBoundsInvalid = false;
				_worldBounds.transformFrom(bounds, sceneTransform);
			}

			return _worldBounds;
		}

		/**
		 * Defines the x coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get x():Number
		{
			return _x;
		}

		public function set x(val:Number):void
		{
			if (_x == val)
				return;

			_x = val;

			invalidatePosition();
		}

		/**
		 * Defines the y coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get y():Number
		{
			return _y;
		}

		public function set y(val:Number):void
		{
			if (_y == val)
				return;

			_y = val;

			invalidatePosition();
		}

		/**
		 * Defines the z coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get z():Number
		{
			return _z;
		}

		public function set z(val:Number):void
		{
			if (_z == val)
				return;

			_z = val;

			invalidatePosition();
		}

		public function get zOffset():Number
		{
			return _zOffset;
		}

		public function set zOffset(value:Number):void
		{
			_zOffset = value;
		}

		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			switch (type) {
				case Object3DEvent.POSITION_CHANGED:
					_listenToPositionChanged = true;
					break;
				case Object3DEvent.ROTATION_CHANGED:
					_listenToRotationChanged = true;
					break;
				case Object3DEvent.SCALE_CHANGED:
					_listenToRotationChanged = true;
					break;
			}
		}

		public function clone():Object3D
		{
			var clone:Object3D = new Object3D();
			clone.pivot = pivot;
			clone.transform = transform;
			clone.name = name;
			// todo: implement for all subtypes
			return clone;
		}

		/**
		 * Cleans up any resources used by the current object.
		 */
		override public function dispose():void
		{
			if(parent) {
				parent.removeChild(this);
			}

			while (_renderables.length)
				_renderables[0].dispose();
		}

		/**
		 * @inheritDoc
		 */
		public function disposeAsset():void
		{
			dispose();
		}

		/**
		 * @inheritDoc
		 */
		public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Boolean
		{
			var localRayPosition:Vector3D = inverseSceneTransform.transformVector(rayPosition);
			var localRayDirection:Vector3D = inverseSceneTransform.deltaTransformVector(rayDirection);
			var pickingCollisionVO:PickingCollisionVO = pickingCollisionVO;

			if (!pickingCollisionVO.localNormal)
				pickingCollisionVO.localNormal = new Vector3D();

			var rayEntryDistance:Number = bounds.rayIntersection(localRayPosition, localRayDirection, pickingCollisionVO.localNormal);

			if (rayEntryDistance < 0)
				return false;

			pickingCollisionVO.rayEntryDistance = rayEntryDistance;
			pickingCollisionVO.localRayPosition = localRayPosition;
			pickingCollisionVO.localRayDirection = localRayDirection;
			pickingCollisionVO.rayPosition = rayPosition;
			pickingCollisionVO.rayDirection = rayDirection;
			pickingCollisionVO.rayOriginIsInsideBounds = rayEntryDistance == 0;

			return true;
		}

		private static var tempAxeX:Vector3D;
		private static var tempAxeY:Vector3D;
		private static var tempAxeZ:Vector3D;
		/**
		 * Rotates the 3d object around to face a point defined relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 *
		 * @param    target        The vector defining the point to be looked at
		 * @param    upAxis        An optional vector used to define the desired up orientation of the 3d object after rotation has occurred
		 */
		public function lookAt(target:Vector3D, upAxis:Vector3D = null):void
		{
			if(!tempAxeX) tempAxeX = new Vector3D();
			if(!tempAxeY) tempAxeY = new Vector3D();
			if(!tempAxeZ) tempAxeZ = new Vector3D();
			var xAxis:Vector3D = tempAxeX;
			var yAxis:Vector3D = tempAxeY;
			var zAxis:Vector3D = tempAxeZ;

			var raw:Vector.<Number>;

			upAxis ||= Vector3D.Y_AXIS;

			if (_transformDirty) {
				updateTransform();
			}

			zAxis.x = target.x - _x;
			zAxis.y = target.y - _y;
			zAxis.z = target.z - _z;
			zAxis.normalize();

			xAxis.x = upAxis.y*zAxis.z - upAxis.z*zAxis.y;
			xAxis.y = upAxis.z*zAxis.x - upAxis.x*zAxis.z;
			xAxis.z = upAxis.x*zAxis.y - upAxis.y*zAxis.x;
			xAxis.normalize();

			if (xAxis.length < .05) {
				xAxis.x = upAxis.y;
				xAxis.y = upAxis.x;
				xAxis.z = 0;
				xAxis.normalize();
			}

			yAxis.x = zAxis.y*xAxis.z - zAxis.z*xAxis.y;
			yAxis.y = zAxis.z*xAxis.x - zAxis.x*xAxis.z;
			yAxis.z = zAxis.x*xAxis.y - zAxis.y*xAxis.x;

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


		private function invalidatePivot():void
		{
			_pivotZero = (_pivot.x == 0) && (_pivot.y == 0) && (_pivot.z == 0);

			if(_pivotDirty) return;

			_pivotDirty = true;

			invalidateTransform();
		}
		
		private function invalidatePosition():void
		{
			if (_positionDirty)
				return;
			
			_positionDirty = true;
			
			invalidateTransform();
			
			if (_listenToPositionChanged)
				notifyPositionChanged();
		}
		
		private function notifyPositionChanged():void
		{
			if (!_positionChanged)
				_positionChanged = new Object3DEvent(Object3DEvent.POSITION_CHANGED, this);
			
			dispatchEvent(_positionChanged);
		}

		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			super.removeEventListener(type, listener, useCapture);
			
			if (hasEventListener(type))
				return;
			
			switch (type) {
				case Object3DEvent.POSITION_CHANGED:
					_listenToPositionChanged = false;
					break;
				case Object3DEvent.ROTATION_CHANGED:
					_listenToRotationChanged = false;
					break;
				case Object3DEvent.SCALE_CHANGED:
					_listenToScaleChanged = false;
					break;
			}
		}
		
		private function invalidateRotation():void
		{
			if (_rotationDirty)
				return;
			
			_rotationDirty = true;
			
			invalidateTransform();
			
			if (_listenToRotationChanged)
				notifyRotationChanged();
		}
		
		private function notifyRotationChanged():void
		{
			if (!_rotationChanged)
				_rotationChanged = new Object3DEvent(Object3DEvent.ROTATION_CHANGED, this);
			
			dispatchEvent(_rotationChanged);
		}
		
		private function invalidateScale():void
		{
			if (_scaleDirty)
				return;
			
			_scaleDirty = true;
			
			invalidateTransform();
			
			if (_listenToScaleChanged)
				notifyScaleChanged();
		}
		
		private function notifyScaleChanged():void
		{
			if (!_scaleChanged)
				_scaleChanged = new Object3DEvent(Object3DEvent.SCALE_CHANGED, this);
			
			dispatchEvent(_scaleChanged);
		}

		/**
		 * @private
		 */
		private function notifySceneChange():void
		{
			if (_listenToSceneChanged) {
				if (!_sceneChanged)
					_sceneChanged = new Object3DEvent(Object3DEvent.SCENE_CHANGED, this);

				dispatchEvent(_sceneChanged);
			}
		}

		/**
		 * @private
		 */
		private function notifySceneTransformChange():void
		{
			if (!_sceneTransformChanged)
				_sceneTransformChanged = new Object3DEvent(Object3DEvent.SCENETRANSFORM_CHANGED, this);

			dispatchEvent(_sceneTransformChanged);
		}

		
		/**
		 * An object that can contain any extra data.
		 */
		public var extra:Object;

		/**
		 * Defines the position of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 */
		public function get position():Vector3D
		{
			transform.copyColumnTo(3, _pos);
			
			return _pos.clone();
		}
		
		public function set position(value:Vector3D):void
		{
			_x = value.x;
			_y = value.y;
			_z = value.z;
			
			invalidatePosition();
		}

		/**
		 * Defines the position of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
		 * @param v the destination Vector3D
		 * @return
		 */
		public function getPosition(v:Vector3D = null):Vector3D {
			if(!v) v = new Vector3D();
			transform.copyColumnTo(3, v);
			return v;
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
			// Cached vector of transformation components used when
			// recomposing the transform matrix in updateTransform()
			_transformComponents = new Vector.<Vector3D>(3, true);
			_transformComponents[0] = _pos;
			_transformComponents[1] = _rot;
			_transformComponents[2] = _sca;
			
			_transform.identity();
			
			_flipY.appendScale(1, -1, 1);

			_bounds = createDefaultBoundingVolume();
			_worldBounds = createDefaultBoundingVolume();
		}
		
		/**
		 * Appends a uniform scale to the current transformation.
		 * @param value The amount by which to scale.
		 */
		public function scale(value:Number):void
		{
			_scaleX *= value;
			_scaleY *= value;
			_scaleZ *= value;
			
			invalidateScale();
		}
		
		/**
		 * Moves the 3d object forwards along it's local z axis
		 *
		 * @param    distance    The length of the movement
		 */
		public function moveForward(distance:Number):void
		{
			translateLocal(Vector3D.Z_AXIS, distance);
		}
		
		/**
		 * Moves the 3d object backwards along it's local z axis
		 *
		 * @param    distance    The length of the movement
		 */
		public function moveBackward(distance:Number):void
		{
			translateLocal(Vector3D.Z_AXIS, -distance);
		}
		
		/**
		 * Moves the 3d object backwards along it's local x axis
		 *
		 * @param    distance    The length of the movement
		 */
		public function moveLeft(distance:Number):void
		{
			translateLocal(Vector3D.X_AXIS, -distance);
		}
		
		/**
		 * Moves the 3d object forwards along it's local x axis
		 *
		 * @param    distance    The length of the movement
		 */
		public function moveRight(distance:Number):void
		{
			translateLocal(Vector3D.X_AXIS, distance);
		}
		
		/**
		 * Moves the 3d object forwards along it's local y axis
		 *
		 * @param    distance    The length of the movement
		 */
		public function moveUp(distance:Number):void
		{
			translateLocal(Vector3D.Y_AXIS, distance);
		}
		
		/**
		 * Moves the 3d object backwards along it's local y axis
		 *
		 * @param    distance    The length of the movement
		 */
		public function moveDown(distance:Number):void
		{
			translateLocal(Vector3D.Y_AXIS, -distance);
		}
		
		/**
		 * Moves the 3d object directly to a point in space
		 *
		 * @param    dx        The amount of movement along the local x axis.
		 * @param    dy        The amount of movement along the local y axis.
		 * @param    dz        The amount of movement along the local z axis.
		 */
		public function moveTo(dx:Number, dy:Number, dz:Number):void
		{
			if (_x == dx && _y == dy && _z == dz)
				return;
			_x = dx;
			_y = dy;
			_z = dz;
			
			invalidatePosition();
		}
		
		/**
		 * Moves the local point around which the object rotates.
		 *
		 * @param    dx        The amount of movement along the local x axis.
		 * @param    dy        The amount of movement along the local y axis.
		 * @param    dz        The amount of movement along the local z axis.
		 */
		public function movePivot(dx:Number, dy:Number, dz:Number):void
		{
			if(!_pivot) _pivot = new Vector3D();
			_pivot.x += dx;
			_pivot.y += dy;
			_pivot.z += dz;
			
			invalidatePivot();
		}
		
		/**
		 * Moves the 3d object along a vector by a defined length
		 *
		 * @param    axis        The vector defining the axis of movement
		 * @param    distance    The length of the movement
		 */
		public function translate(axis:Vector3D, distance:Number):void
		{
			var x:Number = axis.x, y:Number = axis.y, z:Number = axis.z;
			var len:Number = distance/Math.sqrt(x*x + y*y + z*z);
			
			_x += x*len;
			_y += y*len;
			_z += z*len;
			
			invalidatePosition();
		}
		
		/**
		 * Moves the 3d object along a vector by a defined length
		 *
		 * @param    axis        The vector defining the axis of movement
		 * @param    distance    The length of the movement
		 */
		public function translateLocal(axis:Vector3D, distance:Number):void
		{
			var x:Number = axis.x, y:Number = axis.y, z:Number = axis.z;
			var len:Number = distance/Math.sqrt(x*x + y*y + z*z);
			
			transform.prependTranslation(x*len, y*len, z*len);
			
			_transform.copyColumnTo(3, _pos);
			
			_x = _pos.x;
			_y = _pos.y;
			_z = _pos.z;
			
			invalidatePosition();
		}
		
		/**
		 * Rotates the 3d object around it's local x-axis
		 *
		 * @param    angle        The amount of rotation in degrees
		 */
		public function pitch(angle:Number):void
		{
			rotate(Vector3D.X_AXIS, angle);
		}
		
		/**
		 * Rotates the 3d object around it's local y-axis
		 *
		 * @param    angle        The amount of rotation in degrees
		 */
		public function yaw(angle:Number):void
		{
			rotate(Vector3D.Y_AXIS, angle);
		}

		public function get assignedPartition():Partition3D{
			return _implicitPartition;
		}
		
		/**
		 * Rotates the 3d object around it's local z-axis
		 *
		 * @param    angle        The amount of rotation in degrees
		 */
		public function roll(angle:Number):void
		{
			rotate(Vector3D.Z_AXIS, angle);
		}

		
		/**
		 * Rotates the 3d object directly to a euler angle
		 *
		 * @param    ax        The angle in degrees of the rotation around the x axis.
		 * @param    ay        The angle in degrees of the rotation around the y axis.
		 * @param    az        The angle in degrees of the rotation around the z axis.
		 */
		public function rotateTo(ax:Number, ay:Number, az:Number):void
		{
			_rotationX = ax*MathConsts.DEGREES_TO_RADIANS;
			_rotationY = ay*MathConsts.DEGREES_TO_RADIANS;
			_rotationZ = az*MathConsts.DEGREES_TO_RADIANS;
			
			invalidateRotation();
		}
		
		/**
		 * Rotates the 3d object around an axis by a defined angle
		 *
		 * @param    axis        The vector defining the axis of rotation
		 * @param    angle        The amount of rotation in degrees
		 */
		public function rotate(axis:Vector3D, angle:Number):void
		{
			var m:Matrix3D = new Matrix3D();
			m.prependRotation(angle, axis);
			
			var vec:Vector3D = m.decompose()[1];
			
			_rotationX += vec.x;
			_rotationY += vec.y;
			_rotationZ += vec.z;
			
			invalidateRotation();
		}

		/**
		 *
		 */
		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			if (orientationMode == OrientationMode.CAMERA_PLANE) {
				var comps:Vector.<Vector3D> = camera.sceneTransform.decompose();
				var scale:Vector3D = comps[2];
				comps[0] = scenePosition;
				scale.x = _scaleX;
				scale.y = _scaleY;
				scale.z = _scaleZ;
				_orientationMatrix.recompose(comps);

				//add in case of pivot
				if (!_pivotZero && alignmentMode == AlignmentMode.PIVOT_POINT)
					_orientationMatrix.prependTranslation(-_pivot.x/_scaleX, -_pivot.y/this._scaleY, -_pivot.z/_scaleZ);

				return _orientationMatrix;
			}

			return sceneTransform;
		}

		public function get pickingCollisionVO():PickingCollisionVO {
			if(!_pickingCollisionVO) _pickingCollisionVO = new PickingCollisionVO(this);
			return _pickingCollisionVO;
		}

		arcane function setParent(value:ObjectContainer3D) :void {
			_parent = value;
			if (value) {
				updateImplicitMouseEnabled(value.mouseChildren);
				updateImplicitVisibility(value.isVisible());
				updateImplicitPartition(value.assignedPartition);
				setScene(value.scene);
			} else {
				updateImplicitMouseEnabled(true);
				updateImplicitVisibility(true);
				updateImplicitPartition(null);
				setScene(null);
			}
		}

		protected function createDefaultBoundingVolume():BoundingVolumeBase
		{
			// point lights should be using sphere bounds
			// directional lights should be using null bounds
			return new AxisAlignedBoundingBox();
		}

		protected function createEntityPartitionNode():EntityNode
		{
			throw new AbstractMethodError();
		}
		/**
		 * @protected
		 */
		protected function invalidateBounds():void
		{
			_boundsInvalid = true;
			_worldBoundsInvalid = true;
			if (isEntity) invalidatePartition();
		}

		/**
		 * @protected
		 */
		public function invalidateSceneTransform():void
		{
			_sceneTransformDirty = !_ignoreTransform;
			_inverseSceneTransformDirty = !_ignoreTransform;
			_scenePositionDirty = !_ignoreTransform;

			_worldBoundsInvalid = !_ignoreTransform;

			if (isEntity)
				invalidatePartition();

			if (_listenToSceneTransformChanged)
				notifySceneTransformChange();
		}


		/**
		 * @protected
		 */
		protected function updateBounds():void
		{
			_width = _bounds.aabb.width*_scaleX;
			_height = _bounds.aabb.height*_scaleY;
			_depth = _bounds.aabb.depth*_scaleZ;
			_boundsInvalid = false;
		}

		/**
		 * @protected
		 */
		protected function updateImplicitMouseEnabled(value:Boolean):void
		{
			_implicitMouseEnabled = _explicitMouseEnabled && value;

			// If there is a parent and this child does not have a picking collider, use its parent's picking collider.
			if (_implicitMouseEnabled && _parent && !_pickingCollider)
				_pickingCollider =  _parent.pickingCollider;
		}

		/**
		 * @protected
		 */
		protected function updateImplicitPartition(value:Partition3D):void
		{
			// assign parent implicit partition if no explicit one is given
			_implicitPartition = this._explicitPartition || value;
		}

		/**
		 * @protected
		 */
		protected function updateImplicitVisibility(value:Boolean):void
		{
			_implicitVisibility = _explicitVisibility && value;
		}
		
		/**
		 * Invalidates the transformation matrix, causing it to be updated upon the next request
		 */
		arcane function invalidateTransform():void
		{
			if(_transformDirty) return;

			_transformDirty = true;

			if(!_sceneTransformDirty && !_ignoreTransform) {
				invalidateSceneTransform();
			}
		}

		/**
		 * @private
		 */
		private function invalidatePartition():void
		{
			if (assignedPartition)
				assignedPartition.markForUpdate(this);
		}
		
		protected function updateTransform():void
		{
			_pos.x = _x;
			_pos.y = _y;
			_pos.z = _z;
			
			_rot.x = _rotationX;
			_rot.y = _rotationY;
			_rot.z = _rotationZ;

			if (!_pivotZero) {
				_sca.x = 1;
				_sca.y = 1;
				_sca.z = 1;

				_transform.recompose(_transformComponents);
				_transform.appendTranslation(_pivot.x, _pivot.y, _pivot.z);
				_transform.prependTranslation(-_pivot.x, -_pivot.y, -_pivot.z);
				_transform.prependScale(_scaleX, _scaleY, _scaleZ);

				_sca.x = _scaleX;
				_sca.y = _scaleY;
				_sca.z = _scaleZ;
			}else{
				_sca.x = _scaleX;
				_sca.y = _scaleY;
				_sca.z = _scaleZ;

				_transform.recompose(_transformComponents);
			}
			
			_transformDirty = false;
			_positionDirty = false;
			_rotationDirty = false;
			_scaleDirty = false;
			_pivotDirty = false;
		}

		/**
		 * @protected
		 */
		protected function updateSceneTransform():void
		{
			if (_parent && !_parent.isRoot) {
				_sceneTransform.copyFrom(_parent.sceneTransform);
				_sceneTransform.prepend(transform);
			} else {
				_sceneTransform.copyFrom(transform);
			}

			_sceneTransformDirty = false;
		}

		public function addRenderable(renderable:IRenderable):IRenderable
		{
			_renderables.push(renderable);
			return renderable;
		}


		public function removeRenderable(renderable:IRenderable):IRenderable
		{
			var index:Number = _renderables.indexOf(renderable);
			_renderables.splice(index, 1);
			return renderable;
		}

		public function testCollision(shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			return false;
		}

		public function internalUpdate():void
		{
			if (_controller) _controller.update();
		}

		public function isVisible():Boolean {
			return _implicitVisibility;
		}

		public function get isMouseEnabled():Boolean{
			return _implicitMouseEnabled;
		}

		arcane function setScene(value:Scene3D):void {
			if(_scene == value) return;
			updateScene(value);
			if(!_sceneTransformDirty && !_ignoreTransform) {
				invalidateSceneTransform();
			}
		}

		/**
		 * @protected
		 */
		protected function updateScene(value:Scene3D):void
		{
			if (_scene) {
				_scene.dispatchEvent(new Scene3DEvent(Scene3DEvent.REMOVED_FROM_SCENE, this));

				//unregister entity from current scene
				_scene.unregisterEntity(this);
			}

			_scene = value;

			if (value) {
				value.dispatchEvent(new Scene3DEvent(Scene3DEvent.ADDED_TO_SCENE, this));

				//register entity with new scene
				value.registerEntity(this);
			}

			notifySceneChange();
		}

		public function get controller():ControllerBase {
			return _controller;
		}

		public function set controller(value:ControllerBase):void {
			_controller = value;
		}
	}
}
