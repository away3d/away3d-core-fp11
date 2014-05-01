package away3d.core.base {
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.core.math.UVTransform;
	import away3d.core.render.IRenderer;
	import away3d.entities.Camera3D;
	import away3d.entities.Mesh;
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.NamedAssetBase;
	import away3d.materials.IMaterial;

	import flash.geom.Matrix3D;

	use namespace arcane;

	public class SubMeshBase extends NamedAssetBase implements IMaterialOwner
	{
		protected var _parentMesh:Mesh;
		protected var _uvTransform:UVTransform;
		protected var _index:Number = 0;

		protected var _material:IMaterial;
		private var _renderables:Vector.<IRenderable> = new Vector.<IRenderable>();

		public function SubMeshBase() {
		}

		/**
		 * The animator object that provides the state for the TriangleSubMesh's animation.
		 */
		public function get animator():IAnimator
		{
			return _parentMesh.animator;
		}

		/**
		 * The material used to render the current TriangleSubMesh. If set to null, its parent Mesh's material will be used instead.
		 */
		public function get material():IMaterial
		{
			return this._material || _parentMesh.material;
		}

		public function set material(value:IMaterial):void
		{
			if (material)
				material.removeOwner(this);

			_material = value;

			if (material)
				material.addOwner(this);
		}
		/**
		 * The scene transform object that transforms from model to world space.
		 */
		public function get sceneTransform():Matrix3D
		{
			return _parentMesh.sceneTransform;
		}

		/**
		 * The entity that that initially provided the IRenderable to the render pipeline (ie: the owning Mesh object).
		 */
		public function get parentMesh():Mesh
		{
			return _parentMesh;
		}

		/**
		 *
		 */
		public function get uvTransform():UVTransform
		{
			return _uvTransform || _parentMesh.uvTransform;
		}

		public function set uvTransform(value:UVTransform):void
		{
			_uvTransform = value;
		}

		public function dispose():void
		{
			this.material = null;

			var len:uint = _renderables.length;
			for (var i:uint = 0; i < len; i++)
				_renderables[i].dispose();
		}

		/**
		 *
		 * @param camera
		 * @returns {away.geom.Matrix3D}
		 */
		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			return _parentMesh.getRenderSceneTransform(camera);
		}

		public function addRenderable(renderable:IRenderable):IRenderable
		{
			_renderables.push(renderable);
			return renderable;
		}


		public function removeRenderable(renderable:IRenderable):IRenderable
		{
			var index:int = _renderables.indexOf(renderable);

			_renderables.splice(index, 1);

			return renderable;
		}

		public function invalidateRenderableGeometry():void
		{
			var len:uint = _renderables.length;
			for (var i:uint = 0; i < len; i++)
				_renderables[i].invalidateGeometry();
		}

		public function collectRenderable(renderer:IRenderer):void
		{
			throw new AbstractMethodError();
		}

		public function getExplicitMaterial():IMaterial
		{
			return _material;
		}

		public function get index():Number {
			return _index;
		}

		public function set index(value:Number):void {
			_index = value;
		}
	}
}
