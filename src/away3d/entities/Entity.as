package away3d.entities
{
	import away3d.arcane;
	import away3d.bounds.AxisAlignedBoundingBox;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.Partition3D;
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.AssetType;

	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * The Entity class provides an abstract base class for all scene graph objects that are considered having a
	 * "presence" in the scene, in the sense that it can be considered an actual object with a position and a size (even
	 * if infinite or idealised), rather than a grouping.
	 * Entities can be partitioned in a space partitioning system and in turn collected by an EntityCollector.
	 *
	 * @see away3d.partition.Partition3D
	 * @see away3d.core.traverse.EntityCollector
	 */
	public class Entity extends ObjectContainer3D
	{
		arcane function internalUpdate():void
		{
			if (_controller)
				_controller.update();
		}
		
		private var _showBounds : Boolean;
		private var _partitionNode : EntityNode;
		private var _mouseEnabled : Boolean;

		protected var _mvpTransformStack : Vector.<Matrix3D> = new Vector.<Matrix3D>();
		protected var _zIndices : Vector.<Number> = new Vector.<Number>();
		protected var _mvpIndex : int = -1;
		protected var _stackLen : uint;
		protected var _bounds : BoundingVolumeBase;
		protected var _boundsInvalid : Boolean = true;

		/**
		 * 
		 */
		public function get showBounds() : Boolean
		{
			return _showBounds;
		}

		public function set showBounds(value : Boolean) : void
		{
			if (value == _showBounds)
				return;
			
			_showBounds = value;
			
			if (value) {
				addChild(_bounds.boundingRenderable);
			} else {
				removeChild(_bounds.boundingRenderable);
				_bounds.disposeRenderable();
			}
		}
		
		/**
		 * Indicates whether the IRenderable should trigger mouse events, and hence should be rendered for hit testing.
		 */
		public function get mouseEnabled() : Boolean
		{
			return _mouseEnabled;
		}
		
		public function set mouseEnabled(value : Boolean) : void
		{
			_mouseEnabled = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get minX() : Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.x;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get minY() : Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.y;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get minZ() : Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.z;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get maxX() : Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.x;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get maxY() : Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.y;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get maxZ() : Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.z;
		}
		
		/**
		 * The bounding volume approximating the volume occupied by the Entity.
		 */
		public function get bounds() : BoundingVolumeBase
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds;
		}
		
		public function set bounds(value : BoundingVolumeBase) : void
		{
			_bounds = value;
			_boundsInvalid = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function set implicitPartition(value : Partition3D) : void
		{
			if (value == _implicitPartition)
				return;
			
			if (_implicitPartition)
				notifyPartitionUnassigned();
			
			super.implicitPartition = value;
			
			notifyPartitionAssigned();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set scene(value : Scene3D) : void
		{
			if (value == _scene)
				return;

			if (_scene)
				_scene.unregisterEntity(this);
			
			// callback to notify object has been spawned. Casts to please FDT
			if (value)
				value.registerEntity(this);

			super.scene = value;
		}
		
		/**
		 * The current model-view-projection (MVP) matrix - the one on the top of the stack - used to transform from
		 * model to homogeneous projection space.
		 */
		public function get modelViewProjection() : Matrix3D
		{
			// assume base if popped (only happens when all rendering is complete, and no matrices are on the stack)
			return _mvpTransformStack[uint(uint(_mvpIndex > 0)*_mvpIndex)];
		}
		
		/**
		 * The distance of the IRenderable object to the view, used to sort per object. Should never be called manually.
		 *
		 * @private
		 */
		public function get zIndex() : Number
		{
			return _zIndices[_mvpIndex];
		}
		
		/**
		 * Creates a new Entity object.
		 */
		public function Entity()
		{
			super();
			
			_bounds = getDefaultBoundingVolume();
		}
		
		/**
		 * Updates the model-view-projection (MVP) matrix used to transform from model to homogeneous projection space
		 * and places it on the stack. The stack allows nested rendering while keeping the MVP intact.
		 * @param camera The camera which will perform the view transformation and projection.
		 */
		public function pushModelViewProjection(camera : Camera3D) : void
		{
			if (++_mvpIndex == _stackLen) {
				_mvpTransformStack[_mvpIndex] = new Matrix3D();
				_stackLen++;
			}

			var mvp : Matrix3D = _mvpTransformStack[_mvpIndex];
			mvp.copyFrom(sceneTransform);
			mvp.append(camera.viewProjection);
			mvp.copyColumnTo(3, _pos);
			_zIndices[_mvpIndex] = -_pos.z;
		}
		
		/**
		 * Same as before, but not guarding against bounds. Only to be used inside the render loop
		 * @private
		 */
		public function getModelViewProjectionUnsafe() : Matrix3D
		{
			return _mvpTransformStack[_mvpIndex];
		}
		
		/**
		 * Removes a model view projection matrix from the stack, used when leaving a render.
		 */
		public function popModelViewProjection() : void
		{
			--_mvpIndex;
		}

		/**
		 * Gets a concrete EntityPartition3DNode subclass that is associated with this Entity instance
		 */
		public function getEntityPartitionNode() : EntityNode
		{
			return _partitionNode ||= createEntityPartitionNode();
		}

		/**
		 * Factory method that returns the current partition node. Needs to be overridden by concrete subclasses
		 * such as Mesh to return the correct concrete subtype of EntityPartition3DNode (for Mesh = MeshPartition3DNode,
		 * most IRenderables (particles fe) would return RenderablePartition3DNode, I suppose)
		 */
		protected function createEntityPartitionNode() : EntityNode
		{
			throw new AbstractMethodError();
		}

		/**
		 * Creates the default bounding box to be used by this type of Entity.
		 * @return
		 */
		protected function getDefaultBoundingVolume() : BoundingVolumeBase
		{
			// point lights should be using sphere bounds
			// directional lights should be using null bounds
			return new AxisAlignedBoundingBox();
		}

		/**
		 * Updates the bounding volume for the object. Overriding methods need to set invalid flag to false!
		 */
		protected function updateBounds() : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * @inheritDoc
		 */
		override protected function invalidateSceneTransform() : void
		{
			super.invalidateSceneTransform();
			
			notifySceneBoundsInvalid();
		}

		/**
		 * Invalidates the bounding volume, causing to be updated when requested.
		 */
		protected function invalidateBounds() : void
		{
			_boundsInvalid = true;
			
			notifySceneBoundsInvalid();
		}

		/**
		 * Notify the scene that the global scene bounds have changed, so it can be repartitioned.
		 */
		private function notifySceneBoundsInvalid() : void
		{
			if (_scene)
				_scene.invalidateEntityBounds(this);
		}

		/**
		 * Notify the scene that a new partition was assigned.
		 */
		private function notifyPartitionAssigned() : void
		{
			if (_scene)
				_scene.registerPartition(this);//_onAssignPartitionCallback(this);
		}

		/**
		 * Notify the scene that a partition was unassigned.
		 */
		private function notifyPartitionUnassigned() : void
		{
			if (_scene)
				_scene.unregisterPartition(this);
		}


		override public function get assetType() : String
		{
			return AssetType.ENTITY;
		}
	}
}