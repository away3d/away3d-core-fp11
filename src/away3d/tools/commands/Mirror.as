package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.bounds.AxisAlignedBoundingBox;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.entities.Mesh;
	import away3d.tools.utils.GeomUtil;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;
	
	public class Mirror
	{
		public static const X_AXIS : int = 1; // 001
		public static const Y_AXIS : int = 2; // 010
		public static const Z_AXIS : int = 4; // 100
		
		public static const MIN_BOUND : String = 'min';
		public static const MAX_BOUND : String = 'max';
		public static const CENTER : String = 'center';
		
		private var _recenter : Boolean;
		private var _duplicate : Boolean;
		
		private var _axis : int;
		private var _offset : String;
		private var _scaleTransform : Matrix3D;
		private var _fullTransform : Matrix3D;
		private var _centerTransform : Matrix3D;
		private var _flipWinding : Boolean;
		
		
		public function Mirror(recenter : Boolean = false, duplicate : Boolean = true) : void
		{
			_recenter = recenter;
			_duplicate = duplicate;
		}
		
		
		public function apply(mesh : Mesh, axis : int, offset : String = CENTER) : void
		{
			_axis = axis;
			_offset = offset;
			
			initTransforms(mesh.bounds);
			applyToMesh(mesh);
		}
		
		public function applyToContainer(ctr : ObjectContainer3D, axis : int, offset : String = CENTER) : void
		{
			var i : uint;
			var len : uint;
			var meshes : Vector.<Mesh>;
			
			_axis = axis;
			_offset = offset;
			
			// Collect ctr (if it's a mesh) and all it's
			// mesh children to a flat list.
			meshes = new Vector.<Mesh>();
			if (ctr is Mesh)
				meshes.push(Mesh(ctr));
			collectMeshChildren(ctr, meshes);
			len = meshes.length;
			
			for (i=0; i<len; i++) {
				initTransforms(meshes[i].bounds);
				applyToMesh(meshes[i]);
			}
		}
		
		
		private function applyToMesh(mesh : Mesh) : void
		{
			var i : uint;
			var len : uint;
			var geom : Geometry;
			
			geom = mesh.geometry;
			len = geom.subGeometries.length;
			for (i=0; i<len; i++) {
				applyToSubGeom(geom.subGeometries[i], geom);
			}
		}
		
		
		private function applyToSubGeom(subGeom : ISubGeometry, geometry : Geometry) : void
		{
			var i : uint;
			var len : uint;
			var indices : Vector.<uint>;
			var vertices : Vector.<Number>;
			var normals : Vector.<Number>;
			var uvs : Vector.<Number>;
			var newSubGeoms : Vector.<ISubGeometry>;
			
			var vIdx : uint, nIdx : uint, uIdx : uint;
			var vd : Vector.<Number>, nd : Vector.<Number>, ud : Vector.<Number>;
			var vStride : uint, nStride : uint, uStride : uint;
			var vOffs : uint, nOffs : uint, uOffs : uint;
			
			vertices = new Vector.<Number>();
			normals = new Vector.<Number>();
			uvs = new Vector.<Number>();
			
			indices = subGeom.indexData;
			indices.fixed = false;
			
			vd = subGeom.vertexData;
			nd = subGeom.vertexNormalData;
			ud = subGeom.UVData;
			vOffs = subGeom.vertexOffset;
			nOffs = subGeom.vertexNormalOffset;
			uOffs = subGeom.UVOffset;
			vStride = subGeom.vertexStride;
			nStride = subGeom.vertexNormalStride;
			uStride = subGeom.UVStride;
			
			vIdx = nIdx = uIdx = 0;
			len = subGeom.numVertices;
			for (i=0; i<len; i++) {
				vertices[vIdx++] = vd[vOffs + i*vStride + 0];
				vertices[vIdx++] = vd[vOffs + i*vStride + 1];
				vertices[vIdx++] = vd[vOffs + i*vStride + 2];
				
				normals[nIdx++] = nd[nOffs + i*nStride + 0];
				normals[nIdx++] = nd[nOffs + i*nStride + 1];
				normals[nIdx++] = nd[nOffs + i*nStride + 2];
				
				uvs[uIdx++] = ud[uOffs + i*uStride + 0];
				uvs[uIdx++] = ud[uOffs + i*uStride + 1];
			}
			
			if (_duplicate) {
				var indexOffset : uint;
				var flippedVertices : Vector.<Number>;
				var flippedNormals : Vector.<Number>;
				
				flippedVertices = new Vector.<Number>();
				flippedNormals = new Vector.<Number>();
				
				_fullTransform.transformVectors(vertices, flippedVertices);
				_scaleTransform.transformVectors(normals, flippedNormals);
				
				// Copy vertex attributes
				len = subGeom.numVertices;
				for (i=0; i<len; i++) {
					vertices[len*3 + i*3 + 0] = flippedVertices[i*3 + 0];
					vertices[len*3 + i*3 + 1] = flippedVertices[i*3 + 1];
					vertices[len*3 + i*3 + 2] = flippedVertices[i*3 + 2];
					
					normals[len*3 + i*3 + 0] = flippedNormals[i*3 + 0];
					normals[len*3 + i*3 + 1] = flippedNormals[i*3 + 1];
					normals[len*3 + i*3 + 2] = flippedNormals[i*3 + 2];
					
					uvs[len*2 + i*2 + 0] = uvs[i*2 + 0];
					uvs[len*2 + i*2 + 1] = uvs[i*2 + 1];
				}
				
				// Copy indices
				len = indices.length;
				indexOffset = subGeom.numVertices;
				if (_flipWinding) {
					for (i=0; i<len; i+=3) {
						indices[len+i+0] = indices[i+0] + indexOffset;
						indices[len+i+1] = indices[i+2] + indexOffset;
						indices[len+i+2] = indices[i+1] + indexOffset;
					}
				}
				else {
					for (i=0; i<len; i+=3) {
						indices[len+i+0] = indices[i+0] + indexOffset;
						indices[len+i+1] = indices[i+1] + indexOffset;
						indices[len+i+2] = indices[i+2] + indexOffset;
					}
				}
			}
			else {
				_fullTransform.transformVectors(vertices, vertices);
				_scaleTransform.transformVectors(normals, normals);
			}
			
			if (_recenter) {
				_centerTransform.transformVectors(vertices, vertices);
			}
			
			geometry.removeSubGeometry(subGeom);
			newSubGeoms = GeomUtil.fromVectors(vertices, indices, uvs, normals, null, null, null);
			len = newSubGeoms.length;
			for (i=0; i<len; i++) {
				geometry.addSubGeometry(newSubGeoms[0]);
			}
		}
		
		
		private function initTransforms(bounds : BoundingVolumeBase) : void
		{
			var ox : Number, oy : Number, oz : Number;
			var sx : Number, sy : Number, sz : Number;
			
			if (!_scaleTransform) {
				_scaleTransform = new Matrix3D();
				_fullTransform = new Matrix3D();
			}
			
			// Scale factors
			_fullTransform.identity();
			_scaleTransform.identity();
			sx = (_axis & X_AXIS)? -1 : 1;
			sy = (_axis & Y_AXIS)? -1 : 1;
			sz = (_axis & Z_AXIS)? -1 : 1;
			_fullTransform.appendScale(sx, sy, sz);
			_scaleTransform.appendScale(sx, sy, sz);
				
			// Offset
			switch (_offset) {
				case MIN_BOUND:
					ox = (_axis & X_AXIS)? 2*bounds.min.x : 0;
					oy = (_axis & Y_AXIS)? 2*bounds.min.y : 0;
					oz = (_axis & Z_AXIS)? 2*bounds.min.z : 0;
					break;
				case MAX_BOUND:
					ox = (_axis & X_AXIS)? 2*bounds.max.x : 0;
					oy = (_axis & Y_AXIS)? 2*bounds.max.y : 0;
					oz = (_axis & Z_AXIS)? 2*bounds.max.z : 0;
					break;
				default:
					ox = 0;
					oy = 0;
					oz = 0;
			}
			
			// Full transform contains both offset and scale, and is the one
			// to use for vertices. Normals should not be affected the same
			// way (i.e. not be offset) which is why these are separate.
			_fullTransform.appendTranslation(ox, oy, oz);
			
			if (_recenter) {
				if (!_centerTransform)
					_centerTransform = new Matrix3D();
				
				_centerTransform.identity();
				_centerTransform.appendTranslation(-ox/2, -oy/2, -oz/2);
			}
			
			_flipWinding = ((sx * sy * sz) > 0);
		}
		
		
		private function collectMeshChildren(ctr : ObjectContainer3D, meshes : Vector.<Mesh>) : void
		{
			var i : uint;
			for (i=0; i<ctr.numChildren; i++) {
				var child : ObjectContainer3D = ctr.getChildAt(i);
				if (child is Mesh)
					meshes.push(Mesh(child));
				
				collectMeshChildren(child, meshes);
			}
		}
	}
}