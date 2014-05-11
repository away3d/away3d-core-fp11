package away3d.prefabs {
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.LineSubGeometry;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.entities.Mesh;
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.AssetType;
	import away3d.materials.IMaterial;

	use namespace arcane;
	public class PrimitivePrefabBase extends PrefabBase {

		protected var _geomDirty:Boolean = true;
		protected var _uvDirty:Boolean = true;

		private var _subGeometry:SubGeometryBase;
		private var _material:IMaterial;
		private var _geometry:Geometry;
		private var _geometryType:String;
		private var _geometryTypeDirty:Boolean = true;

		/**
		 *
		 */
		override public function get assetType():String
		{
			return AssetType.PRIMITIVE_PREFAB;
		}

		override public function dispose():void {
			_geometry.dispose();
		}

		/**
		 * Creates a new PrimitiveBase object.
		 * @param material The material with which to render the object
		 */
		public function PrimitivePrefabBase(material:IMaterial = null, geometryType:String = GeometryType.TRIANGLES)
		{
			_geometry = new Geometry();
			_material = material;
			_geometryType = geometryType;
		}

		public function get geometryType():String {
			return _geometryType;
		}

		public function set geometryType(value:String):void {
			if(_geometryType == value) return;
			_geometryType = value;
			invalidateGeometryType();
		}

		public function get geometry():Geometry
		{
			validate();
			return _geometry;
		}

		/**
		 * The material with which to render the primitive.
		 */
		public function get material():IMaterial
		{
			return _material;
		}

		public function set material(value:IMaterial):void
		{
			if (value == _material)
				return;

			_material = value;

			var len:Number = _objects.length;
			for (var i:Number = 0; i < len; i++){
				(_objects[i] as Mesh).material = _material;
			}
		}
		/**
		 * Builds the primitive's geometry when invalid. This method should not be called directly. The calling should
		 * be triggered by the invalidateGeometry method (and in turn by updateGeometry).
		 */
		protected function buildGeometry(target:SubGeometryBase, geometryType:String):void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Builds the primitive's uv coordinates when invalid. This method should not be called directly. The calling
		 * should be triggered by the invalidateUVs method (and in turn by updateUVs).
		 */
		protected function buildUVs(target:SubGeometryBase, geometryType:String):void
		{
			throw new AbstractMethodError();
		}

		/**
		 * Invalidates the primitive's geometry type, causing it to be updated when requested.
		 */
		public function invalidateGeometryType():void
		{
			_geometryTypeDirty = true;
			_geomDirty = true;
			_uvDirty = true;
		}

		/**
		 * Invalidates the primitive's geometry, causing it to be updated when requested.
		 */
		protected function invalidateGeometry():void
		{
			_geomDirty = true;
		}

		/**
		 * Invalidates the primitive's uv coordinates, causing them to be updated when requested.
		 */
		protected function invalidateUVs():void
		{
			_uvDirty = true;
		}

		/**
		 * Updates the subgeometry when invalid.
		 */
		private function updateGeometryType():void
		{
			//remove any existing sub geometry
			if (_subGeometry)
				_geometry.removeSubGeometry(_subGeometry);

			if (_geometryType == GeometryType.TRIANGLES) {
				var triangleGeometry:TriangleSubGeometry = new TriangleSubGeometry(true);
				triangleGeometry.autoDeriveNormals = false;
				triangleGeometry.autoDeriveTangents = false;
				triangleGeometry.autoDeriveUVs = false;
				_geometry.addSubGeometry(triangleGeometry);
				_subGeometry = triangleGeometry;
			} else if (_geometryType == GeometryType.LINE) {
				_subGeometry = new LineSubGeometry()
				_geometry.addSubGeometry(_subGeometry);
			}

			_geometryTypeDirty = false;
		}


		/**
		 * Updates the geometry when invalid.
		 */
		private function updateGeometry():void
		{
			buildGeometry(_subGeometry, _geometryType);
			_geomDirty = false;
		}

		/**
		 * Updates the uv coordinates when invalid.
		 */
		private function updateUVs():void
		{
			buildUVs(_subGeometry, _geometryType);
			_uvDirty = false;
		}

		override arcane function validate():void
		{
			if (_geometryTypeDirty)
				updateGeometryType();

			if (_geomDirty)
				updateGeometry();

			if (_uvDirty)
				updateUVs();
		}


		override protected function createObject():Object3D
		{
			var mesh:Mesh = new Mesh(_geometry, _material);
			mesh.sourcePrefab = this;
			return mesh;
		}
	}
}
