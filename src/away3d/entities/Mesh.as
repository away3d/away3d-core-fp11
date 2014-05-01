package away3d.entities
{
	import away3d.core.math.UVTransform;
	import away3d.core.render.IRenderer;
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
	public class Mesh extends ObjectContainer3D implements IEntity
	{
		private var _uvTransform:UVTransform;

		private var _subMeshes:Vector.<ISubMesh>;
		private var _geometry:Geometry;
		private var _material:IMaterial;
		private var _animator:IAnimator;
		private var _castsShadows:Boolean = true;
		private var _shareAnimationGeometry:Boolean = true;

		/**
		 * Create a new Mesh object.
		 *
		 * @param geometry                    The geometry used by the mesh that provides it with its shape.
		 * @param material    [optional]        The material with which to render the Mesh.
		 */
		public function Mesh(geometry:Geometry, material:IMaterial = null)
		{
			super();

			_isEntity = true;

			_subMeshes = new Vector.<ISubMesh>();

			this.geometry = geometry || new Geometry(); //this should never happen, but if people insist on trying to create their meshes before they have geometry to fill it, it becomes necessary

			this.material = material;
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

			var len:uint = _subMeshes.length;
			var subMesh:ISubMesh;

			// reassign for each SubMesh
			for (var i:int = 0; i < len; ++i) {
				subMesh = _subMeshes[i];

				if(subMesh.material) {
					subMesh.material.removeOwner(subMesh);
					subMesh.material.addOwner(subMesh);
				}
				subMesh.invalidateRenderableGeometry();
			}

			if (_animator)
				_animator.addOwner(this);
		}

		public override function get assetType():String
		{
			return AssetType.MESH;
		}

		/**
		 * The geometry used by the mesh that provides it with its shape.
		 */
		public function get geometry():Geometry
		{
			if(sourcePrefab) {
				sourcePrefab.validate();
			}
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

				var subGeoms:Vector.<SubGeometryBase> = _geometry.subGeometries;

				for (i = 0; i < subGeoms.length; ++i)
					addSubMesh(subGeoms[i]);
			}
		}

		/**
		 * The material with which to render the Mesh.
		 */
		public function get material():IMaterial
		{
			return _material;
		}

		public function set material(value:IMaterial):void
		{
			if (value == _material)
				return;

			var i:uint;
			var len:uint = _subMeshes.length;
			var subMesh:ISubMesh;

			for(i = 0; i<len; i++) {
				subMesh = _subMeshes[i];
				if(_material && subMesh.material == _material) {
					_material.removeOwner(subMesh);
				}
			}

			_material = value;

			for(i = 0; i<len; i++) {
				subMesh = _subMeshes[i];
				if(_material && subMesh.material == _material) {
					_material.addOwner(subMesh);
				}
			}
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
		 * The SubMeshes out of which the Mesh consists. Every SubMesh can be assigned a material to override the Mesh's
		 * material.
		 */
		public function get subMeshes():Vector.<ISubMesh>
		{
			// Since this getter is invoked every iteration of the render loop, and
			// the geometry construct could affect the sub-meshes, the geometry is
			// validated here to give it a chance to rebuild.
			if(sourcePrefab) {
				sourcePrefab.validate();
			}
			return _subMeshes;
		}

		public function get uvTransform():UVTransform {
			return _uvTransform;
		}

		public function set uvTransform(value:UVTransform):void {
			_uvTransform = value;
		}

		public function bakeTransformations():void
		{
			geometry.applyTransformation(transform);
			transform.identity();
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
			clone.pivot = pivot;
			clone.partition = partition;
			clone.bounds = _bounds.clone();

			clone.name = name;
			clone.castsShadows = castsShadows;
			clone.shareAnimationGeometry = shareAnimationGeometry;
			clone.mouseEnabled = mouseEnabled;
			clone.mouseChildren = mouseChildren;
			//this is of course no proper cloning
			//maybe use this instead?: http://blog.another-d-mention.ro/programming/how-to-clone-duplicate-an-object-in-actionscript-3/
			clone.extra = extra;

			var len:int = _subMeshes.length;
			for (var i:int = 0; i < len; ++i)
				clone._subMeshes[i].material = _subMeshes[i].material;

			len = numChildren;
			for (i = 0; i < len; ++i)
				clone.addChild(ObjectContainer3D(getChildAt(i).clone()));

			if (_animator)
				clone.animator = _animator.clone();

			return clone;
		}

		public function getSubMeshFromSubGeometry(subGeometry:SubGeometry):ISubMesh
		{
			return this._subMeshes[this._geometry.subGeometries.indexOf(subGeometry)];
		}

		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode():EntityNode
		{
			return new EntityNode(this);
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateBounds():void
		{
			_bounds.fromGeometry(_geometry);
			super.updateBounds();
		}

		private function onGeometryBoundsInvalid(event:GeometryEvent):void
		{
			invalidateBounds();
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
			var subMesh:ISubMesh;
			var subGeom:SubGeometryBase = event.subGeometry;
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
				_subMeshes[i].index = i;
		}

		/**
		 * Adds a SubMesh wrapping a SubGeometry.
		 */
		private function addSubMesh(subGeometry:SubGeometryBase):void
		{
			var subMeshClass:Class = subGeometry.subMeshClass;
			var subMesh:ISubMesh = new subMeshClass(subGeometry, this, null);
			var len:uint = _subMeshes.length;
			subMesh.index = len;
			_subMeshes[len] = subMesh;
			invalidateBounds();
		}

		/**
		 * //TODO
		 *
		 * @param shortestCollisionDistance
		 * @param findClosest
		 * @returns {boolean}
		 *
		 * @internal
		 */
		override public function testCollision(shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			return _pickingCollider.testMeshCollision(this, _pickingCollisionVO, shortestCollisionDistance, findClosest);
		}


		public function collectRenderables(renderer:IRenderer):void {
			// Since this getter is invoked every iteration of the render loop, and
			// the prefab construct could affect the sub-meshes, the prefab is
			// validated here to give it a chance to rebuild.
			if (sourcePrefab)
				sourcePrefab.validate();

			var len:uint = _subMeshes.length;
			for (var i:uint = 0; i < len; i++)
				_subMeshes[i].collectRenderable(renderer);

		}

		arcane function invalidateRenderableGeometries():void
		{
			var len:uint = _subMeshes.length;
			for (var i:uint = 0; i < len; ++i)
				_subMeshes[i].invalidateRenderableGeometry();
		}
	}
}
