package away3d.entities
{
	import away3d.arcane;
	import away3d.bounds.*;
	import away3d.containers.*;
	import away3d.core.partition.*;
	import away3d.core.pick.*;
	import away3d.errors.*;
	import away3d.library.assets.*;
	
	import flash.geom.*;
	
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
		private var _showBounds:Boolean;
		private var _partitionNode:EntityNode;
		private var _boundsIsShown:Boolean = false;
		private var _shaderPickingDetails:Boolean;
		
		arcane var _pickingCollisionVO:PickingCollisionVO;
		arcane var _pickingCollider:IPickingCollider;
		arcane var _staticNode:Boolean;
		
		protected var _bounds:BoundingVolumeBase;
		protected var _boundsInvalid:Boolean = true;
		private var _worldBounds:BoundingVolumeBase;
		private var _worldBoundsInvalid:Boolean = true;
		
		override public function set ignoreTransform(value:Boolean):void
		{
			if (_scene)
				_scene.invalidateEntityBounds(this);
			super.ignoreTransform = value;
		}
		
		/**
		 * Used by the shader-based picking system to determine whether a separate render pass is made in order
		 * to offer more details for the picking collision object, including local position, normal vector and uv value.
		 * Defaults to false.
		 *
		 * @see away3d.core.pick.ShaderPicker
		 */
		public function get shaderPickingDetails():Boolean
		{
			return _shaderPickingDetails;
		}
		
		public function set shaderPickingDetails(value:Boolean):void
		{
			_shaderPickingDetails = value;
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
		
		/**
		 * Returns a unique picking collision value object for the entity.
		 */
		public function get pickingCollisionVO():PickingCollisionVO
		{
			if (!_pickingCollisionVO)
				_pickingCollisionVO = new PickingCollisionVO(this);
			
			return _pickingCollisionVO;
		}
		
		/**
		 * Tests if a collision occurs before shortestCollisionDistance, using the data stored in PickingCollisionVO.
		 * @param shortestCollisionDistance
		 * @return
		 */
		arcane function collidesBefore(shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			shortestCollisionDistance = shortestCollisionDistance;
			findClosest = findClosest;
			return true;
		}
		
		/**
		 *
		 */
		public function get showBounds():Boolean
		{
			return _showBounds;
		}
		
		public function set showBounds(value:Boolean):void
		{
			if (value == _showBounds)
				return;
			
			_showBounds = value;
			
			if (_showBounds)
				addBounds();
			else
				removeBounds();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get minX():Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.x;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get minY():Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.y;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get minZ():Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.z;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get maxX():Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.x;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get maxY():Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.y;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get maxZ():Number
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.z;
		}
		
		/**
		 * The bounding volume approximating the volume occupied by the Entity.
		 */
		public function get bounds():BoundingVolumeBase
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds;
		}
		
		public function set bounds(value:BoundingVolumeBase):void
		{
			removeBounds();
			_bounds = value;
			_worldBounds = value.clone();
			invalidateBounds();
			if (_showBounds)
				addBounds();
		}
		
		public function get worldBounds():BoundingVolumeBase
		{
			if (_worldBoundsInvalid)
				updateWorldBounds();
			
			return _worldBounds;
		}
		
		private function updateWorldBounds():void
		{
			_worldBounds.transformFrom(bounds, sceneTransform);
			_worldBoundsInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function set implicitPartition(value:Partition3D):void
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
		override public function set scene(value:Scene3D):void
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
		
		override public function get assetType():String
		{
			return AssetType.ENTITY;
		}
		
		/**
		 * Used by the raycast-based picking system to determine how the geometric contents of an entity are processed
		 * in order to offer more details for the picking collision object, including local position, normal vector and uv value.
		 * Defaults to null.
		 *
		 * @see away3d.core.pick.RaycastPicker
		 */
		public function get pickingCollider():IPickingCollider
		{
			return _pickingCollider;
		}
		
		public function set pickingCollider(value:IPickingCollider):void
		{
			_pickingCollider = value;
		}
		
		/**
		 * Creates a new Entity object.
		 */
		public function Entity()
		{
			super();
			
			_bounds = getDefaultBoundingVolume();
			_worldBounds = getDefaultBoundingVolume();
		}
		
		/**
		 * Gets a concrete EntityPartition3DNode subclass that is associated with this Entity instance
		 */
		public function getEntityPartitionNode():EntityNode
		{
			return _partitionNode ||= createEntityPartitionNode();
		}
		
		public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Boolean
		{
			// convert ray to entity space
			var localRayPosition:Vector3D = inverseSceneTransform.transformVector(rayPosition);
			var localRayDirection:Vector3D = inverseSceneTransform.deltaTransformVector(rayDirection);
			
			// check for ray-bounds collision
			var rayEntryDistance:Number = bounds.rayIntersection(localRayPosition, localRayDirection, pickingCollisionVO.localNormal ||= new Vector3D());
			
			if (rayEntryDistance < 0)
				return false;
			
			// Store collision data.
			pickingCollisionVO.rayEntryDistance = rayEntryDistance;
			pickingCollisionVO.localRayPosition = localRayPosition;
			pickingCollisionVO.localRayDirection = localRayDirection;
			pickingCollisionVO.rayPosition = rayPosition;
			pickingCollisionVO.rayDirection = rayDirection;
			pickingCollisionVO.rayOriginIsInsideBounds = rayEntryDistance == 0;
			
			return true;
		}
		
		/**
		 * Factory method that returns the current partition node. Needs to be overridden by concrete subclasses
		 * such as Mesh to return the correct concrete subtype of EntityPartition3DNode (for Mesh = MeshPartition3DNode,
		 * most IRenderables (particles fe) would return RenderablePartition3DNode, I suppose)
		 */
		protected function createEntityPartitionNode():EntityNode
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Creates the default bounding box to be used by this type of Entity.
		 * @return
		 */
		protected function getDefaultBoundingVolume():BoundingVolumeBase
		{
			// point lights should be using sphere bounds
			// directional lights should be using null bounds
			return new AxisAlignedBoundingBox();
		}
		
		/**
		 * Updates the bounding volume for the object. Overriding methods need to set invalid flag to false!
		 */
		protected function updateBounds():void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function invalidateSceneTransform():void
		{
			if (!_ignoreTransform) {
				super.invalidateSceneTransform();
				_worldBoundsInvalid = true;
				notifySceneBoundsInvalid();
			}
		}
		
		/**
		 * Invalidates the bounding volume, causing to be updated when requested.
		 */
		protected function invalidateBounds():void
		{
			_boundsInvalid = true;
			_worldBoundsInvalid = true;
			notifySceneBoundsInvalid();
		}
		
		override protected function updateMouseChildren():void
		{
			// If there is a parent and this child does not have a triangle collider, use its parent's triangle collider.
			if (_parent && !pickingCollider) {
				if (_parent is Entity) {
					var collider:IPickingCollider = Entity(_parent).pickingCollider;
					if (collider)
						pickingCollider = collider;
				}
			}
			
			super.updateMouseChildren();
		}
		
		/**
		 * Notify the scene that the global scene bounds have changed, so it can be repartitioned.
		 */
		private function notifySceneBoundsInvalid():void
		{
			if (_scene)
				_scene.invalidateEntityBounds(this);
		}
		
		/**
		 * Notify the scene that a new partition was assigned.
		 */
		private function notifyPartitionAssigned():void
		{
			if (_scene)
				_scene.registerPartition(this); //_onAssignPartitionCallback(this);
		}
		
		/**
		 * Notify the scene that a partition was unassigned.
		 */
		private function notifyPartitionUnassigned():void
		{
			if (_scene)
				_scene.unregisterPartition(this);
		}
		
		private function addBounds():void
		{
			if (!_boundsIsShown) {
				_boundsIsShown = true;
				addChild(_bounds.boundingRenderable);
			}
		}
		
		private function removeBounds():void
		{
			if (_boundsIsShown) {
				_boundsIsShown = false;
				removeChild(_bounds.boundingRenderable);
				_bounds.disposeRenderable();
			}
		}
		
		arcane function internalUpdate():void
		{
			if (_controller)
				_controller.update();
		}
	}
}
