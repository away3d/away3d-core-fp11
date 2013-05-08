package away3d.core.base {
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * The SubGeometry class is a collections of geometric data that describes a triangle mesh. It is owned by a
	 * Geometry instance, and wrapped by a SubMesh in the scene graph.
	 * Several SubGeometries are grouped so they can be rendered with different materials, but still represent a single
	 * object.
	 *
	 * @see away3d.core.base.Geometry
	 * @see away3d.core.base.SubMesh
	 */
	public class SubGeometry extends SubGeometryBase implements ISubGeometry
	{
		// raw data:
		protected var _uvs : Vector.<Number>;
		protected var _secondaryUvs : Vector.<Number>;
		protected var _vertexNormals : Vector.<Number>;
		protected var _vertexTangents : Vector.<Number>;

		protected var _verticesInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _uvsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _secondaryUvsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _normalsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _tangentsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);

		// buffers:
		protected var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _uvBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _secondaryUvBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _vertexNormalBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _vertexTangentBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);

		// buffer dirty flags, per context:
		protected var _vertexBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _uvBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _secondaryUvBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _vertexNormalBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _vertexTangentBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);

		protected var _numVertices : uint;


		/**
		 * Creates a new SubGeometry object.
		 */
		public function SubGeometry()
		{
		}

		/**
		 * The total amount of vertices in the SubGeometry.
		 */
		public function get numVertices() : uint
		{
			return _numVertices;
		}

		/**
		 * @inheritDoc
		 */
		public function activateVertexBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;
			if (!_vertexBuffer[contextIndex] || _vertexBufferContext[contextIndex] != context) {
				_vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 3);
				_vertexBufferContext[contextIndex] = context;
				_verticesInvalid[contextIndex] = true;
 			}
			if (_verticesInvalid[contextIndex]) {
				_vertexBuffer[contextIndex].uploadFromVector(_vertexData, 0, _numVertices);
				_verticesInvalid[contextIndex] = false;
			}

			context.setVertexBufferAt(index, _vertexBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_3);
		}

		/**
		 * @inheritDoc
		 */
		public function activateUVBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (_autoGenerateUVs && _uvsDirty)
				_uvs = updateDummyUVs(_uvs);

			if (!_uvBuffer[contextIndex] || _uvBufferContext[contextIndex] != context) {
				_uvBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 2);
				_uvBufferContext[contextIndex] = context;
				_uvsInvalid[contextIndex] = true;
 			}
			if (_uvsInvalid[contextIndex]) {
				_uvBuffer[contextIndex].uploadFromVector(_uvs, 0, _numVertices);
				_uvsInvalid[contextIndex] = false;
			}

			context.setVertexBufferAt(index, _uvBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_2);
		}

		/**
		 * @inheritDoc
		 */
		public function activateSecondaryUVBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (!_secondaryUvBuffer[contextIndex] || _secondaryUvBufferContext[contextIndex] != context) {
				_secondaryUvBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 2);
				_secondaryUvBufferContext[contextIndex] = context;
				_secondaryUvsInvalid[contextIndex] = true;
 			}
			if (_secondaryUvsInvalid[contextIndex]) {
				_secondaryUvBuffer[contextIndex].uploadFromVector(_secondaryUvs, 0, _numVertices);
				_secondaryUvsInvalid[contextIndex] = false;
			}

			context.setVertexBufferAt(index, _secondaryUvBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_2);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex normals.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex normals.
		 */
		public function activateVertexNormalBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (_autoDeriveVertexNormals && _vertexNormalsDirty)
				_vertexNormals = updateVertexNormals(_vertexNormals);

			if (!_vertexNormalBuffer[contextIndex] || _vertexNormalBufferContext[contextIndex] != context) {
				_vertexNormalBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 3);
				_vertexNormalBufferContext[contextIndex] = context;
				_normalsInvalid[contextIndex] = true;
 			}
			if (_normalsInvalid[contextIndex]) {
				_vertexNormalBuffer[contextIndex].uploadFromVector(_vertexNormals, 0, _numVertices);
				_normalsInvalid[contextIndex] = false;
			}

			context.setVertexBufferAt(index, _vertexNormalBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_3);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex tangents.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex tangents.
		 */
		public function activateVertexTangentBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (_vertexTangentsDirty)
				_vertexTangents = updateVertexTangents(_vertexTangents);

			if (!_vertexTangentBuffer[contextIndex] || _vertexTangentBufferContext[contextIndex] != context) {
				_vertexTangentBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 3);
				_vertexTangentBufferContext[contextIndex] = context;
				_tangentsInvalid[contextIndex] = true;
 			}
			if (_tangentsInvalid[contextIndex]) {
				_vertexTangentBuffer[contextIndex].uploadFromVector(_vertexTangents, 0, _numVertices);
				_tangentsInvalid[contextIndex] = false;
			}
			context.setVertexBufferAt(index, _vertexTangentBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_3);
		}

		override public function applyTransformation(transform:Matrix3D):void
		{
			super.applyTransformation(transform);
			invalidateBuffers(_verticesInvalid);
			invalidateBuffers(_normalsInvalid);
			invalidateBuffers(_tangentsInvalid);
		}

		/**
		 * Clones the current object
		 * @return An exact duplicate of the current object.
		 */
		public function clone() : ISubGeometry
		{
			var clone : SubGeometry = new SubGeometry();
			clone.updateVertexData(_vertexData.concat());
			clone.updateUVData(_uvs.concat());
			clone.updateIndexData(_indices.concat());
			if (_secondaryUvs) clone.updateSecondaryUVData(_secondaryUvs.concat());
			if (!_autoDeriveVertexNormals) clone.updateVertexNormalData(_vertexNormals.concat());
			if (!_autoDeriveVertexTangents) clone.updateVertexTangentData(_vertexTangents.concat());
			return clone;
		}

		/**
		 * @inheritDoc
		 */
		override public function scale(scale : Number):void
		{
			super.scale(scale);
			invalidateBuffers(_verticesInvalid);
		}

		/**
		 * @inheritDoc
		 */
		override public function scaleUV(scaleU : Number = 1, scaleV : Number = 1):void
		{
			super.scaleUV(scaleU, scaleV);
			invalidateBuffers(_uvsInvalid);
		}

		/**
		 * Clears all resources used by the SubGeometry object.
		 */
		override public function dispose() : void
		{
			super.dispose();
			disposeAllVertexBuffers();
			_vertexBuffer = null;
			_vertexNormalBuffer = null;
			_uvBuffer = null;
			_secondaryUvBuffer = null;
			_vertexTangentBuffer = null;
			_indexBuffer = null;
			_uvs = null;
			_secondaryUvs = null;
			_vertexNormals = null;
			_vertexTangents = null;
			_vertexBufferContext = null;
			_uvBufferContext = null;
			_secondaryUvBufferContext = null;
			_vertexNormalBufferContext = null;
			_vertexTangentBufferContext = null;
		}

		protected function disposeAllVertexBuffers() : void
		{
			disposeVertexBuffers(_vertexBuffer);
			disposeVertexBuffers(_vertexNormalBuffer);
			disposeVertexBuffers(_uvBuffer);
			disposeVertexBuffers(_secondaryUvBuffer);
			disposeVertexBuffers(_vertexTangentBuffer);
		}

		/**
		 * The raw vertex position data.
		 */
		override public function get vertexData() : Vector.<Number>
		{
			return _vertexData;
		}

		override public function get vertexPositionData():Vector.<Number> {
			return _vertexData;
		}

		/**
		 * Updates the vertex data of the SubGeometry.
		 * @param vertices The new vertex data to upload.
		 */
		public function updateVertexData(vertices : Vector.<Number>) : void
		{
			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;

			_faceNormalsDirty = true;

			_vertexData = vertices;
			var numVertices : int = vertices.length / 3;
			if (numVertices != _numVertices) disposeAllVertexBuffers();
			_numVertices = numVertices;

            invalidateBuffers(_verticesInvalid);

			invalidateBounds();
		}

		/**
		 * The raw texture coordinate data.
		 */
		override public function get UVData() : Vector.<Number>
		{
			if (_uvsDirty && _autoGenerateUVs)
				_uvs = updateDummyUVs(_uvs);
			return _uvs;
		}

		public function get secondaryUVData() : Vector.<Number>
		{
			return _secondaryUvs;
		}

		/**
		 * Updates the uv coordinates of the SubGeometry.
		 * @param uvs The uv coordinates to upload.
		 */
		public function updateUVData(uvs : Vector.<Number>) : void
		{
			// normals don't get dirty from this
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
			_faceTangentsDirty = true;
			_uvs = uvs;
			invalidateBuffers(_uvsInvalid);
		}

		public function updateSecondaryUVData(uvs : Vector.<Number>) : void
		{
			_secondaryUvs = uvs;
			invalidateBuffers(_secondaryUvsInvalid);
		}

		/**
		 * The raw vertex normal data.
		 */
		override public function get vertexNormalData() : Vector.<Number>
		{
			if (_autoDeriveVertexNormals && _vertexNormalsDirty) _vertexNormals = updateVertexNormals(_vertexNormals);
			return _vertexNormals;
		}

		/**
		 * Updates the vertex normals of the SubGeometry. When updating the vertex normals like this,
		 * autoDeriveVertexNormals will be set to false and vertex normals will no longer be calculated automatically.
		 * @param vertexNormals The vertex normals to upload.
		 */
		public function updateVertexNormalData(vertexNormals : Vector.<Number>) : void
		{
			_vertexNormalsDirty = false;
			_autoDeriveVertexNormals = (vertexNormals == null);
			_vertexNormals = vertexNormals;
			invalidateBuffers(_normalsInvalid);
		}

		/**
		 * The raw vertex tangent data.
		 *
		 * @private
		 */
		override public function get vertexTangentData() : Vector.<Number>
		{
			if (_autoDeriveVertexTangents && _vertexTangentsDirty) _vertexTangents = updateVertexTangents(_vertexTangents);
			return _vertexTangents;
		}

		/**
		 * Updates the vertex tangents of the SubGeometry. When updating the vertex tangents like this,
		 * autoDeriveVertexTangents will be set to false and vertex tangents will no longer be calculated automatically.
		 * @param vertexTangents The vertex tangents to upload.
		 */
		public function updateVertexTangentData(vertexTangents : Vector.<Number>) : void
		{
			_vertexTangentsDirty = false;
			_autoDeriveVertexTangents = (vertexTangents == null);
			_vertexTangents = vertexTangents;
			invalidateBuffers(_tangentsInvalid);
		}
		
		public function fromVectors(vertices : Vector.<Number>, uvs : Vector.<Number>, normals : Vector.<Number>, tangents : Vector.<Number>) : void
		{
			updateVertexData(vertices);
			updateUVData(uvs);
			updateVertexNormalData(normals);
			updateVertexTangentData(tangents);
		}

		override protected function updateVertexNormals(target : Vector.<Number>) : Vector.<Number>
		{
			invalidateBuffers(_normalsInvalid);
			return super.updateVertexNormals(target);
		}

		override protected function updateVertexTangents(target : Vector.<Number>) : Vector.<Number>
		{
			if (_vertexNormalsDirty) _vertexNormals = updateVertexNormals(_vertexNormals);
			invalidateBuffers(_tangentsInvalid);
			return super.updateVertexTangents(target);
		}


		override protected function updateDummyUVs(target : Vector.<Number>) : Vector.<Number>
		{
			invalidateBuffers(_uvsInvalid);
			return super.updateDummyUVs(target);
		}

		protected function disposeForStage3D(stage3DProxy : Stage3DProxy) : void
		{
			var index : int = stage3DProxy._stage3DIndex;
			if (_vertexBuffer[index]) {
				_vertexBuffer[index].dispose();
				_vertexBuffer[index] = null;
			}
			if (_uvBuffer[index]) {
				_uvBuffer[index].dispose();
				_uvBuffer[index] = null;
			}
			if (_secondaryUvBuffer[index]) {
				_secondaryUvBuffer[index].dispose();
				_secondaryUvBuffer[index] = null;
			}
			if (_vertexNormalBuffer[index]) {
				_vertexNormalBuffer[index].dispose();
				_vertexNormalBuffer[index] = null;
			}
			if (_vertexTangentBuffer[index]) {
				_vertexTangentBuffer[index].dispose();
				_vertexTangentBuffer[index] = null;
			}
			if (_indexBuffer[index]) {
				_indexBuffer[index].dispose();
				_indexBuffer[index] = null;
			}
		}

		override public function get vertexStride() : uint
		{
			return 3;
		}

		override public function get vertexTangentStride() : uint
		{
			return 3;
		}

		override public function get vertexNormalStride() : uint
		{
			return 3;
		}

		override public function get UVStride() : uint
		{
			return 2;
		}

		public function get secondaryUVStride() : uint
		{
			return 2;
		}

		override public function get vertexOffset() : int
		{
			return 0;
		}

		override public function get vertexNormalOffset() : int
		{
			return 0;
		}

		override public function get vertexTangentOffset() : int
		{
			return 0;
		}

		override public function get UVOffset() : int
		{
			return 0;
		}

		public function get secondaryUVOffset() : int
		{
			return 0;
		}

		public function cloneWithSeperateBuffers() : SubGeometry
		{
			return SubGeometry(clone());
		}
	}
}