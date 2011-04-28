package away3d.core.base
{
	import away3d.arcane;
	import away3d.animators.data.AnimationBase;

	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;

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
	public class SubGeometry
	{
		private var _parentGeometry : Geometry;

		// raw data:
		protected var _vertices : Vector.<Number>;
		protected var _uvs : Vector.<Number>;
		protected var _secondaryUvs : Vector.<Number>;
		protected var _vertexNormals : Vector.<Number>;
		protected var _vertexTangents : Vector.<Number>;
		protected var _indices : Vector.<uint>;
		protected var _faceNormalsData : Vector.<Number>;
		protected var _faceWeights : Vector.<Number>;
		protected var _faceTangents : Vector.<Number>;

		// buffers:
		protected var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _uvBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _secondaryUvBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _vertexNormalBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _vertexTangentBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _indexBuffer : Vector.<IndexBuffer3D> = new Vector.<IndexBuffer3D>(8);

		private var _autoDeriveVertexNormals : Boolean = true;
		private var _autoDeriveVertexTangents : Boolean = true;
		private var _useFaceWeights : Boolean = false;
		protected var _maxIndex : int = -1;

		// raw data dirty flags:
		protected var _faceNormalsDirty : Boolean = true;
		protected var _faceTangentsDirty : Boolean = true;
		protected var _vertexNormalsDirty : Boolean = true;
		protected var _vertexTangentsDirty : Boolean = true;

		// buffer dirty flags, per context:
		protected var _vertexBufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);
		protected var _uvBufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);
		protected var _secondaryUvBufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);
		protected var _indexBufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);
		protected var _vertexNormalBufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);
		protected var _vertexTangentBufferDirty : Vector.<Boolean> = new Vector.<Boolean>(8);

		protected var _numVertices : uint;
		protected var _numIndices : uint;
		protected var _numTriangles : uint;

		/**
		 * Creates a new SubGeometry object.
		 */
		public function SubGeometry()
		{
		}

		/**
		 * The animation that affects the geometry.
		 */
		public function get animation() : AnimationBase
		{
			return _parentGeometry._animation;
		}

		/**
		 * The total amount of vertices in the SubGeometry.
		 */
		public function get numVertices() : uint
		{
			return _numVertices;
		}

		/**
		 * The total amount of triangles in the SubGeometry.
		 */
		public function get numTriangles() : uint
		{
			return _numTriangles;
		}

		/**
		 * True if the vertex normals should be derived from the geometry, false if the vertex normals are set
		 * explicitly.
		 */
		public function get autoDeriveVertexNormals() : Boolean
		{
			return _autoDeriveVertexNormals;
		}

		public function set autoDeriveVertexNormals(value : Boolean) : void
		{
			_autoDeriveVertexNormals = value;

			if (!value)
				_vertexNormalsDirty = false;
		}

		/**
		 * Indicates whether or not to take the size of faces into account when auto-deriving vertex normals and tangents.
		 */
		public function get useFaceWeights() : Boolean
		{
			return _useFaceWeights;
		}

		public function set useFaceWeights(value : Boolean) : void
		{
			_useFaceWeights = value;
			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
			_faceNormalsDirty = true;
		}

		/**
		 * True if the vertex tangents should be derived from the geometry, false if the vertex normals are set
		 * explicitly.
		 */
		public function get autoDeriveVertexTangents() : Boolean
		{
			return _autoDeriveVertexTangents;
		}

		public function set autoDeriveVertexTangents(value : Boolean) : void
		{
			_autoDeriveVertexTangents = value;

			if (!value)
				_vertexTangentsDirty = false;
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex positions.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex positions.
		 */
		public function getVertexBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;

			if (_vertexBufferDirty[contextIndex] || !_vertexBuffer[contextIndex]) {
				VertexBuffer3D(_vertexBuffer[contextIndex] ||= context.createVertexBuffer(_numVertices, 3)).uploadFromVector(_vertices, 0, _numVertices);
				_vertexBufferDirty[contextIndex] = false;
			}

			return _vertexBuffer[contextIndex];
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains texture coordinates.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains texture coordinates.
		 */
		public function getUVBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;

			if (_uvBufferDirty[contextIndex] || !_uvBuffer[contextIndex]) {
				(_uvBuffer[contextIndex] ||= context.createVertexBuffer(_numVertices, 2)).uploadFromVector(_uvs, 0, _numVertices);
				_uvBufferDirty[contextIndex] = false;
			}

			return _uvBuffer[contextIndex];
		}

		public function getSecondaryUVBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;

			if (_secondaryUvBufferDirty[contextIndex] || !_secondaryUvBuffer[contextIndex]) {
				(_secondaryUvBuffer[contextIndex] ||= context.createVertexBuffer(_numVertices, 2)).uploadFromVector(_secondaryUvs, 0, _numVertices);
				_secondaryUvBufferDirty[contextIndex] = false;
			}

			return _secondaryUvBuffer[contextIndex];
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex normals.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex normals.
		 */
		public function getVertexNormalBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;

			if (_autoDeriveVertexNormals && _vertexNormalsDirty)
				updateVertexNormals();

			if (_vertexNormalBufferDirty[contextIndex] || !_vertexNormalBuffer[contextIndex]) {
				(_vertexNormalBuffer[contextIndex] ||= context.createVertexBuffer(_numVertices, 3)).uploadFromVector(_vertexNormals, 0, _numVertices);
				_vertexNormalBufferDirty[contextIndex] = false;
			}

			return _vertexNormalBuffer[contextIndex];
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex tangents.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex tangents.
		 */
		public function getVertexTangentBuffer(context : Context3D, contextIndex : uint) : VertexBuffer3D
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;

			if (_vertexTangentsDirty)
				updateVertexTangents();

			if (_vertexTangentBufferDirty[contextIndex] || !_vertexTangentBuffer[contextIndex]) {
				(_vertexTangentBuffer[contextIndex] ||= context.createVertexBuffer(_numVertices, 3)).uploadFromVector(_vertexTangents, 0, _numVertices);
				_vertexTangentBufferDirty[contextIndex] = false;
			}
			return _vertexTangentBuffer[contextIndex];
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains triangle indices.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains triangle indices.
		 */
		public function getIndexBuffer(context : Context3D, contextIndex : uint) : IndexBuffer3D
		{
			if (contextIndex > _maxIndex) _maxIndex = contextIndex;

			if (_indexBufferDirty[contextIndex] || !_indexBuffer[contextIndex]) {
				(_indexBuffer[contextIndex] ||= context.createIndexBuffer(_numIndices)).uploadFromVector(_indices, 0, _numIndices);
				_indexBufferDirty[contextIndex] = false;
			}

			return _indexBuffer[contextIndex];
		}

		/**
		 * Clones the current object
		 * @return An exact duplicate of the current object.
		 */
		public function clone() : SubGeometry
		{
			var clone : SubGeometry = new SubGeometry();
			clone.updateVertexData(_vertices.concat());
			clone.updateUVData(_uvs.concat());
			clone.updateSecondaryUVData(_secondaryUvs.concat());
			clone.updateIndexData(_indices.concat());
			if (!_autoDeriveVertexNormals) clone.updateVertexNormalData(_vertexNormals.concat());
			if (!_autoDeriveVertexTangents) clone.updateVertexTangentData(_vertexTangents.concat());
			return clone;
		}

		/**
		 * Scales the geometry.
		 * @param scale The amount by which to scale.
		 */
		public function scale(scale : Number):void
		{
			var len : uint = _vertices.length;
			for (var i : uint = 0; i < len; ++i)
				_vertices[i] *= scale;
			invalidateBuffers(_vertexBufferDirty);
		}

		/**
		 * Scales the uv coordinates.
		 * @param scale The amount by which to scale.
		 */
		public function scaleUV(scale : Number):void
		{
			var len : uint = _uvs.length;
			for (var i : uint = 0; i < len; ++i)
				_uvs[i] *= scale;
			invalidateBuffers(_uvBufferDirty);
		}

		/**
		 * Clears all resources used by the SubGeometry object.
		 */
		public function dispose() : void
		{
			disposeVertexBuffers(_vertexBuffer);
			disposeVertexBuffers(_vertexNormalBuffer);
			disposeVertexBuffers(_uvBuffer);
			disposeVertexBuffers(_secondaryUvBuffer);
			disposeVertexBuffers(_vertexTangentBuffer);
			disposeIndexBuffers(_indexBuffer);
		}

		/**
		 * The raw vertex position data.
		 */
		public function get vertexData() : Vector.<Number>
		{
			return _vertices;
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

			_vertices = vertices;
			_numVertices = vertices.length / 3;
            invalidateBuffers(_vertexBufferDirty);

			// todo: send out bounds invalid
		}

		/**
		 * The raw texture coordinate data.
		 */
		public function get UVData() : Vector.<Number>
		{
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
			invalidateBuffers(_uvBufferDirty);
		}

		public function updateSecondaryUVData(uvs : Vector.<Number>) : void
		{
			_secondaryUvs = uvs;
			invalidateBuffers(_secondaryUvBufferDirty);
		}

		/**
		 * The raw vertex normal data.
		 */
		public function get vertexNormalData() : Vector.<Number>
		{
			if (_autoDeriveVertexNormals && _vertexNormalsDirty) updateVertexNormals();
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
			invalidateBuffers(_vertexNormalBufferDirty);
		}

		/**
		 * The raw vertex tangent data.
		 *
		 * @private
		 */
		public function get vertexTangentData() : Vector.<Number>
		{
			if (_autoDeriveVertexTangents && _vertexTangentsDirty) updateVertexTangents();
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
			invalidateBuffers(_vertexTangentBufferDirty);
		}

		/**
		 * The raw index data that define the faces.
		 *
		 * @private
		 */
		public function get indexData() : Vector.<uint>
		{
			return _indices;
		}

		/**
		 * Updates the face indices of the SubGeometry.
		 * @param indices The face indices to upload.
		 */
		public function updateIndexData(indices : Vector.<uint>) : void
		{
			_indices = indices;
			_numIndices = indices.length;
			_numTriangles = _numIndices/3;
			invalidateBuffers(_indexBufferDirty);
			_faceNormalsDirty = true;

			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
		}

		/**
		 * The raw data of the face normals, in the same order as the faces are listed in the index list.
		 *
		 * @private
		 */
		arcane function get faceNormalsData() : Vector.<Number>
		{
			if (_faceNormalsDirty) updateFaceNormals();
			return _faceNormalsData;
		}

		/**
		 * The Geometry object that 'owns' this SubGeometry object.
		 *
		 * @private
		 */
		arcane function get parentGeometry() : Geometry
		{
			return _parentGeometry;
		}

		arcane function set parentGeometry(value : Geometry) : void
		{
			_parentGeometry = value;
		}

		/**
		 * Invalidates all buffers in a vector, causing them the update when they are first requested.
		 * @param buffers The vector of buffers to invalidate.
		 */
		protected function invalidateBuffers(buffers : Vector.<Boolean>) : void
		{
			for (var i : int = 0; i <= _maxIndex; ++i)
				buffers[i] = true;
		}

		/**
		 * Disposes all buffers in a given vector.
		 * @param buffers The vector of buffers to dispose.
		 */
		protected function disposeVertexBuffers(buffers : Vector.<VertexBuffer3D>) : void
		{
			for (var i : int = 0; i <= _maxIndex; ++i) {
				if (buffers[i]) buffers[i].dispose();
			}
		}

		/**
		 * Disposes all buffers in a given vector.
		 * @param buffers The vector of buffers to dispose.
		 */
		protected function disposeIndexBuffers(buffers : Vector.<IndexBuffer3D>) : void
		{
			for (var i : int = 0; i <= _maxIndex; ++i) {
				if (buffers[i]) buffers[i].dispose();
			}
		}

		/**
		 * Updates the vertex normals based on the geometry.
		 */
		private function updateVertexNormals() : void
		{
			if (_faceNormalsDirty)
				updateFaceNormals();

			var v1 : uint, v2 : uint, v3 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = _vertices.length;

			// reset, yo
			if (_vertexNormals) while (v1 < lenV) _vertexNormals[v1++] = 0.0;
			else _vertexNormals = new Vector.<Number>(_vertices.length, true);

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = 0; v2 = 1; v3 = 2;
			while (v1 < lenV) {
				var vx : Number = _vertexNormals[v1];
				var vy : Number = _vertexNormals[v2];
				var vz : Number = _vertexNormals[v3];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				_vertexNormals[v1] *= d;
				_vertexNormals[v2] *= d;
				_vertexNormals[v3] *= d;
				v1 += 3;
				v2 += 3;
				v3 += 3;
			}

			_vertexNormalsDirty = false;
			invalidateBuffers(_vertexNormalBufferDirty);
		}

		/**
		 * Updates the vertex tangents based on the geometry.
		 */
		private function updateVertexTangents() : void
		{
			if (_vertexNormalsDirty) updateVertexNormals();

			if (_faceTangentsDirty)
				updateFaceTangents();

			var v1 : uint, v2 : uint, v3 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = _vertices.length;

			if (_vertexTangents) while (v1 < lenV) _vertexTangents[v1++] = 0.0;
			else _vertexTangents = new Vector.<Number>(_vertices.length, true);

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = 0; v2 = 1; v3 = 2;
			while (v1 < lenV) {
				var vx : Number = _vertexTangents[v1];
				var vy : Number = _vertexTangents[v2];
				var vz : Number = _vertexTangents[v3];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				_vertexTangents[v1] *= d;
				_vertexTangents[v2] *= d;
				_vertexTangents[v3] *= d;
				v1 += 3;
				v2 += 3;
				v3 += 3;
			}

			_vertexTangentsDirty = false;
			invalidateBuffers(_vertexTangentBufferDirty);
		}

		/**
		 * Updates the normals for each face.
		 */
		private function updateFaceNormals() : void
		{
			var i : uint, j : uint, k : uint;
			var index : uint;
			var len : uint = _indices.length;
			var x1 : Number, x2 : Number, x3 : Number;
			var y1 : Number, y2 : Number, y3 : Number;
			var z1 : Number, z2 : Number, z3 : Number;
			var dx1 : Number, dy1 : Number, dz1 : Number;
			var dx2 : Number, dy2 : Number, dz2 : Number;
			var cx : Number, cy : Number, cz : Number;
			var d : Number;

			_faceNormalsData ||= new Vector.<Number>(len, true);
			if (_useFaceWeights) _faceWeights ||= new Vector.<Number>(len/3, true);

			while (i < len) {
				index = _indices[i++]*3;
				x1 = _vertices[index++];
				y1 = _vertices[index++];
				z1 = _vertices[index];
				index = _indices[i++]*3;
				x2 = _vertices[index++];
				y2 = _vertices[index++];
				z2 = _vertices[index];
				index = _indices[i++]*3;
				x3 = _vertices[index++];
				y3 = _vertices[index++];
				z3 = _vertices[index];
				dx1 = x3-x1;
				dy1 = y3-y1;
				dz1 = z3-z1;
				dx2 = x2-x1;
				dy2 = y2-y1;
				dz2 = z2-z1;
				cx = dz1*dy2 - dy1*dz2;
				cy = dx1*dz2 - dz1*dx2;
				cz = dy1*dx2 - dx1*dy2;
				d = Math.sqrt(cx*cx+cy*cy+cz*cz);
				// length of cross product = 2*triangle area
				if (_useFaceWeights) {
					var w : Number = d*10000;
					if (w < 1) w = 1;
					_faceWeights[k++] = w;
				}
				d = 1/d;
				_faceNormalsData[j++] = cx*d;
				_faceNormalsData[j++] = cy*d;
				_faceNormalsData[j++] = cz*d;
			}

			_faceNormalsDirty = false;
			_faceTangentsDirty = true;
		}

		/**
		 * Updates the tangents for each face.
		 */
		private function updateFaceTangents() : void
		{
			var i : uint, j : uint;
			var index1 : uint, index2 : uint, index3 : uint;
			var len : uint = _indices.length;
			var ui : uint, vi : uint;
			var v0 : Number;
			var dv1 : Number, dv2 : Number;
			var denom : Number;
			var x0 : Number, y0 : Number, z0 : Number;
			var dx1 : Number, dy1 : Number, dz1 : Number;
			var dx2 : Number, dy2 : Number, dz2 : Number;
			var cx : Number, cy : Number, cz : Number;

			_faceTangents ||= new Vector.<Number>(_indices.length, true);

			while (i < len) {
				index1 = _indices[i++];
				index2 = _indices[i++];
				index3 = _indices[i++];

				v0 = _uvs[uint((index1 << 1) + 1)];
				ui = index2 << 1;
				dv1 = _uvs[uint((index2 << 1) + 1)] - v0;
				ui = index3 << 1;
				dv2 = _uvs[uint((index3 << 1) + 1)] - v0;

				vi = index1*3;
				x0 = _vertices[vi];
				y0 = _vertices[uint(vi+1)];
				z0 = _vertices[uint(vi+2)];
				vi = index2*3;
				dx1 = _vertices[uint(vi)] - x0;
				dy1 = _vertices[uint(vi+1)] - y0;
				dz1 = _vertices[uint(vi+2)] - z0;
				vi = index3*3;
				dx2 = _vertices[uint(vi)] - x0;
				dy2 = _vertices[uint(vi+1)] - y0;
				dz2 = _vertices[uint(vi+2)] - z0;

				cx = dv2*dx1 - dv1*dx2;
				cy = dv2*dy1 - dv1*dy2;
				cz = dv2*dz1 - dv1*dz2;
				denom = 1/Math.sqrt(cx*cx + cy*cy + cz*cz);
				_faceTangents[j++] = denom*cx;
				_faceTangents[j++] = denom*cy;
				_faceTangents[j++] = denom*cz;
			}

			_faceTangentsDirty = false;
		}
	}
}