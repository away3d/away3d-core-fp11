package away3d.core {
	import away3d.core.base.ISubMesh;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.SubMeshBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.render.IRenderer;
	import away3d.entities.Mesh;
	import away3d.library.assets.AssetType;
	import away3d.materials.IMaterial;

	/**
	 * TriangleSubMesh wraps a TriangleSubGeometry as a scene graph instantiation. A TriangleSubMesh is owned by a Mesh object.
	 *
	 *
	 * @see away.base.TriangleSubGeometry
	 * @see away.entities.Mesh
	 *
	 * @class away.base.TriangleSubMesh
	 */
	public class TriangleSubMesh extends SubMeshBase implements ISubMesh{
		private var _subGeometry:TriangleSubGeometry;

		public function TriangleSubMesh(subGeometry:TriangleSubGeometry, parentMesh:Mesh, material:IMaterial = null) {
			_parentMesh = parentMesh;
			_subGeometry = subGeometry;
			this.material = material;
		}

		/**
		 *
		 */
		override public function get assetType():String
		{
			return AssetType.TRIANGLE_SUB_MESH;
		}

		public function get subGeometry():SubGeometryBase {
			return _subGeometry;
		}

		override public function collectRenderable(renderer:IRenderer):void{
			renderer.applyTriangleSubMesh(this);
		}
	}
}
