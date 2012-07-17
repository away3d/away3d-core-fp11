package away3d.primitives
{
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.errors.AbstractMethodError;
	
	import flash.geom.Matrix3D;
	
	use namespace arcane;

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
		 * @inheritDoc
		 */
		override public function scale(scale:Number):void
		{
			if (_geomDirty) updateGeometry();

			super.scale(scale);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function scaleUV(scaleU:Number=1, scaleV:Number=1):void
		{
			if (_uvDirty) updateUVs();
			
			super.scaleUV(scaleU, scaleV);
		}
		
		/**
		 * @inheritDoc
		*/
		override public function applyTransformation(transform:Matrix3D):void
		{
			if (_geomDirty) updateGeometry();
			super.applyTransformation(transform);
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
		
		
		override arcane function validate() : void
		{
			if (_geomDirty) updateGeometry();
			if (_uvDirty) updateUVs();
		}
	}
}