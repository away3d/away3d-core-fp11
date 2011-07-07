package away3d.core.base
{
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Entity;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * SubMesh wraps a SubGeometry as a scene graph instantiation. A SubMesh is owned by a Mesh object.
	 *
	 * @see away3d.core.base.SubGeometry
	 * @see away3d.scenegraph.Mesh
	 */
	public class SubMesh implements IRenderable
	{
		arcane var _material : MaterialBase;
		private var _parentMesh : Mesh;
		private var _subGeometry : SubGeometry;
		arcane var _index : uint;
		private var _uvTransform : Matrix;
		private var _uvTransformDirty : Boolean;
		private var _uvRotation : Number = 0;
		private var _scaleU : Number = 1;
		private var _scaleV : Number = 1;
		private var _offsetU : Number = 0;
		private var _offsetV : Number = 0;

		/**
		 * Creates a new SubMesh object
		 * @param subGeometry The SubGeometry object which provides the geometry data for this SubMesh.
		 * @param parentMesh The Mesh object to which this SubMesh belongs.
		 * @param material An optional material used to render this SubMesh.
		 */
		public function SubMesh(subGeometry : SubGeometry, parentMesh : Mesh, material : MaterialBase = null)
		{
			_parentMesh = parentMesh;
			_subGeometry = subGeometry;
			this.material = material;
		}

		public function get offsetU() : Number
		{
			return _offsetU;
		}

		public function set offsetU(value : Number) : void
		{
			if (value == _offsetU) return;
			_offsetU = value;
			_uvTransformDirty = true;
		}

		public function get offsetV() : Number
		{
			return _offsetV;
		}

		public function set offsetV(value : Number) : void
		{
			if (value == _offsetV) return;
			_offsetV = value;
			_uvTransformDirty = true;
		}

		public function get scaleU() : Number
		{
			return _scaleU;
		}

		public function set scaleU(value : Number) : void
		{
			if (value == _scaleU) return;
			_scaleU = value;
			_uvTransformDirty = true;
		}

		public function get scaleV() : Number
		{
			return _scaleV;
		}

		public function set scaleV(value : Number) : void
		{
			if (value == _scaleV) return;
			_scaleV = value;
			_uvTransformDirty = true;
		}

		public function get uvRotation() : Number
		{
			return _uvRotation;
		}

		public function set uvRotation(value : Number) : void
		{
			if (value == _uvRotation) return;
			_uvRotation = value;
			_uvTransformDirty = true;
		}

		/**
		 * The entity that that initially provided the IRenderable to the render pipeline (ie: the owning Mesh object).
		 */
		public function get sourceEntity() : Entity
		{
			return _parentMesh;
		}

		/**
		 * The SubGeometry object which provides the geometry data for this SubMesh.
		 */
		public function get subGeometry() : SubGeometry
		{
			return _subGeometry;
		}

		public function set subGeometry(value : SubGeometry) : void
		{
			_subGeometry = value;
		}

		/**
		 * The material used to render the current SubMesh. If set to null, its parent Mesh's material will be used instead.
		 */
		public function get material() : MaterialBase
		{
			return _material || _parentMesh.material;
		}

		public function set material(value : MaterialBase) : void
		{
			if (_material) _material.removeOwner(this);

			_material = value;

			if (_material) _material.addOwner(this);
		}

		/**
		 * The animation object which is used to transform the geometry.
		 */
		public function get animation() : AnimationBase
		{
			return _subGeometry.animation;
		}

		/**
		 * The distance of the SubMesh object to the view, used to sort per object.
		 */
		public function get zIndex() : Number
		{
			return _parentMesh.zIndex;
		}

		/**
		 * The scene transform object that transforms from model to world space.
		 */
		public function get sceneTransform() : Matrix3D
		{
			return _parentMesh.sceneTransform;
		}

		/**
		 * The inverse scene transform object that transforms from world to model space.
		 */
		public function get inverseSceneTransform() : Matrix3D
		{
			return _parentMesh.inverseSceneTransform;
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex positions.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex positions.
		 */
		public function getVertexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _subGeometry.getVertexBuffer(stage3DProxy);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex normals.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex normals.
		 */
		public function getVertexNormalBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _subGeometry.getVertexNormalBuffer(stage3DProxy);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex tangents.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex tangents.
		 */
		public function getVertexTangentBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _subGeometry.getVertexTangentBuffer(stage3DProxy);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains texture coordinates.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains texture coordinates.
		 */
		public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _subGeometry.getUVBuffer(stage3DProxy);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains triangle indices.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains triangle indices.
		 */
		public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
		{
			return _subGeometry.getIndexBuffer(stage3DProxy);
		}

		/**
		 * The model-view-projection (MVP) matrix used to transform from model to homogeneous projection space.
		 */
		public function get modelViewProjection() : Matrix3D
		{
			return _parentMesh.modelViewProjection;
		}

		/**
		 * The amount of triangles that make up this SubMesh.
		 */
		public function get numTriangles() : uint
		{
			return _subGeometry.numTriangles;
		}

		/**
		 * The AnimationStateBase object that provides the state for the SubMesh's animation.
		 */
		public function get animationState() : AnimationStateBase
		{
			return _parentMesh._animationState;
		}

		/**
		 * Indicates whether the SubMesh should trigger mouse events, and hence should be rendered for hit testing.
		 */
		public function get mouseEnabled() : Boolean
		{
			return _parentMesh.mouseEnabled;
		}

		/**
		 * Indicates whether the SubMesh needs to provide mouse event details, such as position and uv coordinates.
		 */
		public function get mouseDetails() : Boolean
		{
			return _parentMesh.mouseDetails;
		}

		public function get castsShadows() : Boolean
		{
			return _parentMesh.castsShadows;
		}

		/**
		 * A reference to the owning Mesh object
		 *
		 * @private
		 */
		arcane function get parentMesh() : Mesh
		{
			return _parentMesh;
		}

		arcane function set parentMesh(value : Mesh) : void
		{
			_parentMesh = value;
		}

		public function get uvTransform() : Matrix
		{
			if (_uvTransformDirty) updateUVTransform();
			return _uvTransform;
		}

		private function updateUVTransform() : void
		{
			_uvTransform ||= new Matrix();
			_uvTransform.identity();
			if (_uvRotation != 0) _uvTransform.rotate(_uvRotation);
			if (_scaleU != 1 || _scaleV != 1) _uvTransform.scale(_scaleU, _scaleV);
			_uvTransform.translate(_offsetU, _offsetV);
			_uvTransformDirty = false;
		}
	}
}