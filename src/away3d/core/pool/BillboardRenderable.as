package away3d.core.pool
{
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.entities.Billboard;
	import away3d.materials.MaterialBase;

	public class BillboardRenderable extends RenderableBase
	{
		private static const _materialGeometry:Object = {};

		public static const id:String = "billboard";

		private var _billboard:Billboard;

		public function BillboardRenderable(pool:RenderablePool, billboard:Billboard)
		{
			super(pool, billboard, billboard);

			_billboard = billboard;
		}

		override protected function getSubGeometry():SubGeometryBase
		{
			var material:MaterialBase = _billboard.material;

			var geometry:TriangleSubGeometry = _materialGeometry[material.id];

			if (!geometry) {
				geometry = _materialGeometry[material.id] = new TriangleSubGeometry(true);
				geometry.autoDeriveNormals = false;
				geometry.autoDeriveTangents = false;
				geometry.updateIndices(Vector.<uint>([0, 1, 2, 0, 2, 3]));
				geometry.updatePositions(Vector.<Number>([0, material.height, 0, material.width, material.height, 0, material.width, 0, 0, 0, 0, 0]));
				geometry.updateVertexNormals(Vector.<Number>([1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0]));
				geometry.updateVertexTangents(Vector.<Number>([0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1]));
				geometry.updateUVs(Vector.<Number>([0, 0, 1, 0, 1, 1, 0, 1]));
			} else {
				geometry.updatePositions(Vector.<Number>([0, material.height, 0, material.width, material.height, 0, material.width, 0, 0, 0, 0, 0]));
			}

			_vertexDataDirty[TriangleSubGeometry.POSITION_DATA] = true;
			_vertexDataDirty[TriangleSubGeometry.NORMAL_DATA] = true;
			_vertexDataDirty[TriangleSubGeometry.TANGENT_DATA] = true;
			_vertexDataDirty[TriangleSubGeometry.UV_DATA] = true;

			return geometry;
		}
	}
}
