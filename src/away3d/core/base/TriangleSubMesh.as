package away3d.core.base
{
	import away3d.core.render.IRenderer;
	import away3d.entities.Mesh;
	import away3d.core.library.AssetType;
	import away3d.materials.MaterialBase;

	/**
	 * TriangleSubMesh wraps a TriangleSubGeometry as a scene graph instantiation. A TriangleSubMesh is owned by a Mesh object.
	 *
	 *
	 * @see away3d.core.base.TriangleSubGeometry
	 * @see away3d.entities.Mesh
	 *
	 * @class away3d.core.base.TriangleSubMesh
	 */
	public class TriangleSubMesh extends SubMeshBase implements ISubMesh
	{
		private var _subGeometry:TriangleSubGeometry;

		/**
		 * Creates a new TriangleSubMesh object
		 * @param subGeometry The TriangleSubGeometry object which provides the geometry data for this TriangleSubMesh.
		 * @param parentMesh The Mesh object to which this TriangleSubMesh belongs.
		 * @param material An optional material used to render this TriangleSubMesh.
		 */
		public function TriangleSubMesh(subGeometry:TriangleSubGeometry, parentMesh:Mesh, material:MaterialBase = null)
		{
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

		/**
		 * The TriangleSubGeometry object which provides the geometry data for this TriangleSubMesh.
		 */
		public function get subGeometry():SubGeometryBase
		{
			return _subGeometry;
		}

		override public function collectRenderable(renderer:IRenderer):void
		{
			renderer.applyTriangleSubMesh(this);
		}
	}
}
