package away3d.core.base {
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.events.SubGeometryEvent;
	import away3d.library.assets.NamedAssetBase;

	import flash.geom.Matrix3D;

	use namespace  arcane;

	public class SubGeometryBase extends NamedAssetBase {
		public static const VERTEX_DATA:String = "vertices";

		protected var _strideOffsetDirty:Boolean = true;
		protected var _indices:Vector.<uint>;
		protected var _vertices:Vector.<Number>;
		protected var _numVertices:Number;
		protected var _concatenateArrays:Boolean = true;
		protected var _subMeshClass:Class;
		protected var _stride:Object = {};
		protected var _offset:Object = {};

		private var _numIndices:Number;
		private var _numTriangles:Number;
		private var _indicesUpdated:SubGeometryEvent;

		/**
		 * The Geometry object that 'owns' this TriangleSubGeometry object.
		 *
		 * @private
		 */
		public var parentGeometry:Geometry;

		protected function updateStrideOffset():void {
			throw new AbstractMethodError();
		}

		public function get subMeshClass():Class {
			return _subMeshClass;
		}

		/**
		 *
		 */
		public function get concatenateArrays():Boolean {
			return _concatenateArrays;
		}

		public function set concatenateArrays(value:Boolean):void {
			if (_concatenateArrays == value)
				return;

			_concatenateArrays = value;

			_strideOffsetDirty = true;

			if (value)
				notifyVerticesUpdate();
		}

		/**
		 * The raw index data that define the faces.
		 */
		public function get indices():Vector.<uint> {
			return _indices;
		}

		/**
		 *
		 */
		public function get vertices():Vector.<Number> {
			updateVertices();

			return _vertices;
		}

		/**
		 * The total amount of triangles in the TriangleSubGeometry.
		 */
		public function get numTriangles():Number {
			return _numTriangles;
		}

		public function get numVertices():Number {
			return _numVertices;
		}

		/**
		 *
		 */
		public function SubGeometryBase(concatenatedArrays:Boolean):void {
			_concatenateArrays = concatenatedArrays;
		}

		/**
		 *
		 */
		public function getStride(dataType:String):uint {
			if (_strideOffsetDirty)
				updateStrideOffset();

			return _stride[dataType];
		}

		/**
		 *
		 */
		public function getOffset(dataType:String):uint {
			if (_strideOffsetDirty)
				updateStrideOffset();

			return _offset[dataType];
		}

		public function updateVertices():void {
			throw new AbstractMethodError();
		}

		/**
		 *
		 */
		override public function dispose():void {
			_indices = null;
			_vertices = null;
		}

		/**
		 * Updates the face indices of the TriangleSubGeometry.
		 *
		 * @param indices The face indices to upload.
		 */
		public function updateIndices(indices:Vector.<uint>):void {
			_indices = indices;
			_numIndices = indices.length;

			_numTriangles = _numIndices / 3;

			notifyIndicesUpdate();
		}

		/**
		 * @protected
		 */
		protected function invalidateBounds():void {
			if (parentGeometry)
				parentGeometry.invalidateBounds(this);
		}


		/**
		 * Clones the current object
		 * @return An exact duplicate of the current object.
		 */
		public function clone():SubGeometryBase {
			throw new AbstractMethodError();
		}

		public function applyTransformation(transform:Matrix3D):void {

		}

		/**
		 * Scales the geometry.
		 * @param scale The amount by which to scale.
		 */
		public function scale(scale:Number):void {

		}

		public function scaleUV(scaleU:Number = 1, scaleV:Number = 1):void {

		}

		public function getBoundingPositions():Vector.<Number> {
			throw new AbstractMethodError();
		}

		private function notifyIndicesUpdate():void {
			if (!_indicesUpdated)
				_indicesUpdated = new SubGeometryEvent(SubGeometryEvent.INDICES_UPDATED);

			dispatchEvent(_indicesUpdated);
		}

		protected function notifyVerticesUpdate():void {
			throw new AbstractMethodError();
		}
	}
}
