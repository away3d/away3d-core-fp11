package away3d.core.pool {
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.entities.SkyBox;

	public class SkyBoxRenderable extends RenderableBase {
		/**
		 *
		 */
		public static const id:String = "skybox";

		/**
		 *
		 */
		private static var _geometry:TriangleSubGeometry;

		/**
		 * //TODO
		 *
		 * @param pool
		 * @param skybox
		 */
		public function SkyBoxRenderable(pool:RenderablePool, skybox:SkyBox)
		{
			super(pool, skybox, skybox);
		}

		/**
		 * //TODO
		 *
		 * @returns {away.base.TriangleSubGeometry}
		 * @private
		 */
		override protected function getSubGeometry():SubGeometryBase
		{
			var geometry:TriangleSubGeometry = _geometry;

			if (!geometry) {
				geometry = _geometry = new TriangleSubGeometry(true);
				geometry.autoDeriveNormals = false;
				geometry.autoDeriveTangents = false;
				geometry.updateIndices(Vector.<uint>([0, 1, 2, 2, 3, 0, 6, 5, 4, 4, 7, 6, 2, 6, 7, 7, 3, 2, 4, 5, 1, 1, 0, 4, 4, 0, 3, 3, 7, 4, 2, 1, 5, 5, 6, 2]));
				geometry.updatePositions(Vector.<Number>([-1, 1, -1, 1, 1, -1, 1, 1, 1, -1, 1, 1, -1, -1, -1, 1, -1, -1, 1, -1, 1, -1, -1, 1]));
			}

			_vertexDataDirty[TriangleSubGeometry.POSITION_DATA] = true;

			return geometry;
		}
	}
}
