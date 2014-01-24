package away3d.entities
{
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.core.partition.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	import away3d.materials.*;
	
	use namespace arcane;
	
	/**
	 * Mesh is an instance of a Geometry, augmenting it with a presence in the scene graph, a material, and an animation
	 * state. It consists out of SubMeshes, which in turn correspond to SubGeometries. SubMeshes allow different parts
	 * of the geometry to be assigned different materials.
	 */
	public class Mesh extends Entity implements IMaterialOwner, IAsset
	{
		private var _subMeshes:Vector.<SubMesh>;
		protected var _geometry:Geometry;
		private var _material:MaterialBase;
		private var _animator:IAnimator;
		private var _castsShadows:Boolean = true;
		private var _shareAnimationGeometry:Boolean = true;
		
		/**
		 * Create a new Mesh object.
		 *
		 * @param geometry                    The geometry used by the mesh that provides it with its shape.
		 * @param material    [optional]        The material with which to render the Mesh.
		 */
		public function Mesh(geometry:Geometry, material:MaterialBase = null)
		{
			super();
			_subMeshes = new Vector.<SubMesh>();
			
			this.geometry = geometry || new Geometry(); //this should never happen, but if people insist on trying to create their meshes before they have geometry to fill it, it becomes necessary
			
			this.material = material || DefaultMaterialManager.getDefaultMaterial(this);
		}
		
		public function bakeTransformations():void
		{
			geometry.applyTransformation(transform);
			transform.identity();
		}
		
		public override function get assetType():String
		{
			return AssetType.MESH;
		}
		
		private function onGeometryBoundsInvalid(event:GeometryEvent):void
		{
			invalidateBounds();
		}
		
		/**
		 * Indicates whether or not the Mesh can cast shadows. Default value is <code>true</code>.
		 */
		public function get castsShadows():Boolean
		{
			return _castsShadows;
		}
		
		public function set castsShadows(value:Boolean):void
		{
			_castsShadows = value;
		}
		
		/**
		 * Defines the animator of the mesh. Act on the mesh's geometry. Default value is <code>null</code>.
		 */
		public function get animator():IAnimator
		{
			return _animator;
		}
		
		public function set animator(value:IAnimator):void
		{
			if (_animator)
				_animator.removeOwner(this);
			
			_animator = value;
			
			// cause material to be unregistered and registered again to work with the new animation type (if possible)
			var oldMaterial:MaterialBase = material;
			material = null;
			material = oldMaterial;
			
			var len:uint = _subMeshes.length;
			var subMesh:SubMesh;
			
			// reassign for each SubMesh
			for (var i:int = 0; i < len; ++i) {
				subMesh = _subMeshes[i];
				oldMaterial = subMesh._material;
				if (oldMaterial) {
					subMesh.material = null;
					subMesh.material = oldMaterial;
				}
			}
			
			if (_animator)
				_animator.addOwner(this);
		}
		
		/**
		 * The geometry used by the mesh that provides it with its shape.
		 */
		public function get geometry():Geometry
		{
			return _geometry;
		}
		
		public function set geometry(value:Geometry):void
		{
			var i:uint;
			
			if (_geometry) {
				_geometry.removeEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);
				
				for (i = 0; i < _subMeshes.length; ++i)
					_subMeshes[i].dispose();
				_subMeshes.length = 0;
			}
			
			_geometry = value;
			if (_geometry) {
				_geometry.addEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);
				
				var subGeoms:Vector.<ISubGeometry> = _geometry.subGeometries;
				
				for (i = 0; i < subGeoms.length; ++i)
					addSubMesh(subGeoms[i]);
			}
			
			if (_material) {
				// reregister material in case geometry has a different animation
				_material.removeOwner(this);
				_material.addOwner(this);
			}
		}
		
		/**
		 * The material with which to render the Mesh.
		 */
		public function get material():MaterialBase
		{
			return _material;
		}
		
		public function set material(value:MaterialBase):void
		{
			if (value == _material)
				return;
			if (_material)
				_material.removeOwner(this);
			_material = value;
			if (_material)
				_material.addOwner(this);
		}
		
		/**
		 * The SubMeshes out of which the Mesh consists. Every SubMesh can be assigned a material to override the Mesh's
		 * material.
		 */
		public function get subMeshes():Vector.<SubMesh>
		{
			// Since this getter is invoked every iteration of the render loop, and
			// the geometry construct could affect the sub-meshes, the geometry is
			// validated here to give it a chance to rebuild.
			_geometry.validate();
			
			return _subMeshes;
		}
		
		/**
		 * Indicates whether or not the mesh share the same animation geometry.
		 */
		public function get shareAnimationGeometry():Boolean
		{
			return _shareAnimationGeometry;
		}
		
		public function set shareAnimationGeometry(value:Boolean):void
		{
			_shareAnimationGeometry = value;
		}
		
		/**
		 * Clears the animation geometry of this mesh. It will cause animation to generate a new animation geometry. Work only when shareAnimationGeometry is false.
		 */
		public function clearAnimationGeometry():void
		{
			var len:int = _subMeshes.length;
			for (var i:int = 0; i < len; ++i)
				_subMeshes[i].animationSubGeometry = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			
			material = null;
			geometry = null;
		}
		
		/**
		 * Disposes mesh including the animator and children. This is a merely a convenience method.
		 * @return
		 */
		public function disposeWithAnimatorAndChildren():void
		{
			disposeWithChildren();
			
			if (_animator)
				_animator.dispose();
		}
		
		/**
		 * Clones this Mesh instance along with all it's children, while re-using the same
		 * material, geometry and animation set. The returned result will be a copy of this mesh,
		 * containing copies of all of it's children.
		 *
		 * Properties that are re-used (i.e. not cloned) by the new copy include name,
		 * geometry, and material. Properties that are cloned or created anew for the copy
		 * include subMeshes, children of the mesh, and the animator.
		 *
		 * If you want to copy just the mesh, reusing it's geometry and material while not
		 * cloning it's children, the simplest way is to create a new mesh manually:
		 *
		 * <code>
		 * var clone : Mesh = new Mesh(original.geometry, original.material);
		 * </code>
		 */
		override public function clone():Object3D
		{
			var clone:Mesh = new Mesh(_geometry, _material);
			clone.transform = transform;
			clone.pivotPoint = pivotPoint;
			clone.partition = partition;
			clone.bounds = _bounds.clone();
			clone.name = name;
			clone.castsShadows = castsShadows;
			clone.shareAnimationGeometry = shareAnimationGeometry;
			clone.mouseEnabled = this.mouseEnabled;
			clone.mouseChildren = this.mouseChildren;
			//this is of course no proper cloning
			//maybe use this instead?: http://blog.another-d-mention.ro/programming/how-to-clone-duplicate-an-object-in-actionscript-3/
			clone.extra = this.extra;
			
			var len:int = _subMeshes.length;
			for (var i:int = 0; i < len; ++i)
				clone._subMeshes[i]._material = _subMeshes[i]._material;
			
			len = numChildren;
			for (i = 0; i < len; ++i)
				clone.addChild(ObjectContainer3D(getChildAt(i).clone()));
			
			if (_animator)
				clone.animator = _animator.clone();
			
			return clone;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateBounds():void
		{
			_bounds.fromGeometry(_geometry);
			_boundsInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode():EntityNode
		{
			return new MeshNode(this);
		}
		
		/**
		 * Called when a SubGeometry was added to the Geometry.
		 */
		private function onSubGeometryAdded(event:GeometryEvent):void
		{
			addSubMesh(event.subGeometry);
		}
		
		/**
		 * Called when a SubGeometry was removed from the Geometry.
		 */
		private function onSubGeometryRemoved(event:GeometryEvent):void
		{
			var subMesh:SubMesh;
			var subGeom:ISubGeometry = event.subGeometry;
			var len:int = _subMeshes.length;
			var i:uint;
			
			// Important! This has to be done here, and not delayed until the
			// next render loop, since this may be caused by the geometry being
			// rebuilt IN THE RENDER LOOP. Invalidating and waiting will delay
			// it until the NEXT RENDER FRAME which is probably not desirable.
			
			for (i = 0; i < len; ++i) {
				subMesh = _subMeshes[i];
				if (subMesh.subGeometry == subGeom) {
					subMesh.dispose();
					_subMeshes.splice(i, 1);
					break;
				}
			}
			
			--len;
			for (; i < len; ++i)
				_subMeshes[i]._index = i;
		}
		
		/**
		 * Adds a SubMesh wrapping a SubGeometry.
		 */
		private function addSubMesh(subGeometry:ISubGeometry):void
		{
			var subMesh:SubMesh = new SubMesh(subGeometry, this, null);
			var len:uint = _subMeshes.length;
			subMesh._index = len;
			_subMeshes[len] = subMesh;
			invalidateBounds();
		}
		
		public function getSubMeshForSubGeometry(subGeometry:SubGeometry):SubMesh
		{
			return _subMeshes[_geometry.subGeometries.indexOf(subGeometry)];
		}
		
		override arcane function collidesBefore(shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			_pickingCollider.setLocalRay(_pickingCollisionVO.localRayPosition, _pickingCollisionVO.localRayDirection);
			_pickingCollisionVO.renderable = null;
			var len:int = _subMeshes.length;
			for (var i:int = 0; i < len; ++i) {
				var subMesh:SubMesh = _subMeshes[i];
				
				//var ignoreFacesLookingAway:Boolean = _material ? !_material.bothSides : true;
				if (_pickingCollider.testSubMeshCollision(subMesh, _pickingCollisionVO, shortestCollisionDistance)) {
					shortestCollisionDistance = _pickingCollisionVO.rayEntryDistance;
					_pickingCollisionVO.renderable = subMesh;
					if (!findClosest)
						return true;
				}
			}
			
			return _pickingCollisionVO.renderable != null;
		}
	}
}
