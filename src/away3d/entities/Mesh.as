package away3d.entities
{
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.MeshNode;
	import away3d.events.GeometryEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.materials.MaterialBase;

	use namespace arcane;

	/**
	 * Mesh is an instance of a Geometry, augmenting it with a presence in the scene graph, a material, and an animation
	 * state. It consists out of SubMeshes, which in turn correspond to SubGeometries. SubMeshes allow different parts
	 * of the geometry to be assigned different materials.
	 */
	public class Mesh extends Entity implements IMaterialOwner, IAsset
	{
		private var _subMeshes : Vector.<SubMesh>;
		protected var _geometry : Geometry;
		private var _material : MaterialBase;
		arcane var _animationState : AnimationStateBase;
		private var _castsShadows : Boolean = true;

		/**
		 * Create a new Mesh object.
		 * @param material The material with which to render the Mesh.
		 * @param geometry The geometry used by the mesh that provides it with its shape.
		 */
		public function Mesh(geometry : Geometry = null, material : MaterialBase = null)
		{
			super();
			_subMeshes = new Vector.<SubMesh>();

			this.geometry = geometry || new Geometry();
			this.material = material;
		}
		
		public function bakeTransformations():void
		{
			geometry.applyTransformation(transform);
			transform.identity();
		}
		
		public override function get assetType() : String
		{
			return AssetType.MESH;
		}
		

		private function onGeometryBoundsInvalid(event : GeometryEvent) : void
		{
			invalidateBounds();
		}

		/**
		 * Indicates whether or not the Mesh can cast shadows
		 */
		public function get castsShadows() : Boolean
		{
			return _castsShadows;
		}

		public function set castsShadows(value : Boolean) : void
		{
			_castsShadows = value;
		}

		/**
		 * The animation state of the mesh, defining how the animation should influence the mesh's geometry.
		 */
		public function get animationState() : AnimationStateBase
		{
			return _animationState;
		}

		public function set animationState(value : AnimationStateBase) : void
		{
			if (_animationState) _animationState.removeOwner(this);
			_animationState = value;
			if (_animationState) _animationState.addOwner(this);
		}

		/**
		 * The geometry used by the mesh that provides it with its shape.
		 */
		public function get geometry() : Geometry
		{
			return _geometry;
		}

		public function set geometry(value : Geometry) : void
		{
			if (_geometry) {
				_geometry.removeEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);
				_geometry.removeEventListener(GeometryEvent.ANIMATION_CHANGED, onAnimationChanged);

				for (var i : uint = 0; i < _subMeshes.length; ++i) {
					_subMeshes[i].dispose();
				}
				_subMeshes.length = 0;
			}

			_geometry = value;
			if (_geometry) {
				_geometry.addEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);
				_geometry.addEventListener(GeometryEvent.ANIMATION_CHANGED, onAnimationChanged);
				initGeometry();
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
		public function get material() : MaterialBase
		{
			return _material;
		}

		public function set material(value : MaterialBase) : void
		{
			if (value == _material) return;
			if (_material) _material.removeOwner(this);
			_material = value;
			if (_material) _material.addOwner(this);
		}

		/**
		 * The type of animation used to influence the geometry.
		 */
		public function get animation() : AnimationBase
		{
			return _geometry.animation;
		}

		/**
		 * The SubMeshes out of which the Mesh consists. Every SubMesh can be assigned a material to override the Mesh's
		 * material.
		 */
		public function get subMeshes() : Vector.<SubMesh>
		{
			// Since this getter is invoked every iteration of the render loop, and
			// the geometry construct could affect the sub-meshes, the geometry is
			// validated here to give it a chance to rebuild.
			_geometry.validate();
			
			return _subMeshes;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			super.dispose();
			material = null;
			geometry = null;
		}

		/**
		 * Clones this Mesh instance along with all it's children, while re-using the same
		 * material and geometry instance. The returned result will be a copy of this mesh,
		 * containing copies of all of it's children.
		 * 
		 * Properties that are re-used (i.e. not cloned) by the new copy include name, 
		 * geometry, and material. Properties that are cloned or created anew for the copy
		 * include subMeshes, animation and animationState and the children of the mesh.
		 * 
		 * If you want to copy just the mesh, reusing it's geometry and material while not
		 * cloning it's children, the simplest way is to create a new mesh manually:
		 * 
		 * <code>
		 * var clone : Mesh = new Mesh(original.geometry, original.material);
		 * </code>
		*/
		override public function clone() : Object3D
		{
			var clone : Mesh = new Mesh(geometry, _material);
			clone.transform = transform;
			clone.pivotPoint = pivotPoint;
			clone.partition = partition;
			clone.bounds = _bounds.clone();
			clone.name = name;

			var len : int = _subMeshes.length;
			for (var i : int = 0; i < len; ++i) {
				clone._subMeshes[i]._material = _subMeshes[i]._material;
			}

			len = numChildren;
			for (i = 0; i < len; ++i) {
				clone.addChild(ObjectContainer3D(getChildAt(i).clone()));
			}

			return clone;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateBounds() : void
		{
			_bounds.fromGeometry(_geometry);
			_boundsInvalid = false;
		}

		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new MeshNode(this);
		}

		/**
		 * Initialises the SubMesh objects to map unto the Geometry's SubGeometry objects.
		 */
		protected function initGeometry() : void
		{
			var subGeoms : Vector.<SubGeometry> = _geometry.subGeometries;

			for (var i : uint = 0; i < subGeoms.length; ++i)
				addSubMesh(subGeoms[i]);

			if (_geometry.animation) animationState = _geometry.animation.createAnimationState();
		}

		/**
		 * Called when a SubGeometry was added to the Geometry.
		 */
		private function onSubGeometryAdded(event : GeometryEvent) : void
		{
			addSubMesh(event.subGeometry);
		}

		/**
		 * Called when a SubGeometry was removed from the Geometry.
		 */
		private function onSubGeometryRemoved(event : GeometryEvent) : void
		{
			var subMesh : SubMesh;
			var subGeom : SubGeometry = event.subGeometry;
			var len : int = _subMeshes.length;
			var i : uint;
			
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
			for (; i < len; ++i) {
				_subMeshes[i]._index = i;
			}
		}

		/**
		 * Adds a SubMesh wrapping a SubGeometry.
		 */
		private function addSubMesh(subGeometry : SubGeometry) : void
		{
			var subMesh : SubMesh = new SubMesh(subGeometry, this, null);
			var len : uint = _subMeshes.length;
			subMesh._index = len;
			_subMeshes[len] = subMesh;
			invalidateBounds();
		}

		/**
		 * Called when the Geometry's animation type was changed.
		 */
		private function onAnimationChanged(event : GeometryEvent) : void
		{
			animationState = _geometry.animation.createAnimationState();

			// cause material to be unregistered and registered again to work with the new animation type (if possible)
			var oldMaterial : MaterialBase = material;
			material = null;
			material = oldMaterial;

			var len : uint = _subMeshes.length;
			var subMesh : SubMesh;

			// reassign for each SubMesh
			for (var i : int = 0; i < len; ++i) {
				subMesh = _subMeshes[i];
				oldMaterial = subMesh._material;
				if (oldMaterial) {
					subMesh.material = null;
					subMesh.material = oldMaterial;
				}
			}
		}

		public function getSubMeshForSubGeometry(subGeometry : SubGeometry) : SubMesh
		{
			return _subMeshes[_geometry.subGeometries.indexOf(subGeometry)];
		}

		override arcane function collidesBefore(shortestCollisionDistance : Number) : Boolean
		{
			_pickingCollider.setLocalRay(_pickingCollisionVO.localRayPosition, _pickingCollisionVO.localRayDirection);
			var len : int = _subMeshes.length;
			for (var i : int = 0; i < len; ++i)
				if (_pickingCollider.testSubMeshCollision(_subMeshes[i], _pickingCollisionVO, shortestCollisionDistance))
					return true;

			return false;
		}
	}
}
