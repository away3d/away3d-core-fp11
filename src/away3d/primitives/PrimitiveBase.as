package away3d.primitives
{
	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.base.Geometry;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.debug.Debug;
	import away3d.entities.Mesh;
	import away3d.errors.AbstractMethodError;
	import away3d.materials.MaterialBase;

	/**
	 * PrimitiveBase is an abstract base class for mesh primitives, which are prebuilt simple meshes.
	 */
	public class PrimitiveBase extends Geometry
	{
		protected var _geomDirty : Boolean = true;
		protected var _uvDirty : Boolean = true;

		private var _subGeometry : SubGeometry;

		/**
		 * Creates a new PrimitiveBase object.
		 * @param material The material with which to render the object
		 */
		public function PrimitiveBase()
		{
			_subGeometry = new SubGeometry();
			addSubGeometry(_subGeometry);
		}

		/**
		 * @inheritDoc
		 */
		override public function get subGeometries():Vector.<SubGeometry>
		{
			if (_geomDirty) updateGeometry();
			if (_uvDirty) updateUVs();

			return super.subGeometries;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone() : Geometry
		{
			if (_geomDirty) updateGeometry();
			if (_uvDirty) updateUVs();

			return super.clone();
		}

		/**
		 * Builds the primitive's geometry when invalid. This method should not be called directly. The calling should
		 * be triggered by the invalidateGeometry method (and in turn by updateGeometry).
		 */
		protected function buildGeometry(target : SubGeometry) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Builds the primitive's uv coordinates when invalid. This method should not be called directly. The calling
		 * should be triggered by the invalidateUVs method (and in turn by updateUVs).
		 */
		protected function buildUVs(target : SubGeometry) : void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Invalidates the primitive's geometry, causing it to be updated when requested.
		 */
		protected function invalidateGeometry() : void
		{
			_geomDirty = true;
		}

		/**
		 * Invalidates the primitive's uv coordinates, causing them to be updated when requested.
		 */
		protected function invalidateUVs() : void
		{
			_uvDirty = true;
		}

		/**
		 * Updates the geometry when invalid.
		 */
		private function updateGeometry() : void
		{
			buildGeometry(_subGeometry);
			_geomDirty = false;
		}

		/**
		 * Updates the uv coordinates when invalid.
		 */
		private function updateUVs() : void
		{
			buildUVs(_subGeometry);
			_uvDirty = false;
		}
	}
}