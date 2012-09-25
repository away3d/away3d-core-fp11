package away3d.core.base
{
	import away3d.arcane;
	import away3d.core.base.ISubGeometry;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;

	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace  arcane;

	public class SubGeometryBase
	{
		private var _parentGeometry : Geometry;

		protected var _faceNormalsDirty : Boolean = true;
		protected var _faceTangentsDirty : Boolean = true;
		protected var _faceTangents : Vector.<Number>;
		protected var _indices : Vector.<uint>;
		protected var _indexBuffer : Vector.<IndexBuffer3D> = new Vector.<IndexBuffer3D>(8);
		protected var _numIndices : uint;
		protected var _indexBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _indicesInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _numTriangles : uint;

		protected var _autoDeriveVertexNormals : Boolean = true;
		protected var _autoDeriveVertexTangents : Boolean = true;
		private var _useFaceWeights : Boolean = false;
		protected var _vertexNormalsDirty : Boolean = true;
		protected var _vertexTangentsDirty : Boolean = true;

		protected var _faceNormalsData : Vector.<Number>;
		protected var _faceWeights : Vector.<Number>;

		private var _scaleU : Number = 1;
		private var _scaleV : Number = 1;

		public function SubGeometryBase()
		{
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

			_vertexNormalsDirty = value;
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
		 * The total amount of triangles in the SubGeometry.
		 */
		public function get numTriangles() : uint
		{
			return _numTriangles;
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains triangle indices.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains triangle indices.
		 */
		public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (!_indexBuffer[contextIndex] || _indexBufferContext[contextIndex] != context) {
				_indexBuffer[contextIndex] = context.createIndexBuffer(_numIndices);
				_indexBufferContext[contextIndex] = context;
				_indicesInvalid[contextIndex] = true;
			}
			if (_indicesInvalid[contextIndex]) {
				_indexBuffer[contextIndex].uploadFromVector(_indices, 0, _numIndices);
				_indicesInvalid[contextIndex] = false;
			}

			return _indexBuffer[contextIndex];
		}

		/**
		 * Updates the tangents for each face.
		 */
		protected function updateFaceTangents() : void
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
			var vertices : Vector.<Number> = vertexData;
			var uvs : Vector.<Number> = UVData;
			var vertexStride : int = vertexStride;
			var vertexOffset : int = vertexOffset;
			var uvStride : int = UVStride;
			var uvOffset : int = UVOffset;

			_faceTangents ||= new Vector.<Number>(_indices.length, true);

			while (i < len) {
				index1 = _indices[i++];
				index2 = _indices[i++];
				index3 = _indices[i++];

				ui = uvOffset + index1 * uvStride;
				v0 = uvs[ui + 1];
				ui = uvOffset + index2 * uvStride;
				dv1 = uvs[ui + 1] - v0;
				ui = uvOffset + index3 * uvStride;
				dv2 = uvs[ui + 1] - v0;

				vi = vertexOffset + index1 * vertexStride;
				x0 = vertices[vi];
				y0 = vertices[uint(vi + 1)];
				z0 = vertices[uint(vi + 2)];
				vi = vertexOffset + index2 * vertexStride;
				dx1 = vertices[uint(vi)] - x0;
				dy1 = vertices[uint(vi + 1)] - y0;
				dz1 = vertices[uint(vi + 2)] - z0;
				vi = vertexOffset + index3 * vertexStride;
				dx2 = vertices[uint(vi)] - x0;
				dy2 = vertices[uint(vi + 1)] - y0;
				dz2 = vertices[uint(vi + 2)] - z0;

				cx = dv2 * dx1 - dv1 * dx2;
				cy = dv2 * dy1 - dv1 * dy2;
				cz = dv2 * dz1 - dv1 * dz2;
				denom = 1 / Math.sqrt(cx * cx + cy * cy + cz * cz);
				_faceTangents[j++] = denom * cx;
				_faceTangents[j++] = denom * cy;
				_faceTangents[j++] = denom * cz;
			}

			_faceTangentsDirty = false;
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
			var vertices : Vector.<Number> = vertexData;
			var vertexStride : int = vertexStride;
			var vertexOffset : int = vertexOffset;

			_faceNormalsData ||= new Vector.<Number>(len, true);
			if (_useFaceWeights) _faceWeights ||= new Vector.<Number>(len/3, true);

			while (i < len) {
				index = vertexOffset + _indices[i++]*vertexStride;
				x1 = vertices[index++];
				y1 = vertices[index++];
				z1 = vertices[index];
				index = vertexOffset + _indices[i++]*vertexStride;
				x2 = vertices[index++];
				y2 = vertices[index++];
				z2 = vertices[index];
				index = vertexOffset + _indices[i++]*vertexStride;
				x3 = vertices[index++];
				y3 = vertices[index++];
				z3 = vertices[index];
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
		 * Updates the vertex normals based on the geometry.
		 */
		protected function updateVertexNormals(target : Vector.<Number>) : Vector.<Number>
		{
			if (_faceNormalsDirty)
				updateFaceNormals();

			var v1 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = vertexData.length;
			var vertexStride : int = vertexNormalStride;
			var normalOffset : int = vertexNormalOffset;

			// reset, yo
			if (target) {
				v1 = normalOffset;
				while (v1 < lenV) {
					target[v1] = 0.0;
					target[v1+1] = 0.0;
					target[v1+2] = 0.0;
					v1 += vertexStride;
				}
			}
			else target = new Vector.<Number>(lenV, true);

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = normalOffset + _indices[i++]*vertexStride;
				target[index++] += _faceNormalsData[f1]*weight;
				target[index++] += _faceNormalsData[f2]*weight;
				target[index] += _faceNormalsData[f3]*weight;
				index = normalOffset + _indices[i++]*vertexStride;
				target[index++] += _faceNormalsData[f1]*weight;
				target[index++] += _faceNormalsData[f2]*weight;
				target[index] += _faceNormalsData[f3]*weight;
				index = normalOffset + _indices[i++]*vertexStride;
				target[index++] += _faceNormalsData[f1]*weight;
				target[index++] += _faceNormalsData[f2]*weight;
				target[index] += _faceNormalsData[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = normalOffset;
			while (v1 < lenV) {
				var vx : Number = target[v1];
				var vy : Number = target[v1+1];
				var vz : Number = target[v1+2];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				target[v1] *= d;
				target[v1+1] *= d;
				target[v1+2] *= d;
				v1 += vertexStride;
			}

			_vertexNormalsDirty = false;

			return target;
		}

		/**
		 * Updates the vertex tangents based on the geometry.
		 */
		protected function updateVertexTangents(target : Vector.<Number>) : Vector.<Number>
		{
			if (_faceTangentsDirty)
				updateFaceTangents();

			var v1 : uint, v2 : uint, v3 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = vertexData.length;
			var vertexStride : int = vertexTangentStride;
			var tangentOffset : int = vertexTangentOffset;

			if (target) {
				v1 = tangentOffset;
				while (v1 < lenV) {
					target[v1] = 0.0;
					target[v1+1] = 0.0;
					target[v1+2] = 0.0;
					v1 += vertexStride;
				}
			}
			else target = new Vector.<Number>(lenV, true);

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = tangentOffset + _indices[i++]*vertexStride;
				target[index++] += _faceTangents[f1]*weight;
				target[index++] += _faceTangents[f2]*weight;
				target[index] += _faceTangents[f3]*weight;
				index = tangentOffset + _indices[i++]*vertexStride;
				target[index++] += _faceTangents[f1]*weight;
				target[index++] += _faceTangents[f2]*weight;
				target[index] += _faceTangents[f3]*weight;
				index = tangentOffset + _indices[i++]*vertexStride;
				target[index++] += _faceTangents[f1]*weight;
				target[index++] += _faceTangents[f2]*weight;
				target[index] += _faceTangents[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = tangentOffset;
			while (v1 < lenV) {
				var vx : Number = target[v1];
				var vy : Number = target[v1+1];
				var vz : Number = target[v1+2];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				target[v1] *= d;
				target[v1+1] *= d;
				target[v1+2] *= d;
				v1 += vertexStride;
			}

			_vertexTangentsDirty = false;

			return target;
		}

		public function dispose() : void
		{
			disposeIndexBuffers(_indexBuffer);
			_indices = null;
			_indexBufferContext = null;
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

			var numTriangles : int = _numIndices/3;
			if (_numTriangles != numTriangles)
				disposeIndexBuffers(_indexBuffer);
			_numTriangles = numTriangles;
			invalidateBuffers(_indicesInvalid);
			_faceNormalsDirty = true;

			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
		}

		/**
		 * Disposes all buffers in a given vector.
		 * @param buffers The vector of buffers to dispose.
		 */
		protected function disposeIndexBuffers(buffers : Vector.<IndexBuffer3D>) : void
		{
			for (var i : int = 0; i < 8; ++i) {
				if (buffers[i]) {
					buffers[i].dispose();
					buffers[i] = null;
				}
			}
		}

		/**
		 * Disposes all buffers in a given vector.
		 * @param buffers The vector of buffers to dispose.
		 */
		protected function disposeVertexBuffers(buffers : Vector.<VertexBuffer3D>) : void
		{
			for (var i : int = 0; i < 8; ++i) {
				if (buffers[i]) {
					buffers[i].dispose();
					buffers[i] = null;
				}
			}
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

			_vertexTangentsDirty = value;
		}

		/**
		 * The raw data of the face normals, in the same order as the faces are listed in the index list.
		 *
		 * @private
		 */
		public function get faceNormalsData() : Vector.<Number>
		{
			if (_faceNormalsDirty) updateFaceNormals();
			return _faceNormalsData;
		}

		/**
		 * Invalidates all buffers in a vector, causing them the update when they are first requested.
		 * @param buffers The vector of buffers to invalidate.
		 */
		protected function invalidateBuffers(invalid : Vector.<Boolean>) : void
		{
			for (var i : int = 0; i < 8; ++i)
				invalid[i] = true;
		}

		public function get UVStride() : uint
		{
			throw new AbstractMethodError();
		}

		public function get vertexData() : Vector.<Number>
		{
			throw new AbstractMethodError();
		}

		public function get vertexNormalData() : Vector.<Number>
		{
			throw new AbstractMethodError();
		}

		public function get vertexTangentData() : Vector.<Number>
		{
			throw new AbstractMethodError();
		}

		public function get UVData() : Vector.<Number>
		{
			throw new AbstractMethodError();
		}

		public function get vertexStride() : uint
		{
			throw new AbstractMethodError();
		}

		public function get vertexNormalStride() : uint
		{
			throw new AbstractMethodError();
		}

		public function get vertexTangentStride() : uint
		{
			throw new AbstractMethodError();
		}

		public function get vertexOffset() : int
		{
			throw new AbstractMethodError();
		}

		public function get vertexNormalOffset() : int
		{
			throw new AbstractMethodError();
		}

		public function get vertexTangentOffset() : int
		{
			throw new AbstractMethodError();
		}

		public function get UVOffset() : int
		{
			throw new AbstractMethodError();
		}

		protected function invalidateBounds() : void
		{
			if (_parentGeometry) _parentGeometry.invalidateBounds(ISubGeometry(this));
		}

		/**
		 * The Geometry object that 'owns' this SubGeometry object.
		 *
		 * @private
		 */
		public function get parentGeometry() : Geometry
		{
			return _parentGeometry;
		}

		public function set parentGeometry(value : Geometry) : void
		{
			_parentGeometry = value;
		}

		/**
		 * Scales the uv coordinates
		 * @param scaleU The amount by which to scale on the u axis. Default is 1;
		 * @param scaleV The amount by which to scale on the v axis. Default is 1;
		 */
		public function get scaleU():Number
		{
			return _scaleU;
		}

		public function get scaleV():Number
		{
			return _scaleV;
		}

		public function scaleUV(scaleU : Number = 1, scaleV : Number = 1):void
		{
			var offset : int = UVOffset;
			var stride : int = UVStride;
			var uvs : Vector.<Number> = UVData;
			var len : int = uvs.length;
			var ratioU : Number = scaleU/_scaleU;
			var ratioV : Number = scaleV/_scaleV;

			for (var i : uint = offset; i < len; i += stride) {
				uvs[i] *= ratioU;
				uvs[i+1] *= ratioV;
			}

			_scaleU = scaleU;
			_scaleV = scaleV;
		}

		/**
		 * Scales the geometry.
		 * @param scale The amount by which to scale.
		 */
		public function scale(scale : Number):void
		{
			var vertices : Vector.<Number> = UVData;
			var len : uint = vertices.length;
			var offset : int = vertexOffset;
			var stride : int = vertexStride;

			for (var i : uint = offset; i < len; i += stride) {
				vertices[i] *= scale;
				vertices[i+1] *= scale;
				vertices[i+2] *= scale;
			}
		}

		public function applyTransformation(transform:Matrix3D):void
		{
			var vertices : Vector.<Number> = vertexData;
			var normals : Vector.<Number> = vertexNormalData;
			var tangents : Vector.<Number> = vertexTangentData;
			var posStride : int = vertexStride;
			var normalStride : int = vertexNormalStride;
			var tangentStride : int = vertexTangentStride;
			var posOffset : int = vertexOffset;
			var normalOffset : int = vertexNormalOffset;
			var tangentOffset : int = vertexTangentOffset;
			var len : uint = vertices.length/posStride;
			var i:uint, i1:uint, i2:uint;
			var vector:Vector3D = new Vector3D();

			var bakeNormals:Boolean = normals != null;
			var bakeTangents:Boolean = tangents != null;
			var invTranspose:Matrix3D;

			if (bakeNormals || bakeTangents) {
				invTranspose = transform.clone();
				invTranspose.invert();
				invTranspose.transpose();
			}

			var vi0 : int = posOffset;
			var ni0 : int = normalOffset;
			var ti0 : int = tangentOffset;

			for (i = 0; i < len; ++i) {
				i1 = vi0 + 1;
				i2 = vi0 + 2;

				// bake position
				vector.x = vertices[vi0];
				vector.y = vertices[i1];
				vector.z = vertices[i2];
				vector = transform.transformVector(vector);
				vertices[vi0] = vector.x;
				vertices[i1] = vector.y;
				vertices[i2] = vector.z;
				vi0 += posStride;

				// bake normal
				if(bakeNormals)
				{
					i1 = ni0 + 1;
					i2 = ni0 + 2;
					vector.x = normals[ni0];
					vector.y = normals[i1];
					vector.z = normals[i2];
					vector = invTranspose.deltaTransformVector(vector);
					normals[ni0] = vector.x;
					normals[i1] = vector.y;
					normals[i2] = vector.z;
					ni0 += normalStride;
				}

				// bake tangent
				if(bakeTangents)
				{
					i1 = ti0 + 1;
					i2 = ti0 + 2;
					vector.x = tangents[ti0];
					vector.y = tangents[i1];
					vector.z = tangents[i2];
					vector = invTranspose.deltaTransformVector(vector);
					tangents[ti0] = vector.x;
					tangents[i1] = vector.y;
					tangents[i2] = vector.z;
					ti0 += tangentStride;
				}
			}
		}


	}
}
