package away3d.core.base
{
	import away3d.arcane;
	import away3d.core.TriangleSubMesh;
	import away3d.events.SubGeometryEvent;

	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class TriangleSubGeometry extends SubGeometryBase
	{
		public static const POSITION_DATA:String = "positions";
		public static const NORMAL_DATA:String = "vertexNormals";
		public static const TANGENT_DATA:String = "vertexTangents";
		public static const UV_DATA:String = "uvs";
		public static const SECONDARY_UV_DATA:String = "secondaryUVs";
		public static const JOINT_INDEX_DATA:String = "jointIndices";
		public static const JOINT_WEIGHT_DATA:String = "jointWeights";
		public static const POSITION_FORMAT:String = Context3DVertexBufferFormat.FLOAT_3;
		public static const NORMAL_FORMAT:String = Context3DVertexBufferFormat.FLOAT_3;
		public static const TANGENT_FORMAT:String = Context3DVertexBufferFormat.FLOAT_3;
		public static const UV_FORMAT:String = Context3DVertexBufferFormat.FLOAT_2;
		public static const SECONDARY_UV_FORMAT:String = Context3DVertexBufferFormat.FLOAT_2;

		private var _positionsDirty:Boolean = true;
		private var _faceNormalsDirty:Boolean = true;
		private var _faceTangentsDirty:Boolean = true;
		private var _vertexNormalsDirty:Boolean = true;
		private var _vertexTangentsDirty:Boolean = true;
		private var _uvsDirty:Boolean = true;
		private var _secondaryUVsDirty:Boolean = true;
		private var _jointIndicesDirty:Boolean = true;
		private var _jointWeightsDirty:Boolean = true;

		private var _positions:Vector.<Number>;
		private var _vertexNormals:Vector.<Number>;
		private var _vertexTangents:Vector.<Number>;
		private var _uvs:Vector.<Number>;
		private var _secondaryUVs:Vector.<Number>;
		private var _jointIndices:Vector.<Number>;
		private var _jointWeights:Vector.<Number>;

		private var _useCondensedIndices:Boolean;
		private var _condensedJointIndices:Vector.<Number>;
		private var _condensedIndexLookUp:Vector.<Number>;
		private var _numCondensedJoints:Number;

		private var _jointsPerVertex:Number;

		private var _autoDeriveNormals:Boolean = true;
		private var _autoDeriveTangents:Boolean = true;
		private var _autoDeriveUVs:Boolean = false;
		private var _useFaceWeights:Boolean = false;

		private var _faceNormals:Vector.<Number>;
		private var _faceTangents:Vector.<Number>;
		private var _faceWeights:Vector.<Number>;

		private var _scaleU:Number = 1;
		private var _scaleV:Number = 1;

		private var _positionsUpdated:SubGeometryEvent;
		private var _normalsUpdated:SubGeometryEvent;
		private var _tangentsUpdated:SubGeometryEvent;
		private var _uvsUpdated:SubGeometryEvent;
		private var _secondaryUVsUpdated:SubGeometryEvent;
		private var _jointIndicesUpdated:SubGeometryEvent;
		private var _jointWeightsUpdated:SubGeometryEvent;

		/**
		 *
		 */
		public function get scaleU():Number
		{
			return _scaleU;
		}

		/**
		 *
		 */
		public function get scaleV():Number
		{
			return _scaleV;
		}

		/**
		 * Offers the option of enabling GPU accelerated animation on skeletons larger than 32 joints
		 * by condensing the Number of joint index values required per mesh. Only applicable to
		 * skeleton animations that utilise more than one mesh object. Defaults to false.
		 */
		public function get useCondensedIndices():Boolean
		{
			return _useCondensedIndices;
		}

		public function set useCondensedIndices(value:Boolean):void
		{
			if (_useCondensedIndices == value)
				return;

			_useCondensedIndices = value;

			notifyJointIndicesUpdate();
		}

		override protected function updateStrideOffset():void
		{
			if (_concatenateArrays) {
				_offset[VERTEX_DATA] = 0;

				//always have positions
				_offset[POSITION_DATA] = 0;
				var stride:Number = 3;

				if (_vertexNormals != null) {
					_offset[NORMAL_DATA] = stride;
					stride += 3;
				}

				if (_vertexTangents != null) {
					_offset[TANGENT_DATA] = stride;
					stride += 3;
				}

				if (_uvs != null) {
					_offset[UV_DATA] = stride;
					stride += 2;
				}

				if (_secondaryUVs != null) {
					_offset[SECONDARY_UV_DATA] = stride;
					stride += 2;
				}

				if (_jointIndices != null) {
					_offset[JOINT_INDEX_DATA] = stride;
					stride += _jointsPerVertex;
				}

				if (_jointWeights != null) {
					_offset[JOINT_WEIGHT_DATA] = stride;
					stride += _jointsPerVertex;
				}

				_stride[VERTEX_DATA] = stride;
				_stride[POSITION_DATA] = stride;
				_stride[NORMAL_DATA] = stride;
				_stride[TANGENT_DATA] = stride;
				_stride[UV_DATA] = stride;
				_stride[SECONDARY_UV_DATA] = stride;
				_stride[JOINT_INDEX_DATA] = stride;
				_stride[JOINT_WEIGHT_DATA] = stride;

				var len:Number = _numVertices*stride;

				if (_vertices == null)
					_vertices = new Vector.<Number>(len);
				else if (_vertices.length != len)
					_vertices.length = len;

			} else {
				_offset[POSITION_DATA] = 0;
				_offset[NORMAL_DATA] = 0;
				_offset[TANGENT_DATA] = 0;
				_offset[UV_DATA] = 0;
				_offset[SECONDARY_UV_DATA] = 0;
				_offset[JOINT_INDEX_DATA] = 0;
				_offset[JOINT_WEIGHT_DATA] = 0;

				_stride[POSITION_DATA] = 3;
				_stride[NORMAL_DATA] = 3;
				_stride[TANGENT_DATA] = 3;
				_stride[UV_DATA] = 2;
				_stride[SECONDARY_UV_DATA] = 2;
				_stride[JOINT_INDEX_DATA] = _jointsPerVertex;
				_stride[JOINT_WEIGHT_DATA] = _jointsPerVertex;
			}

			_strideOffsetDirty = false;
		}

		/**
		 *
		 */
		public function get jointsPerVertex():Number
		{
			return _jointsPerVertex;
		}

		public function set jointsPerVertex(value:Number):void
		{
			if (_jointsPerVertex == value)
				return;

			_jointsPerVertex = value;

			_strideOffsetDirty = true;

			if (_concatenateArrays)
				notifyVerticesUpdate();
		}

		/**
		 * Defines whether a UV buffer should be automatically generated to contain dummy UV coordinates.
		 * Set to true if a geometry lacks UV data but uses a material that requires it, or leave as false
		 * in cases where UV data is explicitly defined or the material does not require UV data.
		 */
		public function get autoDeriveUVs():Boolean
		{
			return _autoDeriveUVs;
		}

		public function set autoDeriveUVs(value:Boolean):void
		{
			if (_autoDeriveUVs == value)
				return;

			_autoDeriveUVs = value;

			if (value)
				notifyUVsUpdate();
		}

		/**
		 * True if the vertex normals should be derived from the geometry, false if the vertex normals are set
		 * explicitly.
		 */
		public function get autoDeriveNormals():Boolean
		{
			return _autoDeriveNormals;
		}

		public function set autoDeriveNormals(value:Boolean):void
		{
			if (_autoDeriveNormals == value)
				return;

			_autoDeriveNormals = value;

			if (value)
				notifyNormalsUpdate();
		}

		/**
		 * True if the vertex tangents should be derived from the geometry, false if the vertex normals are set
		 * explicitly.
		 */
		public function get autoDeriveTangents():Boolean
		{
			return _autoDeriveTangents;
		}

		public function set autoDeriveTangents(value:Boolean):void
		{
			if (_autoDeriveTangents == value)
				return;

			_autoDeriveTangents = value;

			if (value)
				notifyTangentsUpdate();
		}

		/**
		 *
		 */
		override public function get vertices():Vector.<Number>
		{
			if (_positionsDirty)
				updatePositions(_positions);

			if (_vertexNormalsDirty)
				updateVertexNormals(_vertexNormals);

			if (_vertexTangentsDirty)
				updateVertexTangents(_vertexTangents);

			if (_uvsDirty)
				updateUVs(_uvs);

			if (_secondaryUVsDirty)
				updateSecondaryUVs(_secondaryUVs);

			if (_jointIndicesDirty)
				updateJointIndices(_jointIndices);

			if (_jointWeightsDirty)
				updateJointWeights(_jointWeights);

			return _vertices;
		}

		/**
		 *
		 */
		public function get positions():Vector.<Number>
		{
			if (_positionsDirty)
				updatePositions(_positions);

			return _positions;
		}

		/**
		 *
		 */
		public function get vertexNormals():Vector.<Number>
		{
			if (_vertexNormalsDirty)
				updateVertexNormals(_vertexNormals);

			return _vertexNormals;
		}

		/**
		 *
		 */
		public function get vertexTangents():Vector.<Number>
		{
			if (_vertexTangentsDirty)
				updateVertexTangents(_vertexTangents);

			return _vertexTangents;
		}

		/**
		 * The raw data of the face normals, in the same order as the faces are listed in the index list.
		 */
		public function get faceNormals():Vector.<Number>
		{
			if (_faceNormalsDirty)
				updateFaceNormals();

			return _faceNormals;
		}

		/**
		 * The raw data of the face tangets, in the same order as the faces are listed in the index list.
		 */
		public function get faceTangents():Vector.<Number>
		{
			if (_faceTangentsDirty)
				updateFaceTangents();

			return _faceTangents;
		}

		/**
		 *
		 */
		public function get uvs():Vector.<Number>
		{
			if (_uvsDirty)
				updateUVs(_uvs);

			return _uvs;
		}

		/**
		 *
		 */
		public function get secondaryUVs():Vector.<Number>
		{
			if (_secondaryUVsDirty)
				updateSecondaryUVs(_secondaryUVs);

			return _secondaryUVs;
		}

		/**
		 *
		 */
		public function get jointIndices():Vector.<Number>
		{
			if (_jointIndicesDirty)
				updateJointIndices(_jointIndices);

			if (_useCondensedIndices)
				return _condensedJointIndices;

			return _jointIndices;
		}

		/**
		 *
		 */
		public function get jointWeights():Vector.<Number>
		{
			if (_jointWeightsDirty)
				updateJointWeights(_jointWeights);

			return _jointWeights;
		}

		/**
		 * Indicates whether or not to take the size of faces into account when auto-deriving vertex normals and tangents.
		 */
		public function get useFaceWeights():Boolean
		{
			return _useFaceWeights;
		}

		public function set useFaceWeights(value:Boolean):void
		{
			if (_useFaceWeights == value)
				return;

			_useFaceWeights = value;

			if (_autoDeriveNormals)
				notifyNormalsUpdate();

			if (_autoDeriveTangents)
				notifyTangentsUpdate();

			_faceNormalsDirty = true;
		}

		public function get numCondensedJoints():Number
		{
			if (_jointIndicesDirty)
				updateJointIndices(_jointIndices);

			return _numCondensedJoints;
		}

		public function get condensedIndexLookUp():Vector.<Number>
		{
			if (_jointIndicesDirty)
				updateJointIndices(_jointIndices);

			return _condensedIndexLookUp;
		}

		/**
		 *
		 */
		public function TriangleSubGeometry(concatenatedArrays:Boolean)
		{
			super(concatenatedArrays);
			_subMeshClass = TriangleSubMesh;
		}

		override public function getBoundingPositions():Vector.<Number>
		{
			if (_positionsDirty)
				updatePositions(_positions);

			return _positions;
		}

		/**
		 *
		 */
		public function updatePositions(values:Vector.<Number>):void
		{
			var i:Number;
			var index:Number;
			var stride:Number;
			var positions:Vector.<Number>;

			_positions = values;

			if (_positions == null)
				_positions = new Vector.<Number>();

			_numVertices = _positions.length/3;

			if (_concatenateArrays) {
				var len:Number = _numVertices*getStride(VERTEX_DATA);

				if (_vertices == null)
					_vertices = new Vector.<Number>(len);
				else if (_vertices.length != len)
					_vertices.length = len;

				i = 0;
				index = getOffset(POSITION_DATA);
				stride = getStride(POSITION_DATA);
				positions = _vertices;

				while (i < values.length) {
					positions[index] = values[i++];
					positions[index + 1] = values[i++];
					positions[index + 2] = values[i++];
					index += stride;
				}
			}

			if (_autoDeriveNormals)
				notifyNormalsUpdate();

			if (_autoDeriveTangents)
				notifyTangentsUpdate();

			if (_autoDeriveUVs)
				notifyUVsUpdate()

			invalidateBounds();

			notifyPositionsUpdate();

			_positionsDirty = false;
		}

		/**
		 * Updates the vertex normals based on the geometry.
		 */
		public function updateVertexNormals(values:Vector.<Number>):void
		{
			var i:Number;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var normals:Vector.<Number>;

			if (!_autoDeriveNormals) {
				if ((_vertexNormals == null || values == null) && (_vertexNormals != null || values != null)) {
					if (_concatenateArrays)
						notifyVerticesUpdate();
					else
						_strideOffsetDirty = true;
				}

				_vertexNormals = values;

				if (values != null && _concatenateArrays) {
					i = 0;
					index = getOffset(NORMAL_DATA);
					stride = getStride(NORMAL_DATA);
					normals = _vertices;

					while (i < values.length) {
						normals[index] = values[i++];
						normals[index + 1] = values[i++];
						normals[index + 2] = values[i++];
						index += stride;
					}
				}
			} else {
				if (_vertexNormals == null) {
					_vertexNormals = new Vector.<Number>(_positions.length);

					if (_concatenateArrays)
						notifyVerticesUpdate();
					else
						_strideOffsetDirty = true;
				}

				if (_faceNormalsDirty)
					updateFaceNormals();

				offset = getOffset(NORMAL_DATA);
				stride = getStride(NORMAL_DATA);

				//autoderived normals
				normals = _concatenateArrays? _vertices : _vertexNormals;

				var f1:Number = 0;
				var f2:Number = 1;
				var f3:Number = 2;

				index = offset;

				//clear normal values
				var lenV:Number = normals.length;
				while (index < lenV) {
					normals[index] = 0;
					normals[index + 1] = 0;
					normals[index + 2] = 0;
					index += stride;
				}

				var k:Number = 0;
				var lenI:Number = _indices.length;
				var weight:Number;

				i = 0;

				//collect face normals
				while (i < lenI) {
					weight = _useFaceWeights? _faceWeights[k++] : 1;
					index = offset + _indices[i++]*stride;
					normals[index] += _faceNormals[f1]*weight;
					normals[index + 1] += _faceNormals[f2]*weight;
					normals[index + 2] += _faceNormals[f3]*weight;
					index = offset + _indices[i++]*stride;
					normals[index] += _faceNormals[f1]*weight;
					normals[index + 1] += _faceNormals[f2]*weight;
					normals[index + 2] += _faceNormals[f3]*weight;
					index = offset + _indices[i++]*stride;
					normals[index] += _faceNormals[f1]*weight;
					normals[index + 1] += _faceNormals[f2]*weight;
					normals[index + 2] += _faceNormals[f3]*weight;
					f1 += 3;
					f2 += 3;
					f3 += 3;
				}

				i = 0;
				index = offset;

				//average normals collections
				while (index < lenV) {
					var vx:Number = normals[index];
					var vy:Number = normals[index + 1];
					var vz:Number = normals[index + 2];
					var d:Number = 1.0/Math.sqrt(vx*vx + vy*vy + vz*vz);

					if (_concatenateArrays) {
						_vertexNormals[i++] = normals[index] = vx*d;
						_vertexNormals[i++] = normals[index + 1] = vy*d;
						_vertexNormals[i++] = normals[index + 2] = vz*d;
					} else {
						normals[index] = vx*d;
						normals[index + 1] = vy*d;
						normals[index + 2] = vz*d;
					}

					index += stride;
				}
			}

			notifyNormalsUpdate();

			_vertexNormalsDirty = false;
		}

		/**
		 * Updates the vertex tangents based on the geometry.
		 */
		public function updateVertexTangents(values:Vector.<Number>):void
		{
			var i:Number;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var tangents:Vector.<Number>;

			if (!_autoDeriveTangents) {
				if ((_vertexTangents == null || values == null) && (_vertexTangents != null || values != null)) {
					if (_concatenateArrays)
						notifyVerticesUpdate();
					else
						_strideOffsetDirty = true;
				}


				_vertexTangents = values;

				if (values != null && _concatenateArrays) {
					i = 0;
					index = getOffset(TANGENT_DATA);
					stride = getStride(TANGENT_DATA);
					tangents = _vertices;

					while (i < values.length) {
						tangents[index] = values[i++];
						tangents[index + 1] = values[i++];
						tangents[index + 2] = values[i++];
						index += stride;
					}
				}
			} else {
				if (_vertexTangents == null) {
					_vertexTangents = new Vector.<Number>(_positions.length);

					if (_concatenateArrays)
						notifyVerticesUpdate();
					else
						_strideOffsetDirty = true;
				}

				if (_faceTangentsDirty)
					updateFaceTangents();

				offset = getOffset(TANGENT_DATA);
				stride = getStride(TANGENT_DATA);

				//autoderived tangents
				tangents = _concatenateArrays? _vertices : _vertexTangents;

				index = offset;

				//clear tangent values
				var lenV:Number = tangents.length;
				while (index < lenV) {
					tangents[index] = 0;
					tangents[index + 1] = 0;
					tangents[index + 2] = 0;

					index += stride;
				}

				var k:Number = 0;
				var weight:Number;
				var f1:Number = 0;
				var f2:Number = 1;
				var f3:Number = 2;

				i = 0;

				//collect face tangents
				var lenI:Number = _indices.length;
				while (i < lenI) {
					weight = _useFaceWeights? _faceWeights[k++] : 1;
					index = offset + _indices[i++]*stride;
					tangents[index++] += _faceTangents[f1]*weight;
					tangents[index++] += _faceTangents[f2]*weight;
					tangents[index] += _faceTangents[f3]*weight;
					index = offset + _indices[i++]*stride;
					tangents[index++] += _faceTangents[f1]*weight;
					tangents[index++] += _faceTangents[f2]*weight;
					tangents[index] += _faceTangents[f3]*weight;
					index = offset + _indices[i++]*stride;
					tangents[index++] += _faceTangents[f1]*weight;
					tangents[index++] += _faceTangents[f2]*weight;
					tangents[index] += _faceTangents[f3]*weight;
					f1 += 3;
					f2 += 3;
					f3 += 3;
				}

				i = 0;
				index = offset;

				//average tangents collections
				while (index < lenV) {
					var vx:Number = tangents[index];
					var vy:Number = tangents[index + 1];
					var vz:Number = tangents[index + 2];
					var d:Number = 1.0/Math.sqrt(vx*vx + vy*vy + vz*vz);

					if (_concatenateArrays) {
						_vertexTangents[i++] = tangents[index] = vx*d;
						_vertexTangents[i++] = tangents[index + 1] = vy*d;
						_vertexTangents[i++] = tangents[index + 2] = vz*d;
					} else {
						tangents[index] = vx*d;
						tangents[index + 1] = vy*d;
						tangents[index + 2] = vz*d;
					}

					index += stride;
				}
			}

			notifyTangentsUpdate();

			_vertexTangentsDirty = false;
		}

		/**
		 * Updates the uvs based on the geometry.
		 */
		public function updateUVs(values:Vector.<Number>):void
		{
			var i:Number;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var uvs:Vector.<Number>;

			if (!_autoDeriveUVs) {
				if ((_uvs == null || values == null) && (_uvs != null || values != null)) {
					if (_concatenateArrays)
						notifyVerticesUpdate();
					else
						_strideOffsetDirty = true;
				}

				_uvs = values;

				if (values != null && _concatenateArrays) {
					i = 0;
					index = getOffset(UV_DATA);
					stride = getStride(UV_DATA);
					uvs = _vertices;

					while (i < values.length) {
						uvs[index] = values[i++];
						uvs[index + 1] = values[i++];
						index += stride;
					}
				}

			} else {
				if (_uvs == null) {
					_uvs = new Vector.<Number>(_positions.length*2/3);

					if (_concatenateArrays)
						notifyVerticesUpdate();
					else
						_strideOffsetDirty = true;
				}

				offset = getOffset(UV_DATA);
				stride = getStride(UV_DATA);

				//autoderived uvs
				uvs = _concatenateArrays? _vertices : _uvs;

				i = 0;
				index = offset;
				var uvIdx:Number = 0;

				//clear uv values
				var lenV:Number = uvs.length;
				while (index < lenV) {
					if (_concatenateArrays) {
						_uvs[i++] = uvs[index] = uvIdx*.5;
						_uvs[i++] = uvs[index + 1] = 1.0 - (uvIdx & 1);
					} else {
						uvs[index] = uvIdx*.5;
						uvs[index + 1] = 1.0 - (uvIdx & 1);
					}

					if (++uvIdx == 3)
						uvIdx = 0;

					index += stride;
				}
			}

			if (_autoDeriveTangents)
				notifyTangentsUpdate();

			notifyUVsUpdate();

			_uvsDirty = false;
		}

		/**
		 * Updates the secondary uvs based on the geometry.
		 */
		public function updateSecondaryUVs(values:Vector.<Number>):void
		{
			var i:Number;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var uvs:Vector.<Number>;

			if (_concatenateArrays && (_secondaryUVs == null || values == null) && (_secondaryUVs != null || values != null))
				notifyVerticesUpdate();

			_secondaryUVs = values;

			if (values != null && _concatenateArrays) {
				offset = getOffset(SECONDARY_UV_DATA);
				stride = getStride(SECONDARY_UV_DATA);

				i = 0;
				index = offset;
				uvs = _vertices;

				while (i < values.length) {
					uvs[index] = values[i++];
					uvs[index + 1] = values[i++];
					index += stride;
				}
			}

			notifySecondaryUVsUpdate();

			_secondaryUVsDirty = false;
		}

		/**
		 * Updates the joint indices
		 */
		public function updateJointIndices(values:Vector.<Number>):void
		{
			var i:Number;
			var j:Number;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var jointIndices:Vector.<Number>;

			if (_concatenateArrays && (_jointIndices == null || values == null) && (_jointIndices != null || values != null))
				notifyVerticesUpdate();

			_jointIndices = values;

			if (values != null) {
				offset = getOffset(JOINT_INDEX_DATA);
				stride = getStride(JOINT_INDEX_DATA);
				if (_useCondensedIndices) {
					i = 0;
					j = 0;
					index = offset;
					jointIndices = _concatenateArrays? _vertices : _condensedJointIndices;
					var oldIndex:Number;
					var newIndex:Number = 0;
					var dic:Object = new Object();

					if (!_concatenateArrays)
						_condensedJointIndices = new Vector.<Number>(values.length);

					_condensedIndexLookUp = new Vector.<Number>();

					while (i < values.length) {
						for (j = 0; j < _jointsPerVertex; j++) {
							oldIndex = values[i++];

							// if we encounter a new index, assign it a new condensed index
							if (dic[oldIndex] == undefined) {
								dic[oldIndex] = newIndex*3; //3 required for the three vectors that store the matrix
								_condensedIndexLookUp[newIndex++] = oldIndex;
							}
							jointIndices[index + j] = dic[oldIndex];
						}
						index += stride;
					}
					_numCondensedJoints = newIndex;
				} else if (_concatenateArrays) {

					i = 0;
					index = offset;
					jointIndices = _vertices;

					while (i < values.length) {
						j = 0;
						while (j < _jointsPerVertex)
							jointIndices[index + j++] = values[i++];
						index += stride;
					}
				}
			}

			notifyJointIndicesUpdate();

			_jointIndicesDirty = false;
		}

		/**
		 * Updates the joint weights.
		 */
		public function updateJointWeights(values:Vector.<Number>):void
		{
			var i:Number;
			var j:Number;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var jointWeights:Vector.<Number>;

			if (_concatenateArrays && (_jointWeights == null || values == null) && (_jointWeights != null || values != null))
				notifyVerticesUpdate();

			_jointWeights = values;

			if (values != null && _concatenateArrays) {
				offset = getOffset(JOINT_WEIGHT_DATA);
				stride = getStride(JOINT_WEIGHT_DATA);

				i = 0;
				index = offset;
				jointWeights = _vertices;

				while (i < values.length) {
					j = 0;
					while (j < _jointsPerVertex)
						jointWeights[index + j++] = values[i++];
					index += stride;
				}
			}

			notifyJointWeightsUpdate();

			_jointWeightsDirty = false;
		}

		/**
		 *
		 */
		override public function dispose():void
		{
			super.dispose();

			_positions = null;
			_vertexNormals = null;
			_vertexTangents = null;
			_uvs = null;
			_secondaryUVs = null;
			_jointIndices = null;
			_jointWeights = null;

			_faceNormals = null;
			_faceWeights = null;
			_faceTangents = null;
		}

		/**
		 * Updates the face indices of the
		 *
		 * @param indices The face indices to upload.
		 */
		override public function updateIndices(indices:Vector.<uint>):void
		{
			super.updateIndices(indices);

			_faceNormalsDirty = true;

			if (_autoDeriveNormals)
				_vertexNormalsDirty = true;

			if (_autoDeriveTangents)
				_vertexTangentsDirty = true;

			if (_autoDeriveUVs)
				_uvsDirty = true;
		}

		/**
		 * Clones the current object
		 * @return An exact duplicate of the current object.
		 */
		override public function clone():SubGeometryBase
		{
			var clone:TriangleSubGeometry = new TriangleSubGeometry(_concatenateArrays);
			clone.updateIndices(_indices.concat());
			clone.updatePositions(_positions.concat());

			if (_vertexNormals && !_autoDeriveNormals)
				clone.updateVertexNormals(_vertexNormals.concat());
			else
				clone.updateVertexNormals(null);

			if (_uvs && !_autoDeriveUVs)
				clone.updateUVs(_uvs.concat());
			else
				clone.updateUVs(null);

			if (_vertexTangents && !_autoDeriveTangents)
				clone.updateVertexTangents(_vertexTangents.concat());
			else
				clone.updateVertexTangents(null);

			if (_secondaryUVs)
				clone.updateSecondaryUVs(_secondaryUVs.concat());

			if (_jointIndices) {
				clone.jointsPerVertex = _jointsPerVertex;
				clone.updateJointIndices(_jointIndices.concat());
			}

			if (_jointWeights)
				clone.updateJointWeights(_jointWeights.concat());

			return clone;
		}

		override public function scaleUV(scaleU:Number = 1, scaleV:Number = 1):void
		{
			var index:Number;
			var offset:Number;
			var stride:Number;
			var uvs:Vector.<Number>;

			uvs = _uvs;

			var ratioU:Number = scaleU/_scaleU;
			var ratioV:Number = scaleV/_scaleV;

			_scaleU = scaleU;
			_scaleV = scaleV;

			var len:Number = uvs.length;

			offset = 0;
			stride = 2;

			index = offset;

			while (index < len) {
				uvs[index] *= ratioU;
				uvs[index + 1] *= ratioV;
				index += stride;
			}

			notifyUVsUpdate();
		}

		/**
		 * Scales the geometry.
		 * @param scale The amount by which to scale.
		 */
		override public function scale(scale:Number):void
		{
			var i:uint;
			var index:Number;
			var offset:Number;
			var stride:Number;
			var positions:Vector.<Number>;

			positions = _positions;

			var len:uint = positions.length;

			offset = 0;
			stride = 3;

			i = 0;
			index = offset;
			while (i < len) {
				positions[index] *= scale;
				positions[index + 1] *= scale;
				positions[index + 2] *= scale;

				i += 3;
				index += stride;
			}

			notifyPositionsUpdate();
		}

		override public function applyTransformation(transform:Matrix3D):void
		{
			var positions:Vector.<Number>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;

			if (_concatenateArrays) {
				positions = _vertices;
				normals = _vertices;
				tangents = _vertices;
			} else {
				positions = _positions;
				normals = _vertexNormals;
				tangents = _vertexTangents;
			}

			var len:Number = _positions.length/3;
			var i:Number;
			var i1:Number;
			var i2:Number;
			var vector:Vector3D = new Vector3D();

			var bakeNormals:Boolean = _vertexNormals != null;
			var bakeTangents:Boolean = _vertexTangents != null;
			var invTranspose:Matrix3D;

			if (bakeNormals || bakeTangents) {
				invTranspose = transform.clone();
				invTranspose.invert();
				invTranspose.transpose();
			}

			var vi0:Number = getOffset(POSITION_DATA);
			var ni0:Number = getOffset(NORMAL_DATA);
			var ti0:Number = getOffset(TANGENT_DATA);

			var vStride:Number = getStride(POSITION_DATA);
			var nStride:Number = getStride(NORMAL_DATA);
			var tStride:Number = getStride(TANGENT_DATA);

			for (i = 0; i < len; ++i) {
				i1 = vi0 + 1;
				i2 = vi0 + 2;

				// bake position
				vector.x = positions[vi0];
				vector.y = positions[i1];
				vector.z = positions[i2];
				vector = transform.transformVector(vector);
				positions[vi0] = vector.x;
				positions[i1] = vector.y;
				positions[i2] = vector.z;
				vi0 += vStride;

				// bake normal
				if (bakeNormals) {
					i1 = ni0 + 1;
					i2 = ni0 + 2;
					vector.x = normals[ni0];
					vector.y = normals[i1];
					vector.z = normals[i2];
					vector = invTranspose.deltaTransformVector(vector);
					vector.normalize();
					normals[ni0] = vector.x;
					normals[i1] = vector.y;
					normals[i2] = vector.z;
					ni0 += nStride;
				}

				// bake tangent
				if (bakeTangents) {
					i1 = ti0 + 1;
					i2 = ti0 + 2;
					vector.x = tangents[ti0];
					vector.y = tangents[i1];
					vector.z = tangents[i2];
					vector = invTranspose.deltaTransformVector(vector);
					vector.normalize();
					tangents[ti0] = vector.x;
					tangents[i1] = vector.y;
					tangents[i2] = vector.z;
					ti0 += tStride;
				}
			}

			notifyPositionsUpdate();
			notifyNormalsUpdate();
			notifyTangentsUpdate();
		}

		/**
		 * Updates the tangents for each face.
		 */
		private function updateFaceTangents():void
		{
			var i:uint = 0;
			var index1:Number;
			var index2:Number;
			var index3:Number;
			var vi:Number;
			var v0:Number;
			var dv1:Number;
			var dv2:Number;
			var denom:Number;
			var x0:Number, y0:Number, z0:Number;
			var dx1:Number, dy1:Number, dz1:Number;
			var dx2:Number, dy2:Number, dz2:Number;
			var cx:Number, cy:Number, cz:Number;

			var positions:Vector.<Number> = _positions
			var uvs:Vector.<Number> = _uvs;

			var len:uint = _indices.length;

			if (_faceTangents == null)
				_faceTangents = new Vector.<Number>(len);

			while (i < len) {
				index1 = _indices[i];
				index2 = _indices[i + 1];
				index3 = _indices[i + 2];

				v0 = uvs[index1*2 + 1];
				dv1 = uvs[index2*2 + 1] - v0;
				dv2 = uvs[index3*2 + 1] - v0;

				vi = index1*3;
				x0 = positions[vi];
				y0 = positions[vi + 1];
				z0 = positions[vi + 2];
				vi = index2*3;
				dx1 = positions[vi] - x0;
				dy1 = positions[vi + 1] - y0;
				dz1 = positions[vi + 2] - z0;
				vi = index3*3;
				dx2 = positions[vi] - x0;
				dy2 = positions[vi + 1] - y0;
				dz2 = positions[vi + 2] - z0;

				cx = dv2*dx1 - dv1*dx2;
				cy = dv2*dy1 - dv1*dy2;
				cz = dv2*dz1 - dv1*dz2;
				denom = 1/Math.sqrt(cx*cx + cy*cy + cz*cz);

				_faceTangents[i++] = denom*cx;
				_faceTangents[i++] = denom*cy;
				_faceTangents[i++] = denom*cz;
			}

			_faceTangentsDirty = false;
		}

		/**
		 * Updates the normals for each face.
		 */
		private function updateFaceNormals():void
		{
			var i:uint = 0;
			var j:Number = 0;
			var k:Number = 0;
			var index:Number;
			var offset:Number;
			var stride:Number;

			var x1:Number, x2:Number, x3:Number;
			var y1:Number, y2:Number, y3:Number;
			var z1:Number, z2:Number, z3:Number;
			var dx1:Number, dy1:Number, dz1:Number;
			var dx2:Number, dy2:Number, dz2:Number;
			var cx:Number, cy:Number, cz:Number;
			var d:Number;

			var positions:Vector.<Number> = _positions;

			var len:uint = _indices.length;

			if (_faceNormals == null)
				_faceNormals = new Vector.<Number>(len);

			if (_useFaceWeights && _faceWeights == null)
				_faceWeights = new Vector.<Number>(len/3);

			while (i < len) {
				index = _indices[i++]*3;
				x1 = positions[index];
				y1 = positions[index + 1];
				z1 = positions[index + 2];
				index = _indices[i++]*3;
				x2 = positions[index];
				y2 = positions[index + 1];
				z2 = positions[index + 2];
				index = _indices[i++]*3;
				x3 = positions[index];
				y3 = positions[index + 1];
				z3 = positions[index + 2];
				dx1 = x3 - x1;
				dy1 = y3 - y1;
				dz1 = z3 - z1;
				dx2 = x2 - x1;
				dy2 = y2 - y1;
				dz2 = z2 - z1;
				cx = dz1*dy2 - dy1*dz2;
				cy = dx1*dz2 - dz1*dx2;
				cz = dy1*dx2 - dx1*dy2;
				d = Math.sqrt(cx*cx + cy*cy + cz*cz);
				// length of cross product = 2*triangle area

				if (_useFaceWeights) {
					var w:Number = d*10000;

					if (w < 1)
						w = 1;

					_faceWeights[k++] = w;
				}

				d = 1/d;

				_faceNormals[j++] = cx*d;
				_faceNormals[j++] = cy*d;
				_faceNormals[j++] = cz*d;
			}

			_faceNormalsDirty = false;
		}

		override protected function notifyVerticesUpdate():void
		{
			_strideOffsetDirty = true;

			notifyPositionsUpdate();
			notifyNormalsUpdate();
			notifyTangentsUpdate();
			notifyUVsUpdate();
			notifySecondaryUVsUpdate();
			notifyJointIndicesUpdate();
			notifyJointWeightsUpdate();
		}

		private function notifyPositionsUpdate():void
		{
			if (_positionsDirty)
				return;

			_positionsDirty = true;

			if (!_positionsUpdated)
				_positionsUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, POSITION_DATA);

			dispatchEvent(_positionsUpdated);
		}

		private function notifyNormalsUpdate():void
		{
			if (_vertexNormalsDirty)
				return;

			_vertexNormalsDirty = true;

			if (!_normalsUpdated)
				_normalsUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, NORMAL_DATA);

			dispatchEvent(_normalsUpdated);
		}

		private function notifyTangentsUpdate():void
		{
			if (_vertexTangentsDirty)
				return;

			_vertexTangentsDirty = true;

			if (!_tangentsUpdated)
				_tangentsUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, TANGENT_DATA);

			dispatchEvent(_tangentsUpdated);
		}

		private function notifyUVsUpdate():void
		{
			if (_uvsDirty)
				return;

			_uvsDirty = true;

			if (!_uvsUpdated)
				_uvsUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, UV_DATA);

			dispatchEvent(_uvsUpdated);
		}

		private function notifySecondaryUVsUpdate():void
		{
			if (_secondaryUVsDirty)
				return;

			_secondaryUVsDirty = true;

			if (!_secondaryUVsUpdated)
				_secondaryUVsUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, SECONDARY_UV_DATA);

			dispatchEvent(_secondaryUVsUpdated);
		}

		private function notifyJointIndicesUpdate():void
		{
			if (_jointIndicesDirty)
				return;

			_jointIndicesDirty = true;

			if (!_jointIndicesUpdated)
				_jointIndicesUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, JOINT_INDEX_DATA);

			dispatchEvent(_jointIndicesUpdated);
		}

		private function notifyJointWeightsUpdate():void
		{
			if (_jointWeightsDirty)
				return;

			_jointWeightsDirty = true;

			if (!_jointWeightsUpdated)
				_jointWeightsUpdated = new SubGeometryEvent(SubGeometryEvent.VERTICES_UPDATED, JOINT_WEIGHT_DATA);

			dispatchEvent(_jointWeightsUpdated);
		}
	}
}
