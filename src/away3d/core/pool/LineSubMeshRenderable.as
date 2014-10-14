package away3d.core.pool {
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.LineSubGeometry;
	import away3d.core.base.LineSubMesh;
	import away3d.core.base.SubGeometryBase;

	public class LineSubMeshRenderable extends RenderableBase {
		/**
		 *
		 */
		public static const id:String = "linesubmesh";

		/**
		 *
		 */
		public var subMesh:LineSubMesh;

		/**
		 * //TODO
		 *
		 * @param pool
		 * @param subMesh
		 * @param level
		 * @param dataOffset
		 */
		public function LineSubMeshRenderable(pool:RenderablePool, subMesh:LineSubMesh, level:Number = 0, indexOffset:Number = 0)
		{
			super(pool, subMesh.parentMesh, subMesh, level, indexOffset);

			this.subMesh = subMesh;
		}

		/**
		 * //TODO
		 *
		 * @returns {base.LineSubGeometry}
		 * @protected
		 */
		override protected function getSubGeometry():SubGeometryBase
		{
			var subGeometry:LineSubGeometry = subMesh.subGeometry as LineSubGeometry;

			_vertexDataDirty[LineSubGeometry.START_POSITION_DATA] = true;
			_vertexDataDirty[LineSubGeometry.END_POSITION_DATA] = true;

			if (subGeometry.thickness)
				_vertexDataDirty[LineSubGeometry.THICKNESS_DATA] = true;

			if (subGeometry.startColors)
				_vertexDataDirty[LineSubGeometry.COLOR_DATA] = true;

			return subGeometry;
		}

		/**
		 * //TODO
		 *
		 * @param pool
		 * @param materialOwner
		 * @param level
		 * @param indexOffset
		 * @returns {away.pool.LineSubMeshRenderable}
		 * @private
		 */
		override protected function getOverflowRenderable(pool:RenderablePool, materialOwner:IMaterialOwner, level:Number, indexOffset:Number):RenderableBase
		{
			return new LineSubMeshRenderable(pool, materialOwner as LineSubMesh, level, indexOffset);
		}
	}
}
