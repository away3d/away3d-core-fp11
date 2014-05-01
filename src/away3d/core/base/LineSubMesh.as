package away3d.core.base {
	import away3d.arcane;
	import away3d.core.render.IRenderer;
	import away3d.entities.Mesh;
	import away3d.library.assets.AssetType;
	import away3d.materials.IMaterial;

	use namespace arcane;

	public class LineSubMesh extends SubMeshBase implements ISubMesh {
		private var _subGeometry:LineSubGeometry;

		public function LineSubMesh(subGeometry:LineSubGeometry, parentMesh:Mesh, material:IMaterial = null) {
			_parentMesh = parentMesh;
			_subGeometry = subGeometry;
			this.material = material;
		}

		override public function get assetType():String {
			return AssetType.LINE_SUB_MESH;
		}

		public function get subGeometry():SubGeometryBase {
			return _subGeometry;
		}

		override public function dispose():void {
			material = null;
			super.dispose();
		}

		override public function collectRenderable(renderer:IRenderer):void {
			renderer.applyLineSubMesh(this);
		}
	}
}
