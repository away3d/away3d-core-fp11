package away3d.core.pool {
	import away3d.core.TriangleSubMesh;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;

	import flash.display3D.Context3DVertexBufferFormat;

	public class TriangleSubMeshRenderable extends RenderableBase {
		/**
		 *
		 */
		public static var id:String = "trianglesubmesh";

		/**
		 *
		 */
		public var subMesh:TriangleSubMesh;

		/**
		 * //TODO
		 *
		 * @param pool
		 * @param subMesh
		 * @param level
		 * @param indexOffset
		 */
		public function TriangleSubMeshRenderable(pool:RenderablePool, subMesh:TriangleSubMesh, level:Number = 0, indexOffset:Number = 0) {
			super(pool, subMesh.parentMesh, subMesh, level, indexOffset);

			this.subMesh = subMesh;
		}

		/**
		 *
		 * @returns {away.base.SubGeometryBase}
		 * @protected
		 */
		override protected function getSubGeometry():SubGeometryBase {
			var subGeometry:TriangleSubGeometry;

			if (subMesh.animator) {
				subGeometry = subMesh.animator.getRenderableSubGeometry(this, subMesh.subGeometry) as TriangleSubGeometry;
			}
			else {
				subGeometry = subMesh.subGeometry as TriangleSubGeometry;
			}
			_vertexDataDirty[TriangleSubGeometry.POSITION_DATA] = true;

			if (subGeometry.vertexNormals)
				_vertexDataDirty[TriangleSubGeometry.NORMAL_DATA] = true;

			if (subGeometry.vertexTangents)
				_vertexDataDirty[TriangleSubGeometry.TANGENT_DATA] = true;

			if (subGeometry.uvs)
				_vertexDataDirty[TriangleSubGeometry.UV_DATA] = true;

			if (subGeometry.secondaryUVs)
				_vertexDataDirty[TriangleSubGeometry.SECONDARY_UV_DATA] = true;

			if (subGeometry.jointIndices)
				_vertexDataDirty[TriangleSubGeometry.JOINT_INDEX_DATA] = true;

			if (subGeometry.jointWeights)
				_vertexDataDirty[TriangleSubGeometry.JOINT_WEIGHT_DATA] = true;

			switch (subGeometry.jointsPerVertex) {
				case 1:
					JOINT_INDEX_FORMAT = JOINT_WEIGHT_FORMAT = Context3DVertexBufferFormat.FLOAT_1;
					break;
				case 2:
					JOINT_INDEX_FORMAT = JOINT_WEIGHT_FORMAT = Context3DVertexBufferFormat.FLOAT_2;
					break;
				case 3:
					JOINT_INDEX_FORMAT = JOINT_WEIGHT_FORMAT = Context3DVertexBufferFormat.FLOAT_3;
					break;
				case 4:
					JOINT_INDEX_FORMAT = JOINT_WEIGHT_FORMAT = Context3DVertexBufferFormat.FLOAT_4;
					break;
				default:
			}

			return subGeometry;
		}

		/**
		 * //TODO
		 *
		 * @param pool
		 * @param materialOwner
		 * @param level
		 * @param indexOffset
		 * @returns {away.pool.TriangleSubMeshRenderable}
		 * @protected
		 */
		override public function getOverflowRenderable(pool:RenderablePool, materialOwner:IMaterialOwner, level:Number, indexOffset:Number):RenderableBase {
			return new TriangleSubMeshRenderable(pool, materialOwner as TriangleSubMesh, level, indexOffset);
		}
	}
}
