package away3d.entities
{
	import away3d.arcane;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.AnimatorBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.core.base.Geometry;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.events.GeometryEvent;
	import away3d.materials.MaterialBase;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.MeshNode;

	use namespace arcane;

	/**
	 * Mesh is an instance of a Geometry, augmenting it with a presence in the scene graph, a material, and an animation
	 * state. It consists out of SubMeshes, which in turn correspond to SubGeometries. SubMeshes allow different parts
	 * of the geometry to be assigned different materials.
	 */
	public class Mesh extends Entity implements IMaterialOwner
	{
		private var _subMeshes : Vector.<SubMesh>;
		protected var _geometry : Geometry;
		private var _material : MaterialBase;
		arcane var _animationState : AnimationStateBase;
		private var _mouseDetails : Boolean;
		private var _castsShadows : Boolean = true;

		/**
		 * Create a new Mesh object.
		 * @param material The material with which to render the Mesh.
		 * @param geometry The geometry used by the mesh that provides it with its shape.
		 */
		public function Mesh(material : MaterialBase = null, geometry : Geometry = null)
		{
			super();
			_geometry = geometry || new Geometry();
			_geometry.addEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
			_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
			_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);
			_geometry.addEventListener(GeometryEvent.ANIMATION_CHANGED, onAnimationChanged);
			_subMeshes = new Vector.<SubMesh>();
			this.material = material;
			if (geometry) initGeometry();
		}

		private function onGeometryBoundsInvalid(event : GeometryEvent) : void
		{
			invalidateBounds();
		}

		/**
		 * Indicates whether or not mouse events contain UV and position coordinates. Setting this to true can affect performance. Defaults to false.
		 */
		public function get mouseDetails() : Boolean
		{
			return _mouseDetails;
		}

		public function set mouseDetails(value : Boolean) : void
		{
			_mouseDetails = value;
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
			return _subMeshes;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			if (deep) {
				_geometry.dispose();
				_material.dispose(true);
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function clone() : Object3D
		{
			var clone : Mesh = new Mesh(_material, geometry);
//			clone._animationState = _animationState? _animationState.clone() : null;
			clone.transform = transform;
			clone.pivotPoint = pivotPoint;
			clone.bounds = _bounds.clone();

			var len : int = _subMeshes.length;
			for (var i : int = 0; i < len; ++i) {
				clone._subMeshes[i]._material = _subMeshes[i]._material;
			}
			// todo: is there more to be cloned?
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
			var subGeom : SubGeometry;
			var len : uint;
			for (var i : uint = 0; i < len; ++i) {
				subMesh = _subMeshes[i];
				if (subMesh.subGeometry == subGeom) {
					_subMeshes.splice(i, 1);
					return;
				}
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
		}

		/**
		 * Called when the Geometry's animation type was changed.
		 */
		private function onAnimationChanged(event : GeometryEvent) : void
		{
			animationState = _geometry.animation.createAnimationState();
		}
	}
}